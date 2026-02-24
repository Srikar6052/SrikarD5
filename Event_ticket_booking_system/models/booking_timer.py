import time

class BookingTimer:
    def __init__(self, duration=30):
        self.duration = duration
        self.start_time = time.time()
    
    def check_timeout(self):
        elapsed = time.time() - self.start_time
        remaining = self.duration - elapsed
        
        if remaining <= 0:
            return True, 0
        return False, int(remaining)
    
    def display_timer(self):
        timeout, remaining = self.check_timeout()
        if timeout:
            print("\n⏰ TIME EXPIRED! Your session has timed out.")
            return False
        else:
            print(f"\n⏱️  Time remaining to complete booking: {remaining} seconds")
            return True