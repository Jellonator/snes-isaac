#!/usr/bin/python3

import random

def make_random(n):
    return [random.choice([False, True]) for _ in range(n)]

def isEndpoint(v):
    return v

def swap(tiles, i, j):
    tiles[i], tiles[j] = tiles[j], tiles[i]

def check(tiles):
    i = 0
    while i < len(tiles):
        if tiles[i] == False:
            break
        i += 1
    while i < len(tiles):
        if tiles[i] == True:
            return False
        i += 1
    return True

# i = 0, j = len(tiles)-1
# while (i < j) {
#   if (isEndpoint(tiles[i]) {
#       // i is endpoint, j may or may not be endpoint
#       ++i;
#   }
#   else if (isEndpoint(tiles[j])) {
#       // i is not endpoint, j is endpoint
#       swap(&tiles[i], &tiles[j]);
#       ++i;
#       --j;
#   }
#   else {
#       // i is not endpoint, j is not endpoint
#       --j;
#   }
# }
# if (isEndpoint(tiles[i])) {
#   numEndpoints = i+1;
# }
# else {
#   numEndpoints = i;
# }

def dosort(tiles):
    if len(tiles) == 0:
        return 0
    i = 0
    j = len(tiles) - 1
    k = 0
    while i < j:
        if isEndpoint(tiles[i]):
            i += 1
            k += 1
        elif isEndpoint(tiles[j]):
            k += 1
            swap(tiles, i, j)
            i += 1
            j -= 1
        else:
            j -= 1
    if j <= 0:
        print(j)
    if isEndpoint(tiles[i]):
        k += 1
    # print(i, j)
    return k
    #     return i+1
    # else:
    #     return i

for i in range(1000):
    tiles = make_random(i)
    num = 0
    for v in tiles:
        if v:
            num += 1
    value = dosort(tiles)
    chk = check(tiles)
    if not chk or value != num:
        print("ERROR for:", i)
        print(value, num)
        # print(tiles)
        print()

