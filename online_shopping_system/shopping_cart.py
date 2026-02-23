class ShoppingCart:
    def __init__(self):
        self.items = {}  # pid : quantity

    def add_to_cart(self, pid, qty):
        self.items[pid] = self.items.get(pid, 0) + qty
        print("🛒 Item added to cart")

    def remove_from_cart(self, pid):
        if pid in self.items:
            del self.items[pid]
            print("🗑️ Item removed from cart")
        else:
            print("❌ Item not in cart")

    def view_cart(self, store):
        if not self.items:
            print("🛒 Cart is empty")
            return

        print("\n--- Your Cart ---")
        for pid, qty in self.items.items():
            p = store.products[pid]
            print(f"{p.name} | ₹{p.price} | Qty: {qty}")

    def total_amount(self, store):
        return sum(store.products[pid].price * qty for pid, qty in self.items.items())
