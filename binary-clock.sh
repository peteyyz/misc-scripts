#!/bin/bash 

SCALE=.95                                       # main timeout - adjust to taste
D2B=({0,1}{0,1}{0,1}{0,1}{0,1}{0,1})            # array via brace expansion
tput civis                                      # hide the cursor and set up the clock face
clear    
echo "┌──────┐"
echo "│○○○○○○│"
echo "│○○○○○○│"
echo "│○○○○○○│"
echo "└──────┘"
# echo -e "\e[2A"
CUR_TIME=$(date "+%s")

###################################################################
function timeout {
    read -n 1 -t $SCALE                         # check for user key press, but only wait .95 seconds (set by SCALE variable)
    if [ $? == 0 ]; then                        # check return code of read command
        tput cnorm                              # if key pressed, reactivate cursor and exit
        echo
        exit
    fi
}

function wait_for_it {
    let LOOP_START=CUR_TIME                     # This check will loop for a very short time (1 second minus the timeout)
    while [ "$CUR_TIME" == "$LOOP_START" ];     # Adjust the read/delay timeout variable (SCALE) if the rest
    do                                          # of the code takes longer than one second minus the timeout.
        CUR_TIME=$(date "+%s")
    done
}

function update_clock {
    let NEXT_SEC=CUR_TIME+1
    HH=$(expr $(date -d @$NEXT_SEC +"%H") + 0)
    if [ $HH -ge 12 ]                           # if PM, set color and subtract 12
        then                                    
            tput setaf 10
            let HH=HH-12
        else 
            tput setaf 9
    fi
    if [ $HH -eq 0 ]; then HH=12; fi            # if either midnight or noon HH will equal zero, so adjust it

    MM=$(expr $(date -d @$NEXT_SEC +"%M") + 0)
    SS=$(expr $(date -d @$NEXT_SEC +"%S") + 0)

    HRS="$(echo ${D2B[$HH]} | sed 's/0/○/g' | sed 's/1/●/g')"
    MIN="$(echo ${D2B[$MM]} | sed 's/0/○/g' | sed 's/1/●/g')"
    SEC="$(echo ${D2B[$SS]} | sed 's/0/○/g' | sed 's/1/●/g')"

    clock_face=$(echo -e "\e[5A┌──────┐\n│$HRS│\n│$MIN│\n│$SEC│\n└──────┘")
}
###################################################################

# main

while true
do
    update_clock
    wait_for_it
    echo "$clock_face"
    timeout
done
