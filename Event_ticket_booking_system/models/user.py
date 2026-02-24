import random

class User:
    def __init__(self, name, city, phone):
        self.name = name
        self.city = city
        self.phone = phone
        self.user_id = f"USER{random.randint(1000, 9999)}"
    
    def display_info(self):
        return f"Name: {self.name} | City: {self.city} | Phone: {self.phone}"