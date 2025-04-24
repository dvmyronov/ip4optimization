#!/bin/bash
#Prefilled conversion arrays to save some time.
#Actually it could save up to 1s comparinmg to calculate this array every time script starts
d2b=(
    "00000000" "00000001" "00000010" "00000011" "00000100" "00000101" "00000110" "00000111"
    "00001000" "00001001" "00001010" "00001011" "00001100" "00001101" "00001110" "00001111"
    "00010000" "00010001" "00010010" "00010011" "00010100" "00010101" "00010110" "00010111"
    "00011000" "00011001" "00011010" "00011011" "00011100" "00011101" "00011110" "00011111"
    "00100000" "00100001" "00100010" "00100011" "00100100" "00100101" "00100110" "00100111"
    "00101000" "00101001" "00101010" "00101011" "00101100" "00101101" "00101110" "00101111"
    "00110000" "00110001" "00110010" "00110011" "00110100" "00110101" "00110110" "00110111"
    "00111000" "00111001" "00111010" "00111011" "00111100" "00111101" "00111110" "00111111"
    "01000000" "01000001" "01000010" "01000011" "01000100" "01000101" "01000110" "01000111"
    "01001000" "01001001" "01001010" "01001011" "01001100" "01001101" "01001110" "01001111"
    "01010000" "01010001" "01010010" "01010011" "01010100" "01010101" "01010110" "01010111"
    "01011000" "01011001" "01011010" "01011011" "01011100" "01011101" "01011110" "01011111"
    "01100000" "01100001" "01100010" "01100011" "01100100" "01100101" "01100110" "01100111"
    "01101000" "01101001" "01101010" "01101011" "01101100" "01101101" "01101110" "01101111"
    "01110000" "01110001" "01110010" "01110011" "01110100" "01110101" "01110110" "01110111"
    "01111000" "01111001" "01111010" "01111011" "01111100" "01111101" "01111110" "01111111"
    "10000000" "10000001" "10000010" "10000011" "10000100" "10000101" "10000110" "10000111"
    "10001000" "10001001" "10001010" "10001011" "10001100" "10001101" "10001110" "10001111"
    "10010000" "10010001" "10010010" "10010011" "10010100" "10010101" "10010110" "10010111"
    "10011000" "10011001" "10011010" "10011011" "10011100" "10011101" "10011110" "10011111"
    "10100000" "10100001" "10100010" "10100011" "10100100" "10100101" "10100110" "10100111"
    "10101000" "10101001" "10101010" "10101011" "10101100" "10101101" "10101110" "10101111"
    "10110000" "10110001" "10110010" "10110011" "10110100" "10110101" "10110110" "10110111"
    "10111000" "10111001" "10111010" "10111011" "10111100" "10111101" "10111110" "10111111"
    "11000000" "11000001" "11000010" "11000011" "11000100" "11000101" "11000110" "11000111"
    "11001000" "11001001" "11001010" "11001011" "11001100" "11001101" "11001110" "11001111"
    "11010000" "11010001" "11010010" "11010011" "11010100" "11010101" "11010110" "11010111"
    "11011000" "11011001" "11011010" "11011011" "11011100" "11011101" "11011110" "11011111"
    "11100000" "11100001" "11100010" "11100011" "11100100" "11100101" "11100110" "11100111"
    "11101000" "11101001" "11101010" "11101011" "11101100" "11101101" "11101110" "11101111"
    "11110000" "11110001" "11110010" "11110011" "11110100" "11110101" "11110110" "11110111"
    "11111000" "11111001" "11111010" "11111011" "11111100" "11111101" "11111110" "11111111"
)

masked=""

START=$(date +%s)
pools=($(cat))
STOP=$(date +%s)
echo "Loaded ${#pools[@]} pools in $((STOP - START)) seconds"

#Get uniq pools. If no mask specified set mask 32.
START=$(date +%s)
sorted=($(for pool in "${pools[@]}"; do
    mask="${pool##*/}"
    if [[ "$mask" == "$pool" ]];then 
        echo "$pool/32"
    else
        echo "$pool"
    fi
done | sort -u ))
STOP=$(date +%s)
echo "Have ${#sorted[@]} uniq pools in $((STOP - START)) seconds"
#for pool in "${sorted[@]}"; do
#    echo "Processing: $pool"
#done

