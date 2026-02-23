from user import User 
from product import Product
class Admin(User):
    def admin_menu(self, store):
        while True:
            print("\n--- ADMIN MENU ---")
            print("1. Add Product")
            print("2. View Products")
            print("3. Logout")

            choice = input("Enter choice: ")

            if choice == "1":
                pid = int(input("Product ID: "))
                name = input("Product Name: ")
                price = int(input("Price: "))
                store.add_product(Product(pid, name, price))

            elif choice == "2":
                store.view_products()

            elif choice == "3":
                break

            else:
                print("❌ Invalid choice")