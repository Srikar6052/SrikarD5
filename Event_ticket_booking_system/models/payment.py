import random
import time

class Payment:
    def __init__(self, amount):
        self.amount = amount
        self.payment_id = f"PAY{random.randint(10000, 99999)}"
        self.payment_method = None
        self.status = "Pending"
    
    def process_payment(self, method):
        self.payment_method = method
        print(f"\n💳 Processing payment of ₹{self.amount} via {method}...")
        
        # Simulate payment processing with timer
        for i in range(3, 0, -1):
            print(f"⏳ Please wait... {i}")
            time.sleep(1)
        
        self.status = "Success"
        print(f"✓ Payment Successful! Payment ID: {self.payment_id}")
        return True