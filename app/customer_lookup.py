
import getpass
import os

import bcrypt
import mysql.connector
from mysql.connector import Error

import config

MAX_LOGIN_ATTEMPTS = 3



def connect():
    password = os.environ.get("KL_APP_PASSWORD") or getpass.getpass(
        f"Database password for {config.APP_DB_USER}: ")
    return mysql.connector.connect(host=config.DB_HOST, port=config.DB_PORT,
                                   user=config.APP_DB_USER, password=password,
                                   database=config.DB_NAME)



def login(conn):
    cur = conn.cursor()
    for attempt in range(1, MAX_LOGIN_ATTEMPTS + 1):
        username = input("App username: ").strip()
        password = getpass.getpass("App password: ")
        cur.execute("SELECT password_hash, app_role FROM app_users "
                    "WHERE username = %s AND is_active = TRUE", (username,))
        row = cur.fetchone()
        # Same message whether the username or the password is wrong,
        # so an attacker cannot discover which usernames exist.
        if row and bcrypt.checkpw(password.encode("utf-8"), row[0].encode("utf-8")):
            cur.close()
            print(f"\nLogin successful. Welcome, {username} ({row[1]}).")
            return username
        print(f"Invalid username or password. Attempts left: {MAX_LOGIN_ATTEMPTS - attempt}")
    cur.close()
    return None



def unsafe_lookup(conn, phone):
    
    query = ("SELECT full_name, phone, type_name, balance "
             "FROM v_customer_balances WHERE phone = '" + phone + "'")
    print("\n[UNSAFE] SQL sent to MySQL:\n  " + query)
    cur = conn.cursor()
    cur.execute(query)
    rows = cur.fetchall()
   
    try:
        while cur.nextset():
            if cur.with_rows:
                cur.fetchall()
    finally:
        cur.close()
    return rows



def safe_lookup(conn, phone):
    
    query = ("SELECT full_name, phone, type_name, balance "
             "FROM v_customer_balances WHERE phone = %s")
    print("\n[SAFE] SQL template:\n  " + query)
    print("[SAFE] Parameter:    " + repr(phone))
    cur = conn.cursor()
    cur.execute(query, (phone,))
    rows = cur.fetchall()
    cur.close()
    return rows


def print_rows(rows):
    if not rows:
        print("\nNo matching customer found (0 rows).")
        return
    headers = ("Name", "Phone", "Type", "Balance (K)")
    data = [tuple(str(v) for v in row) for row in rows]
    widths = [max(len(h), *(len(r[i]) for r in data)) + 2 for i, h in enumerate(headers)]
    print()
    print("".join(h.ljust(w) for h, w in zip(headers, widths)))
    print("-" * sum(widths))
    for r in data:
        print("".join(v.ljust(w) for v, w in zip(r, widths)))
    print(f"({len(rows)} row(s) returned)")


ATTACKS = """
Example inputs to try (on our own sample database only):
  Normal lookup : +260971000101
  Attack 1      : ' OR '1'='1
                  -> tries to show EVERY customer's debt
  Attack 2      : ' UNION SELECT username, password_hash, app_role, 0 FROM app_users #
                  -> tries to steal the app login password hashes
  Attack 3      : '; DROP TABLE customers; #
                  -> tries to destroy data. In UNSAFE mode the DROP really
                     reaches MySQL - it fails ONLY because kl_app has no
                     DROP privilege (least privilege = last line of defence)
"""


def main():
    print("=" * 63)
    print(" KALOBA LEDGER - Customer Balance Lookup (Security Demo)")
    print("=" * 63)
    try:
        conn = connect()
    except Error as e:
        print(f"Could not connect to MySQL: {e}")
        return

    if not login(conn):
        print("Too many failed attempts. Exiting.")
        conn.close()
        return

    while True:
        print("\n[1] UNSAFE lookup (string concatenation - vulnerable)")
        print("[2] SAFE lookup   (parameterised query)")
        print("[3] Show attack examples")
        print("[0] Exit")
        choice = input("Choose: ").strip()
        if choice == "0":
            break
        if choice == "3":
            print(ATTACKS)
            continue
        if choice not in ("1", "2"):
            print("Invalid choice.")
            continue
        # Input is NOT stripped, so attack strings reach the query exactly as typed
        phone = input("Customer phone number: ")
        try:
            rows = unsafe_lookup(conn, phone) if choice == "1" else safe_lookup(conn, phone)
            print_rows(rows)
        except Exception as e:   # mysql.connector.Error or the C-extension's MySQLInterfaceError
            print(f"\nMySQL error: {e}")

    conn.close()
    print("Goodbye.")


if __name__ == "__main__":
    main()
