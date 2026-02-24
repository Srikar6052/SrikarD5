from datetime import datetime

class WaitingList:
    def __init__(self):
        self.waiting_users = []
    
    def add_to_waitlist(self, user, ticket_type, quantity):
        entry = {
            'user': user,
            'ticket_type': ticket_type,
            'quantity': quantity,
            'timestamp': datetime.now()
        }
        self.waiting_users.append(entry)
        print(f"\n⏳ Added to waiting list for {ticket_type.value[0]} tickets")
    
    def display_position(self, user):
        for idx, entry in enumerate(self.waiting_users, 1):
            if entry['user'].user_id == user.user_id:
                print(f"Your position in waiting list: {idx}")
                return idx
        return None