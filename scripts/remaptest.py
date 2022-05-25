#!/usr/bin/python3

def remap(value, mode):
    cmask = 2**(mode+4) - 1
    bmask = 7<<(mode+4)
    amask = 0xFFFF - cmask - bmask
    a = value & amask
    b = value & bmask
    c = value & cmask
    out = a | (b >> (mode+4)) | (c << 3)
    return out

cpuaddr = 0
for i in range(0, 2**11, 128):
    out = remap(i, 3)
    print("{0:04X} => {1:04X} ({0:016b} => {1:016b}) ({0:5} => {1:5}), [{2:4} or {3:4}]".format(i, out, cpuaddr, cpuaddr*2))
    cpuaddr += 1