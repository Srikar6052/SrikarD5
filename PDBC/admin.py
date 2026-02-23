from admin_features import add_student
def admin():
    print("You are in Admin panel")
    print("Choose Your Option to Proceed")
    print("1. Add Student")
    print("2. Get Student")
    print("3. Update Student")
    print("4. Delete Student")

    op=int(input("Enter your option :"))
    if op==1:
        add_student()