from datetime import datetime, timedelta

class Booking:
    def __init__(self, user, cart, booking_id):
        self.user = user
        self.tickets = cart.items.copy()
        self.booking_id = booking_id
        self.booking_date = datetime.now()
        self.total_amount = cart.get_total()
        self.status = "Confirmed"
        self.event_date = datetime.now() + timedelta(days=30)  # Event in 30 days
    
    def display_booking(self):
        print("\n" + "="*60)
        print("🎫 BOOKING CONFIRMATION")
        print("="*60)
        print(f"Booking ID: {self.booking_id}")
        print(f"Event: Anirudh XV Tour")
        print(f"Artist: Anirudh Ravichander")
        print(f"Venue: Gachibowli Stadium, Hyderabad")
        print(f"Event Date: {self.event_date.strftime('%d %B %Y, %I:%M %p')}")
        print(f"Booking Date: {self.booking_date.strftime('%d %B %Y, %I:%M %p')}")
        print("-"*60)
        print(f"Customer: {self.user.name}")
        print(f"Phone: {self.user.phone}")
        print(f"City: {self.user.city}")
        print("-"*60)
        print("TICKETS:")
        for idx, ticket in enumerate(self.tickets, 1):
            print(f"{idx}. {ticket.display_info()}")
        print("-"*60)
        print(f"TOTAL PAID: ₹{self.total_amount}")
        print(f"Status: {self.status}")
        print("="*60)
    
    def send_sms(self):
        print("\n📱 SMS SENT TO", self.user.phone)
        print("-"*60)
        print(f"Anirudh XV Tour - Booking Confirmed!")
        print(f"Booking ID: {self.booking_id}")
        print(f"Tickets: {len(self.tickets)} | Total: ₹{self.total_amount}")
        print(f"Venue: Gachibowli Stadium")
        print(f"Date: {self.event_date.strftime('%d %b %Y')}")
        print(f"Download e-ticket: www.anirudhxv.com/{self.booking_id}")
        print("-"*60)