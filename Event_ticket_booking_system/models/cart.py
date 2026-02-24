class Cart:
    def __init__(self):
        self.items = []
    
    def add_ticket(self, ticket):
        self.items.append(ticket)
        print(f"✓ Added {ticket.quantity} {ticket.ticket_type.value[0]} ticket(s) to cart")
    
    def get_total(self):
        return sum(item.total_price for item in self.items)
    
    def display_cart(self):
        if not self.items:
            print("Your cart is empty!")
            return
        
        print("\n" + "="*60)
        print("🛒 YOUR CART")
        print("="*60)
        for idx, item in enumerate(self.items, 1):
            print(f"{idx}. {item.display_info()}")
        print("-"*60)
        print(f"TOTAL: ₹{self.get_total()}")
        print("="*60)
    
    def clear_cart(self):
        self.items = []