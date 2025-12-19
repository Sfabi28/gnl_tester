#!/bin/bash


############ SOURCES PATH ############
            SOURCE_PATH="../"
######################################


GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo -e "${CYAN}=== TEST GNL ===${RESET}\n"

echo -e "${CYAN}[Compiling the project ...]${RESET}"

cc -Wall -Wextra -Werror -D BUFFER_SIZE=42 main.c "${SOURCE_PATH}get_next_line.c" "${SOURCE_PATH}get_next_line_utils.c" -I "${SOURCE_PATH}" -o gnl_tester

if [ $? -ne 0 ]; then
    echo -e "${RED}Compilation Error! Make sure to have the right directory path${RESET}"
    exit 1
fi

echo -e "${GREEN}Compilation OK!${RESET}\n"

echo -e "${CYAN}[2] Running Norminette ...${RESET}"

norminette "${SOURCE_PATH}get_next_line.c" "${SOURCE_PATH}get_next_line_utils.c" "${SOURCE_PATH}get_next_line.h"

if [ $? -ne 0 ]; then
    echo -e "${RED}Norminette Found Errors!${RESET}"
else
    echo -e "${GREEN}Norminette OK!${RESET}"
fi
echo ""

mkdir -p outputs
echo -e "${CYAN}[3] Running Tests ...${RESET}"

for file in files/*; do
    [ -e "$file" ] || continue
    
    ./gnl_tester "$file" > outputs/user_output.txt
    
    python3 checker.py "$file" outputs/user_output.txt
done

rm -f gnl_tester
rm -rf outputs

echo -e "\n${CYAN}=== DONE ===${RESET}"