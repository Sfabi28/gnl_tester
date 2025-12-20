#!/bin/bash

SOURCE_PATH="../"
TIMEOUT_VAL="10s"





GREEN='\033[92m'
RED='\033[91m'
CYAN='\033[96m'
YELLOW='\033[93m'
RESET='\033[0m'
MAGENTA='\033[95m'
BLUE='\033[94m'



run_gnl_tests() {
    MODE=$1
    
    echo -e "\n${BLUE}**************************************************${RESET}"
    echo -e "${BLUE}        STARTING MODE: $MODE PART                 ${RESET}"
    echo -e "${BLUE}**************************************************${RESET}\n"

    if [ "$MODE" == "BONUS" ]; then
        GNL_FILE="get_next_line_bonus.c"
        UTILS_FILE="get_next_line_utils_bonus.c"
        HEADER_FILE="get_next_line_bonus.h"
        MAIN_FILE="main_bonus.c"
        CHECKER_FILE="checker_bonus.py"
    else
        GNL_FILE="get_next_line.c"
        UTILS_FILE="get_next_line_utils.c"
        HEADER_FILE="get_next_line.h"
        MAIN_FILE="main.c"
        CHECKER_FILE="checker.py"
    fi

    echo -e "${CYAN}Running Norminette...${RESET}"
    norminette "${SOURCE_PATH}${GNL_FILE}" "${SOURCE_PATH}${UTILS_FILE}" "${SOURCE_PATH}${HEADER_FILE}"
    [ $? -ne 0 ] && echo -e "${RED}Norminette Found Errors!${RESET}" || echo -e "${GREEN}Norminette OK!${RESET}"
    echo ""

    mkdir -p outputs
    BUFFER_SIZES="DEFAULT 1 42 1000 1000000"

    for SIZE in $BUFFER_SIZES; do
        echo -e "${MAGENTA}--------- BUFFER_SIZE = $SIZE ---------${RESET}"

        SRC_GNL="${SOURCE_PATH}${GNL_FILE}"
        SRC_UTILS="${SOURCE_PATH}${UTILS_FILE}"
        
        if [ "$SIZE" == "DEFAULT" ]; then
            cc -Wall -Wextra -Werror -g $MAIN_FILE "$SRC_GNL" "$SRC_UTILS" -I "${SOURCE_PATH}" -o gnl_tester
        else
            cc -Wall -Wextra -Werror -g -D BUFFER_SIZE=$SIZE $MAIN_FILE "$SRC_GNL" "$SRC_UTILS" -I "${SOURCE_PATH}" -o gnl_tester
        fi

        if [ $? -ne 0 ]; then
            echo -e "${RED}Compilation Error!${RESET}"
            continue
        fi

        if [ "$MODE" == "BONUS" ]; then
            FILES=(files/*)
            NUM_FILES=${#FILES[@]}
            
            if [ "$NUM_FILES" -lt 2 ]; then
                echo -e "${RED}Error: Need at least 2 files in 'files/' for bonus test!${RESET}"
                continue
            fi

            for ((i=0; i<$NUM_FILES-1; i++)); do
                FILE_A="${FILES[$i]}"
                FILE_B="${FILES[$i+1]}"
                [ -e "$FILE_A" ] && [ -e "$FILE_B" ] || continue
                
                echo -n "Mix $(basename "$FILE_A") + $(basename "$FILE_B"): "
                
                
                timeout $TIMEOUT_VAL valgrind --leak-check=full --show-leak-kinds=all ./gnl_tester "$FILE_A" "$FILE_B" > outputs/user_output.txt 2> outputs/valgrind.log
                EXIT_CODE=$?

                if [ $EXIT_CODE -eq 124 ]; then
                    echo -e "${RED}[TIMEOUT]${RESET}"
                elif [ $EXIT_CODE -eq 139 ]; then
                    echo -e "${RED}[SIGSEGV]${RESET}"
                else
                    python3 $CHECKER_FILE "$FILE_A" "$FILE_B" outputs/user_output.txt | tr -d '\n'
                    echo -n " "
                    if grep -q "All heap blocks were freed -- no leaks are possible" outputs/valgrind.log; then
                        echo -e "${GREEN}[MOK]${RESET}"
                    else
                        echo -e "${RED}[MKO]${RESET}"
                    fi
                fi
            done
            
            
            FILE_A="${FILES[NUM_FILES-1]}"
            FILE_B="${FILES[0]}"
            if [ -e "$FILE_A" ] && [ -e "$FILE_B" ]; then
                echo -n "Mix $(basename "$FILE_A") + $(basename "$FILE_B"): "
                timeout $TIMEOUT_VAL valgrind --leak-check=full --show-leak-kinds=all ./gnl_tester "$FILE_A" "$FILE_B" > outputs/user_output.txt 2> outputs/valgrind.log
                EXIT_CODE=$?

                if [ $EXIT_CODE -eq 124 ]; then
                    echo -e "${RED}[TIMEOUT]${RESET}"
                elif [ $EXIT_CODE -eq 139 ]; then
                    echo -e "${RED}[SIGSEGV]${RESET}"
                else
                    python3 $CHECKER_FILE "$FILE_A" "$FILE_B" outputs/user_output.txt | tr -d '\n'
                    echo -n " "
                    if grep -q "All heap blocks were freed -- no leaks are possible" outputs/valgrind.log; then
                        echo -e "${GREEN}[MOK]${RESET}"
                    else
                        echo -e "${RED}[MKO]${RESET}"
                    fi
                fi
            fi

            
            TWIN_FILE=""
            for f in files/*; do
                if [ -s "$f" ]; then
                    TWIN_FILE="$f"
                    break
                fi
            done

            if [ -n "$TWIN_FILE" ]; then
                NAME=$(basename "$TWIN_FILE")
                echo -n "Twin Mix $NAME + $NAME (Same File): "
                
                timeout $TIMEOUT_VAL valgrind --leak-check=full --show-leak-kinds=all ./gnl_tester "$TWIN_FILE" "$TWIN_FILE" > outputs/user_output.txt 2> outputs/valgrind.log
                EXIT_CODE=$?

                if [ $EXIT_CODE -eq 124 ]; then
                    echo -e "${RED}[TIMEOUT]${RESET}"
                elif [ $EXIT_CODE -eq 139 ]; then
                    echo -e "${RED}[SIGSEGV]${RESET}"
                else
                    python3 $CHECKER_FILE "$TWIN_FILE" "$TWIN_FILE" outputs/user_output.txt | tr -d '\n'
                    echo -n " "
                    if grep -q "All heap blocks were freed -- no leaks are possible" outputs/valgrind.log; then
                        echo -e "${GREEN}[MOK]${RESET}"
                    else
                        echo -e "${RED}[MKO]${RESET}"
                    fi
                fi
            fi

        else
            
            if [ -e "main_error.c" ]; then
                echo -n "Test INVALID FDs: "
                if [ "$SIZE" == "DEFAULT" ]; then
                     cc -Wall -Wextra -Werror -g main_error.c "$SRC_GNL" "$SRC_UTILS" -I "${SOURCE_PATH}" -o gnl_error_tester
                else
                     cc -Wall -Wextra -Werror -g -D BUFFER_SIZE=$SIZE main_error.c "$SRC_GNL" "$SRC_UTILS" -I "${SOURCE_PATH}" -o gnl_error_tester
                fi
                
                if [ $? -eq 0 ]; then
                    timeout $TIMEOUT_VAL valgrind --leak-check=full ./gnl_error_tester > outputs/error_out.txt 2> outputs/valgrind_error.log
                    EXIT_CODE=$?

                    if [ $EXIT_CODE -eq 124 ]; then
                        echo -e "${RED}[TIMEOUT]${RESET}"
                    elif [ $EXIT_CODE -eq 139 ]; then
                        echo -e "${RED}[SIGSEGV]${RESET}"
                    else
                        RESULT=$(cat outputs/error_out.txt)
                        if [ "$RESULT" == "OK" ]; then
                             echo -ne "${GREEN}OK${RESET} "
                             if grep -q "All heap blocks were freed -- no leaks are possible" outputs/valgrind_error.log; then
                                echo -e "${GREEN}[MOK]${RESET}"
                             else
                                echo -e "${RED}[MKO]${RESET}"
                             fi
                        else
                            echo -e "${RED}[KO] (Output: $RESULT)${RESET}"
                        fi
                    fi
                else
                    echo -e "${RED}[Compilation Fail]${RESET}"
                fi
                rm -f gnl_error_tester
            fi

            echo -n "Test STDIN (Pipe): "
            echo -e "Line 1\nLine 2\nLine 3" | timeout $TIMEOUT_VAL valgrind --leak-check=full --show-leak-kinds=all ./gnl_tester > outputs/user_output.txt 2> outputs/valgrind.log
            EXIT_CODE=$?

            if [ $EXIT_CODE -eq 124 ]; then
                echo -e "${RED}[TIMEOUT]${RESET}"
            elif [ $EXIT_CODE -eq 139 ]; then
                echo -e "${RED}[SIGSEGV]${RESET}"
            else
                echo -e "Line 1\nLine 2\nLine 3" > outputs/stdin_expected.txt
                python3 $CHECKER_FILE outputs/stdin_expected.txt outputs/user_output.txt | tr -d '\n'
                echo -n " "
                if grep -q "All heap blocks were freed -- no leaks are possible" outputs/valgrind.log; then
                    echo -e "${GREEN}[MOK]${RESET}"
                else
                    echo -e "${RED}[MKO]${RESET}"
                fi
            fi

            for file in files/*; do
                [ -e "$file" ] || continue
                FILENAME=$(basename "$file")
                
                timeout $TIMEOUT_VAL valgrind --leak-check=full --show-leak-kinds=all ./gnl_tester "$file" > outputs/user_output.txt 2> outputs/valgrind.log
                EXIT_CODE=$?
                
                echo -n "Test $FILENAME: "
                
                if [ $EXIT_CODE -eq 124 ]; then
                    echo -e "${RED}[TIMEOUT]${RESET}"
                elif [ $EXIT_CODE -eq 139 ]; then
                    echo -e "${RED}[SIGSEGV]${RESET}"
                else
                    python3 $CHECKER_FILE "$file" outputs/user_output.txt | tr -d '\n'
                    echo -n " " 
                    
                    if grep -q "All heap blocks were freed -- no leaks are possible" outputs/valgrind.log; then
                        echo -e "${GREEN}[MOK]${RESET}"
                    else
                        echo -e "${RED}[MKO]${RESET}"
                    fi
                fi
            done
        fi
        echo ""
    done

    rm -f gnl_tester
    rm -rf outputs
}

echo -e "\n${CYAN}=== GNL TESTER ===${RESET}"

if [ "$1" == "b" ]; then
    run_gnl_tests "BONUS"
elif [ "$1" == "" ]; then
    run_gnl_tests "MANDATORY"
    run_gnl_tests "BONUS"
elif [ "$1" == "m" ]; then
    run_gnl_tests "MANDATORY"
else
    echo -e "${YELLOW}(Default: MANDATORY)${RESET}"
    run_gnl_tests "MANDATORY"
fi
echo -e "\n${CYAN}=== DONE ===${RESET}"