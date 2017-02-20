import time

class Mac:
    def __init__(self, mac):
        self.mac = mac
        self.id = 1
        self.time = time.strftime("%x-%X")
        self.device = "Android"
