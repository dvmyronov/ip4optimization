#!/usr/bin/python3 
from datetime import datetime

import sys

d2b = {i: format(i, '08b') for i in range(256)}

def main():
    start=datetime.now()
    prefixes = set()
    binprefixes = set()
    filtered = set()
    masks = set()
    cidrs = set()
    
    for line in sys.stdin:
        line = line.strip()
        if '/' not in line:
            line += '/32'
        prefixes.add(line)
    
    #print("\nUnique Prefixes:")
    #for prefix in prefixes:
    #    print(prefix)

    for prefix in prefixes:
        ip, mask = prefix.split('/')
        octets = ip.split('.')
        binary_octets = [d2b[int(o)] for o in octets]
        binary_string = ''.join(binary_octets)
        MASK=int(mask)
        binprefixes.add(binary_string[:MASK])
        masks.add(MASK)
    
    #for prefix in binprefixes:
    #    print(prefix)
    
    bins = sorted(binprefixes)

    #for bin in bins:
    #    print(bin)

    ptr=0
    filter=bins[ptr]
    filtered.add(filter)
    bound=len(bins) - 1
    while ptr < bound:
        ptr += 1 
        if not bins[ptr].startswith(filter):
            filter = bins[ptr]  # Update filter to the new value
            filtered.add(filter)  # Add the new filter to the set

    #print("filtered:")
   # for filter in sorted(filtered):
   #     print(filter)

    max_mask=max(masks)

    #now let's merge
    merge=sorted(filtered)

    for bit in range(max_mask - 1, 0, -1):
        #print(bit)
        for i in range(len(merge) - 1):
                # Check if the string without the last symbol is equal
                if merge[i][:-1] == merge[i + 1][:-1]:
                    # Check if the bit character of each string is 0 and 1, respectively
                    if merge[i][bit:bit+1] == '0' and merge[i + 1][bit:bit+1] == '1':
                        #print("merge!")
                        merge[i] = merge[i][:-1]
                        merge[i + 1] = merge[i + 1][:-1]
            # Remove duplicates by converting to a set and re-sorting
        merge = sorted(set(merge))

    #print("merged:")
    #for pref in merge:
    #    print(pref)
    

    for pref in merge:
        #print(pref)
        mask=len(pref)
        fullbin = pref + '0' * (32 - len(pref))
        octets = [fullbin[i:i+8] for i in range(0, len(fullbin), 8)]
        octets_decimal = [str(int(octet, 2)) for octet in octets]
        ip = '.'.join(octets_decimal)
        cidr = f"{ip}/{mask}"
        cidrs.add(cidr)

    end=datetime.now()
    time = end - start
    print(f"Time: {time}")

    file_path = 'cidrs.txt'
    # Open the file in write mode
    with open(file_path, 'w') as file:
        # Iterate over the set and write each CIDR on a new line
        for cidr in sorted(cidrs):
            file.write(f"{cidr}\n")


if __name__ == "__main__":
    main()
