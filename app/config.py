"""
Kaloba Ledger Security Prototype - connection settings.

SECURITY NOTE: passwords are NOT written in this file. They are read from
environment variables, or typed in when the program asks (hidden input).
"""
import os

DB_HOST = os.environ.get("KL_DB_HOST", "localhost")
DB_PORT = int(os.environ.get("KL_DB_PORT", "3306"))
DB_NAME = "kaloba_ledger"

# Low-privilege account used by the app (see sql/07_users_and_roles.sql)
APP_DB_USER = "kl_app"
