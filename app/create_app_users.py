"""
Kaloba Ledger Security Prototype
create_app_users.py - creates the Python app's login accounts.

Passwords are hashed with bcrypt BEFORE they reach the database.
bcrypt adds a random salt, so the same password gives a different hash
every time, and the hash cannot be reversed.

Run ONCE as the database administrator (root), because kl_app is
deliberately NOT allowed to insert into app_users.
"""
import getpass
import os

import bcrypt
import mysql.connector

import config

# Demo app accounts (username, password, role). Demo passwords only.
DEMO_USERS = [
    ("owner",   "OwnerApp#2026",   "owner"),
    ("helper",  "HelperApp#2026",  "helper"),
    ("auditor", "AuditorApp#2026", "auditor"),
]


def main():
    admin_user = os.environ.get("KL_ADMIN_USER") or input("MySQL admin user [root]: ").strip() or "root"
    admin_pw = os.environ.get("KL_ADMIN_PASSWORD") or getpass.getpass(f"Password for {admin_user}: ")

    conn = mysql.connector.connect(host=config.DB_HOST, port=config.DB_PORT,
                                   user=admin_user, password=admin_pw,
                                   database=config.DB_NAME)
    cur = conn.cursor()

    sql = ("INSERT INTO app_users (username, password_hash, app_role) "
           "VALUES (%s, %s, %s) "
           "ON DUPLICATE KEY UPDATE password_hash = VALUES(password_hash), "
           "app_role = VALUES(app_role), is_active = TRUE")

    for username, password, role in DEMO_USERS:
        hashed = bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt(rounds=12))
        cur.execute(sql, (username, hashed.decode("utf-8"), role))   # parameterised
        print(f"  {username:<8} ({role:<7}) hash: {hashed.decode()[:29]}...")

    conn.commit()
    cur.close()
    conn.close()
    print("App users created. Only bcrypt hashes were stored - never the passwords.")


if __name__ == "__main__":
    main()
