from admin import admin
from db_connection import db_connection_func
a=db_connection_func()
print("Database connection established")
print("Choose Your Role")
print("1. Admin")
print("2. Student")

op=int(input("Choose One Option (1 or 2) :"))

if op==1:
    print("Logging in as Admin")
    admin()
if op==2:
    print("Logging in as Student")
    pass