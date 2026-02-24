from enum import Enum

class TicketType(Enum):
    SILVER = ("Silver", 2000, 500)
    GOLD = ("Gold", 4000, 300)
    FANPIT = ("Fan Pit", 6000, 150)
    PREMIUM = ("Premium", 10000, 100)
    
    def __init__(self, name, price, total_seats):
        self._name = name
        self._price = price
        self._total_seats = total_seats