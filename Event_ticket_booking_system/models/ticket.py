import random

class Ticket:
    def __init__(self, ticket_type, quantity):
        self.ticket_type = ticket_type
        self.quantity = quantity
        self.price_per_ticket = ticket_type.value[1]
        self.total_price = self.price_per_ticket * quantity
        self.seat_numbers = []
    
    def assign_seats(self, available_seats):
        """Assign random available seats"""
        if len(available_seats) >= self.quantity:
            self.seat_numbers = random.sample(available_seats, self.quantity)
            return True
        return False
    
    def display_info(self):
        seats = ", ".join(self.seat_numbers) if self.seat_numbers else "Not Assigned"
        return f"{self.ticket_type.value[0]} x{self.quantity} - ₹{self.total_price} | Seats: {seats}"