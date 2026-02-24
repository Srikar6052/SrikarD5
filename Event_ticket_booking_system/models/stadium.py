from enums import TicketType

class Stadium:
    def __init__(self, name):
        self.name = name
        self.sections = {}
        self._initialize_sections()
    
    def _initialize_sections(self):
        """Initialize all sections with seat numbers"""
        for ticket_type in TicketType:
            section_name = ticket_type.value[0]
            total_seats = ticket_type.value[2]
            self.sections[ticket_type] = [f"{section_name[0]}{i:03d}" for i in range(1, total_seats + 1)]
    
    def get_available_seats(self, ticket_type):
        return self.sections.get(ticket_type, [])
    
    def book_seats(self, ticket_type, seat_numbers):
        """Remove booked seats from available seats"""
        for seat in seat_numbers:
            if seat in self.sections[ticket_type]:
                self.sections[ticket_type].remove(seat)
    
    def get_availability_summary(self):
        print("\n" + "="*60)
        print("🎪 GACHIBOWLI STADIUM - SEAT AVAILABILITY")
        print("="*60)
        for ticket_type in TicketType:
            available = len(self.sections[ticket_type])
            total = ticket_type.value[2]
            percentage = (available / total) * 100
            status = "✓ Available" if available > 0 else "✗ SOLD OUT"
            print(f"{ticket_type.value[0]:<12} | ₹{ticket_type.value[1]:<6} | {available:>3}/{total} seats | {status}")
        print("="*60)