#Convert to bin
START=$(date +%s)
OLDIFS=$IFS
for cidr in "${sorted[@]}"; do
    ip="${cidr%/*}"
    mask="${cidr#*/}"
    first_octet="${ip%%.*}"
    second_octet="${ip#*.}"      # Remove first octet (195.)
    second_octet="${second_octet%%.*}"
    third_octet="${ip#*.*.}"      # Remove the first two octets (195.1.)
    third_octet="${third_octet%%.*}"  # Remove everything after the third dot
    fourth_octet="${ip##*.}"
    #IFS='.' read -r o1 o2 o3 o4 <<< "$ip"
    #binary="${d2b[$o1]}${d2b[$o2]}${d2b[$o3]}${d2b[$o4]}"
    binary="${d2b[$first_octet]}${d2b[$second_octet]}${d2b[$third_octet]}${d2b[$fourth_octet]}"
    #echo $binary
    masked+="${binary:0:$mask}"$'\n'
done
IFS=$OLDIFS
pools=()
sorted=()
prefixes=($(echo "$masked" | sort))
STOP=$(date +%s)
echo "Converted to bin. Number of prefixes: ${#prefixes[@]} in $((STOP - START)) seconds"
#for ((i=0; i<${#prefixes[@]}; i++)); do
#    echo "$i ${prefixes[$i]}"
#done

#Let's filter out overlaps. F.e if we have 5.0.0.0/8 5.0.0.0/16 5.1.1.0/24 -> result 5.0.0.0/8
START=$(date +%s)
filtered=()
ptr=0
filter=${prefixes[$ptr]}
filtered+=("$filter")
bound=$(( ${#prefixes[@]} - 1 ))
while (( ptr < bound )); do
    (( ++ptr ))
    #echo "ptr=$ptr"
    if [[ ${prefixes[$ptr]} != "$filter"* ]]; then
        filter=${prefixes[$ptr]}
        filtered+=("$filter")  # Добавляем новый фильтр в массив
        #echo "ptr=$ptr filter=$filter"
    fi
done
prefixes=("${filtered[@]}")
STOP=$(date +%s)
echo "Overlapped removed in $((STOP - START)) seconds. Prefixes before merge= ${#prefixes[@]}"
#for ((i=0; i<${#prefixes[@]}; i++)); do
#    echo "$i ${prefixes[$i]}"
#done

max_mask=0
for prefix in "${prefixes[@]}"; do
    length=${#prefix}  # Get the length of the prefix
    if (( length > max_mask )); then
        max_mask=$length  # Update max_length if current length is greater
    fi
done
echo "max_mask=$max_mask"

array_length=${#prefixes[@]}

START=$(date +%s)
for ((bit=max_mask-1; bit>0; bit--)); do
    for ((i=0; i<array_length-1; i++)); do
        if [[ "${prefixes[i]::-1}" == "${prefixes[i+1]::-1}" ]]; then
                if [[ "${prefixes[$i]:$bit:1}" == "0" && "${prefixes[$i+1]:$bit:1}" == "1" ]]; then
                    prefixes[i]="${prefixes[i]::-1}"
                    prefixes[i+1]="${prefixes[i+1]::-1}"
                fi
        fi
    done
    prefixes=($(echo "${prefixes[@]}" | tr ' ' '\n' | uniq))
    array_length=${#prefixes[@]}
done
STOP=$(date +%s)
echo "Merge completed in $((STOP - START)) seconds. Nmbr of prefixes = ${#prefixes[@]}."

#Convert to dotted-decimal
START=$(date +%s)
dec=()
rm -f optimized.txt
for prefix in "${prefixes[@]}"; do
    #echo "$prefix"
    prefix_length="${#prefix}"
    zeros_to_add=$(( 32 - prefix_length ))
    zeros=""
    for ((i=0; i<zeros_to_add; i++)); do
        zeros+="0"
    done
    full_binary="$prefix$zeros"
    #echo "full_binary=$full_binary / $prefix_length"
    byte1="${full_binary:0:8}"
    byte2="${full_binary:8:8}"   
    byte3="${full_binary:16:8}"
    byte4="${full_binary:24:8}"
    dec+=("$((2#$byte1)).$((2#$byte2)).$((2#$byte3)).$((2#$byte4))/$prefix_length")
done
STOP=$(date +%s)
echo "Binary do decimal completed in $((STOP - START)) seconds. Nmbr of prefixes = ${#dec[@]}.Writing result..."

for element in "${dec[@]}"; do
    echo "$element" >> optimized.txt
done
