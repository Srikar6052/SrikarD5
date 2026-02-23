from store import Store
from admin import Admin
from customer import Customer
def main():
    store = Store()

    while True:
        print("\n=== ONLINE SHOPPING SYSTEM ===")
        print("1. Admin")
        print("2. Customer")
        print("3. Exit")

        role = input("Select role: ")

        if role == "1":
            admin = Admin("Admin")
            admin.admin_menu(store)

        elif role == "2":
            name = input("Enter your name: ")
            customer = Customer(name)
            customer.customer_menu(store)

        elif role == "3":
            print("🙏 Thank you for using the system")
            break

        else:
            print("❌ Invalid option")


if __name__ == "__main__":
    main()