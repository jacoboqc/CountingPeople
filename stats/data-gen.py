import random
import math

# minimal amount of times a mac address will show up
mac_min_rep = 10
mac_letters=['a','b','c','d','e','f','0','1','2','3','4','5','6','7','8','9']
# desired mac length
mac_length = 4
# samples to acquire previous conditions
samples = (len(mac_letters)**mac_length) * mac_min_rep
print(samples)
f = open("data.csv", "w")
f.write("timestamp,MAC,receptor\n")

def getmac():
    mac_list = [mac_letters[random.randint(0,len(mac_letters)-1)] 
            for i in range(mac_length)]
    return "".join(mac_list)



for i in range(0,samples):
    f.write("{ts},{mac},{rec}\n".format(
        ts=i,
        mac=getmac(),
        rec= random.randint(0,1)
        )
    )
