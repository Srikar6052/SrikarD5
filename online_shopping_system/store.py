class Store:
    def __init__(self):
        self.products = {}

    def add_product(self, product):
        self.products[product.pid] = product
        print("✅ Product added successfully")

    def view_products(self):
        if not self.products:
            print("❌ No products available")
            return

        print("\n--- Available Products ---")
        for p in self.products.values():
            print(f"{p.pid} | {p.name} | ₹{p.price}")