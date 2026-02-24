import random
from models import User, Ticket, Cart, Booking, Payment, Stadium, WaitingList, BookingTimer
from enums import TicketType

class ConcertBookingSystem:
    def __init__(self):
        self.event_name = "Anirudh XV Tour"
        self.artist = "Anirudh Ravichander"
        self.venue = Stadium("Gachibowli Stadium")
        self.bookings = []
        self.waiting_list = WaitingList()
        self.current_user = None
        self.cart = None
        self.booking_timer = None
    
    def display_welcome(self):
        print("\n" + "="*60)
        print("🎵 WELCOME TO ANIRUDH XV TOUR BOOKING 🎵")
        print("="*60)
        print(f"Artist: {self.artist}")
        print(f"Event: {self.event_name}")
        print(f"Venue: Gachibowli Stadium, Hyderabad")
        print("="*60)
    
    def register_user(self):
        print("\n📝 USER REGISTRATION")
        print("-"*60)
        name = input("Enter your name: ").strip()
        city = input("Enter your city: ").strip()
        
        while True:
            phone = input("Enter your phone number (10 digits): ").strip()
            if len(phone) == 10 and phone.isdigit():
                break
            print("❌ Invalid phone number. Please enter 10 digits.")
        
        self.current_user = User(name, city, phone)
        self.cart = Cart()
        
        print(f"\n✓ Registration successful! User ID: {self.current_user.user_id}")
        print(f"Welcome, {name}!")
    
    def select_tickets(self):
        while True:
            self.venue.get_availability_summary()
            
            print("\n🎫 SELECT TICKET TYPE")
            print("1. Silver - ₹2,000")
            print("2. Gold - ₹4,000")
            print("3. Fan Pit - ₹6,000")
            print("4. Premium - ₹10,000")
            print("5. View Cart & Proceed to Checkout")
            print("0. Cancel Booking")
            
            choice = input("\nEnter your choice (0-5): ").strip()
            
            if choice == '0':
                print("Booking cancelled.")
                return False
            elif choice == '5':
                if len(self.cart.items) > 0:
                    return True
                else:
                    print("❌ Your cart is empty! Please add tickets first.")
                    continue
            elif choice in ['1', '2', '3', '4']:
                ticket_map = {
                    '1': TicketType.SILVER,
                    '2': TicketType.GOLD,
                    '3': TicketType.FANPIT,
                    '4': TicketType.PREMIUM
                }
                selected_type = ticket_map[choice]
                
                available_seats = self.venue.get_available_seats(selected_type)
                
                if len(available_seats) == 0:
                    print(f"\n❌ Sorry! {selected_type.value[0]} tickets are SOLD OUT!")
                    add_waitlist = input("Would you like to join the waiting list? (y/n): ").lower()
                    if add_waitlist == 'y':
                        quantity = int(input("How many tickets? "))
                        self.waiting_list.add_to_waitlist(self.current_user, selected_type, quantity)
                    continue
                
                print(f"\nAvailable seats: {len(available_seats)}")
                quantity = int(input(f"How many {selected_type.value[0]} tickets? "))
                
                if quantity > len(available_seats):
                    print(f"❌ Only {len(available_seats)} seats available!")
                    continue
                
                if quantity <= 0:
                    print("❌ Invalid quantity!")
                    continue
                
                ticket = Ticket(selected_type, quantity)
                
                # Start timer when first ticket is added
                if len(self.cart.items) == 0:
                    self.booking_timer = BookingTimer(30)
                    print("\n⏱️  Booking timer started! You have 30 seconds to complete your booking.")
                
                self.cart.add_ticket(ticket)
                
            else:
                print("❌ Invalid choice!")
    
    def checkout(self):
        # Check timer
        if self.booking_timer:
            if not self.booking_timer.display_timer():
                print("❌ Session expired! Please start over.")
                self.cart.clear_cart()
                return False
        
        self.cart.display_cart()
        
        confirm = input("\nProceed to payment? (y/n): ").lower()
        if confirm != 'y':
            print("Checkout cancelled.")
            return False
        
        # Assign seats to all tickets
        for ticket in self.cart.items:
            available_seats = self.venue.get_available_seats(ticket.ticket_type)
            if not ticket.assign_seats(available_seats):
                print(f"❌ Failed to assign seats for {ticket.ticket_type.value[0]}!")
                return False
        
        return True
    
    def process_payment(self):
        total = self.cart.get_total()
        
        print("\n💳 PAYMENT OPTIONS")
        print("1. Credit/Debit Card")
        print("2. UPI")
        print("3. Net Banking")
        
        choice = input("Select payment method (1-3): ").strip()
        
        payment_methods = {
            '1': 'Credit/Debit Card',
            '2': 'UPI',
            '3': 'Net Banking'
        }
        
        method = payment_methods.get(choice, 'UPI')
        payment = Payment(total)
        
        if payment.process_payment(method):
            # Book the seats in the stadium
            for ticket in self.cart.items:
                self.venue.book_seats(ticket.ticket_type, ticket.seat_numbers)
            
            # Create booking
            booking_id = f"ANR{random.randint(100000, 999999)}"
            booking = Booking(self.current_user, self.cart, booking_id)
            self.bookings.append(booking)
            
            # Display confirmation
            booking.display_booking()
            booking.send_sms()
            
            # Clear cart
            self.cart.clear_cart()
            return True
        
        return False
    
    def run(self):
        self.display_welcome()
        self.register_user()
        
        if self.select_tickets():
            if self.checkout():
                self.process_payment()
        
        print("\n✨ Thank you for booking with us! See you at the concert! ✨\n")