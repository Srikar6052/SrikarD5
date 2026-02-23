import mysql.connector

def db_connection_func():
    return mysql.connector.connect(
    host="localhost",
    user="root",
    database="d5_PDBC",
    password="Srikar@2003"
)
print("Database Connected Successfully ")