from user import User
from shopping_cart import ShoppingCart
class Customer(User):
    def __init__(self, username):
        super().__init__(username)
        self.cart = ShoppingCart()

    def customer_menu(self, store):
        while True:
            print(f"\n--- CUSTOMER MENU ({self.username}) ---")
            print("1. View Products")
            print("2. Add to Cart")
            print("3. Remove from Cart")
            print("4. View Cart")
            print("5. Checkout")
            print("6. Logout")

            choice = input("Enter choice: ")

            if choice == "1":
                store.view_products()

            elif choice == "2":
                pid = int(input("Enter Product ID: "))
                qty = int(input("Enter Quantity: "))
                if pid in store.products:
                    self.cart.add_to_cart(pid, qty)
                else:
                    print("❌ Invalid Product ID")

            elif choice == "3":
                pid = int(input("Enter Product ID: "))
                self.cart.remove_from_cart(pid)

            elif choice == "4":
                self.cart.view_cart(store)

            elif choice == "5":
                total = self.cart.total_amount(store)
                print(f"\n💰 Total Bill: ₹{total}")
                print("✅ Order placed successfully 🎉")
                break

            elif choice == "6":
                break

            else:
                print("❌ Invalid choice")