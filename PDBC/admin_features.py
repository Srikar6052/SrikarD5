from db_connection import db_connection_func
a=db_connection_func()
curObj=a.cursor() #cursor helps to execute sql queries 

def add_student():
    s_admNo=int(input("Enter Student Admission NO :"))
    s_name=input("Enter Student Name :")
    s_age=int(input("Enter Student Age :"))
    s_year=int(input("Enter Student Year :"))
    s_dept=input("Enter Student Department name:")

    curObj.execute("insert into students(stu_admno,stu_name,stu_age ,stu_year ,stu_dept) values(%s,%s,%s,%s,%s)",(s_admNo,s_name,s_age,s_year,s_dept))# execute method of curser obj helps to run sql query;
    #insert,update,delete from py to db(saves) commit()
    a.commit()
    print("Details Added Successfully")
