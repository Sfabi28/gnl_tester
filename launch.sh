#!/bin/bash

SOURCE_PATH="../"
TIMEOUT_VAL="15s"




TESTER_NAME="gnl_tester"
LOG_FILE="test_results.log"

GREEN='\033[92m'
RED='\033[91m'
CYAN='\033[96m'
YELLOW='\033[93m'
RESET='\033[0m'
MAGENTA='\033[95m'
BLUE='\033[94m'


strip_colors() {
    sed $'s/\033\[[0-9;]*m//g'
}

check_allowed_function() {
    echo -e "\n${BLUE}=== ALLOWED FUNCTIONS CHECK ===${NC}"
    
    WHITELIST_FILE=".whitelist_gnl.txt"
    if [ ! -f "$WHITELIST_FILE" ]; then
        echo "malloc" > "$WHITELIST_FILE"
        echo "free" >> "$WHITELIST_FILE"
        echo "read" >> "$WHITELIST_FILE"
    fi

    echo -e "${YELLOW}Compiling objects for check...${NC}"
    rm -f *.o 

    if [ -f "${SOURCE_PATH}get_next_line.c" ]; then
        cc -c -Wall -Wextra -Werror "${SOURCE_PATH}get_next_line.c" "${SOURCE_PATH}get_next_line_utils.c" -I "$SOURCE_PATH" 2>/dev/null
    fi
    
    if [ -f "${SOURCE_PATH}get_next_line_bonus.c" ]; then
        cc -c -Wall -Wextra -Werror "${SOURCE_PATH}get_next_line_bonus.c" "${SOURCE_PATH}get_next_line_utils_bonus.c" -I "$SOURCE_PATH" 2>/dev/null
    fi

    if ! ls *.o >/dev/null 2>&1; then
        echo -e "${RED}Error: No object files created. Check source paths.${NC}"
        return
    fi

    USED_FUNCS=$(nm -u *.o | awk '{print $2}' | sort | uniq)
    DEFINED_FUNCS=$(nm *.o | awk '$2 ~ /[TtWw]/ {print $3}' | sed 's/^_//' | sort | uniq)
    VIOLATION=0
    ALLOWED_FUNCS=$(cat "$WHITELIST_FILE")

    for func in $USED_FUNCS; do
        clean_func=${func%%@*}
        clean_func=${clean_func#_}

        if [[ "$clean_func" == _* || "$clean_func" == .* ]]; then
            continue
        fi
        
        if [[ "$clean_func" == "dyld_stub_binder" || "$clean_func" == "gmon_start" || \
              "$clean_func" == "data_start" || "$clean_func" == "edata" || \
              "$clean_func" == "end" || "$clean_func" == "bss_start" ]]; then
            continue
        fi

        if echo "$DEFINED_FUNCS" | grep -w -q "^$clean_func$"; then
            continue
        fi

        if ! echo "$ALLOWED_FUNCS" | grep -w -q "^$clean_func$"; then
            echo -e "Forbidden function used: ${RED}$clean_func${NC} (raw: $func) ${RED}[KO]${NC}"
            VIOLATION=1
        fi
    done

    rm -f *.o

    if [ $VIOLATION -eq 0 ]; then
        echo -e "No Forbidden Functions. ${GREEN}[OK]${NC}"
    else
        echo -e "${RED}Forbidden functions detected!${NC}"
        echo "FORBIDDEN FUNCTIONS DETECTED" >> "$LOG_FILE"
    fi
}

check_dev_mode() {
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

    if [ "$CURRENT_BRANCH" == "dev" ]; then
        echo -e "\n${MAGENTA}⚠️  WARNING: YOU ARE IN DEVELOPER MODE (dev branch) ⚠️${NC}"
        echo -e "${MAGENTA}This version might be unstable.${NC}"
        echo -e "If you are a student, please switch to stable: ${CYAN}git checkout main${NC}\n"
        sleep 5
    fi
}

check_updates() {
    if [ -d ".git" ]; then
        echo -n -e "${CYAN}Checking for updates... ${NC}"
        
        git fetch origin > /dev/null 2>&1
        
        LOCAL=$(git rev-parse HEAD)
        REMOTE=$(git rev-parse @{u} 2>/dev/null)

        if [ -z "$REMOTE" ]; then
            return
        fi

        if [ "$LOCAL" != "$REMOTE" ]; then
            echo -e "${RED}[UPDATE FOUND]${NC}"
            echo -e "\n${YELLOW}🚨  A NEW VERSION IS AVAILABLE!  🚨${NC}"
            echo -e "You are using an old version of the tester."
            echo -e "Do you want to update it now? (Recommended) [y/N]"
            read -r -p "Select: " RESPONSE
            
            if [[ "$RESPONSE" =~ ^[yY]$ ]]; then
                echo -e "${GREEN}Downloading updates...${NC}"
                git pull
                echo -e "\n${GREEN}✅ Update successful!${NC}"
                echo -e "${CYAN}Please restart the tester to apply changes.${NC}"
                exit 0
            fi
        else
            echo -e "${GREEN}[UP-TO-DATE]${NC}"
        fi
    fi
}

cleanup() {
    rm -f *.o gnl_tester gnl_error_tester
    rm -rf outputs
}

trap cleanup EXIT

check_dev_mode
check_updates

echo "=== TEST SESSION STARTED: $(date) ===" > "$LOG_FILE"
echo "Detailed logs below." >> "$LOG_FILE"
echo "-----------------------------------" >> "$LOG_FILE"
echo ""
echo -e "${CYAN} Checking Norminette...${RESET}"

TESTER_DIR=$(basename "$PWD")
FILES_TO_CHECK=$(find "$SOURCE_PATH" -maxdepth 1 -type f \( -name "*.c" -o -name "*.h" \) | grep -v "/$TESTER_DIR/" | tr '\n' ' ')

if [ -z "$FILES_TO_CHECK" ]; then
    NORM_OUT=""
else
    NORM_OUT=$(norminette $FILES_TO_CHECK | grep -v "OK!" | grep -v "Error: ")
fi

if [ -z "$NORM_OUT" ]; then
    echo -e "${GREEN}[NORM OK]${RESET}"
    echo "[NORM OK]" >> "$LOG_FILE"
else
    echo -e "${RED}[NORM KO]${RESET}"
    echo "$NORM_OUT"
    echo "--- NORMINETTE ERRORS ---" >> "$LOG_FILE"
    echo "$NORM_OUT" >> "$LOG_FILE"
    echo "-------------------------" >> "$LOG_FILE"
fi
echo ""

run_gnl_tests() {
    MODE=$1
    
    echo -e "\n${BLUE}**************************************************${RESET}"
    echo -e "${BLUE}        STARTING MODE: $MODE PART                  ${RESET}"
    echo -e "${BLUE}**************************************************${RESET}\n"
    echo -e "\n\n>>> STARTING $MODE PART <<<\n" >> "$LOG_FILE"

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

    check_allowed_function "$MODE"

    mkdir -p outputs
    BUFFER_SIZES="DEFAULT 1 42 1000 1000000"

    for SIZE in $BUFFER_SIZES; do
        echo -e "${MAGENTA}--------- BUFFER_SIZE = $SIZE ---------${RESET}"
        echo "--- BUFFER_SIZE = $SIZE ---" >> "$LOG_FILE"

        SRC_GNL="${SOURCE_PATH}${GNL_FILE}"
        SRC_UTILS="${SOURCE_PATH}${UTILS_FILE}"
        
        if [ "$SIZE" == "DEFAULT" ]; then
            cc -Wall -Wextra -Werror -g $MAIN_FILE "$SRC_GNL" "$SRC_UTILS" -I "${SOURCE_PATH}" -o gnl_tester
        else
            cc -Wall -Wextra -Werror -g -D BUFFER_SIZE=$SIZE $MAIN_FILE "$SRC_GNL" "$SRC_UTILS" -I "${SOURCE_PATH}" -o gnl_tester
        fi

        if [ $? -ne 0 ]; then
            echo -e "${RED}Compilation Error!${RESET}"
            echo "Compilation Error for BUFFER_SIZE=$SIZE" >> "$LOG_FILE"
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
                
                TEST_NAME="Mix $(basename "$FILE_A") + $(basename "$FILE_B")"
                echo -n "$TEST_NAME: "
                echo "Test: $TEST_NAME" >> "$LOG_FILE"
                
                timeout $TIMEOUT_VAL valgrind --leak-check=full --show-leak-kinds=all ./gnl_tester "$FILE_A" "$FILE_B" > outputs/user_output.txt 2> outputs/valgrind.log
                EXIT_CODE=$?

                if [ $EXIT_CODE -eq 124 ]; then
                    echo -e "${RED}[TIMEOUT]${RESET}"
                    echo "Result: TIMEOUT" >> "$LOG_FILE"
                elif [ $EXIT_CODE -eq 139 ]; then
                    echo -e "${RED}[SIGSEGV]${RESET}"
                    echo "Result: CRASH (SIGSEGV)" >> "$LOG_FILE"
                else
                    CHECK_OUT=$(python3 $CHECKER_FILE "$FILE_A" "$FILE_B" outputs/user_output.txt)
                    echo "$CHECK_OUT" | tr -d '\n'
                    echo "$CHECK_OUT" | strip_colors >> "$LOG_FILE"
                    echo -n " "
                    if grep -q "All heap blocks were freed -- no leaks are possible" outputs/valgrind.log; then
                        echo -e "${GREEN}[MOK]${RESET}"
                        echo "Valgrind: OK" >> "$LOG_FILE"
                    else
                        echo -e "${RED}[MKO]${RESET}"
                        echo "Valgrind: LEAKS DETECTED" >> "$LOG_FILE"
                    fi
                fi
                echo "----------------" >> "$LOG_FILE"
            done
            
            FILE_A="${FILES[NUM_FILES-1]}"
            FILE_B="${FILES[0]}"
            if [ -e "$FILE_A" ] && [ -e "$FILE_B" ]; then
                TEST_NAME="Mix $(basename "$FILE_A") + $(basename "$FILE_B")"
                echo -n "$TEST_NAME: "
                echo "Test: $TEST_NAME" >> "$LOG_FILE"

                timeout $TIMEOUT_VAL valgrind --leak-check=full --show-leak-kinds=all ./gnl_tester "$FILE_A" "$FILE_B" > outputs/user_output.txt 2> outputs/valgrind.log
                EXIT_CODE=$?

                if [ $EXIT_CODE -eq 124 ]; then
                    echo -e "${RED}[TIMEOUT]${RESET}"
                    echo "Result: TIMEOUT" >> "$LOG_FILE"
                elif [ $EXIT_CODE -eq 139 ]; then
                    echo -e "${RED}[SIGSEGV]${RESET}"
                    echo "Result: CRASH" >> "$LOG_FILE"
                else
                    CHECK_OUT=$(python3 $CHECKER_FILE "$FILE_A" "$FILE_B" outputs/user_output.txt)
                    echo "$CHECK_OUT" | tr -d '\n'
                    echo "$CHECK_OUT" | strip_colors >> "$LOG_FILE"
                    echo -n " "
                    if grep -q "All heap blocks were freed -- no leaks are possible" outputs/valgrind.log; then
                        echo -e "${GREEN}[MOK]${RESET}"
                        echo "Valgrind: OK" >> "$LOG_FILE"
                    else
                        echo -e "${RED}[MKO]${RESET}"
                        echo "Valgrind: LEAKS" >> "$LOG_FILE"
                    fi
                fi
                echo "----------------" >> "$LOG_FILE"
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
                TEST_NAME="Twin Mix $NAME + $NAME"
                echo -n "$TEST_NAME: "
                echo "Test: $TEST_NAME" >> "$LOG_FILE"
                
                timeout $TIMEOUT_VAL valgrind --leak-check=full --show-leak-kinds=all ./gnl_tester "$TWIN_FILE" "$TWIN_FILE" > outputs/user_output.txt 2> outputs/valgrind.log
                EXIT_CODE=$?

                if [ $EXIT_CODE -eq 124 ]; then
                    echo -e "${RED}[TIMEOUT]${RESET}"
                    echo "Result: TIMEOUT" >> "$LOG_FILE"
                elif [ $EXIT_CODE -eq 139 ]; then
                    echo -e "${RED}[SIGSEGV]${RESET}"
                    echo "Result: CRASH" >> "$LOG_FILE"
                else
                    CHECK_OUT=$(python3 $CHECKER_FILE "$TWIN_FILE" "$TWIN_FILE" outputs/user_output.txt)
                    echo "$CHECK_OUT" | tr -d '\n'
                    echo "$CHECK_OUT" | strip_colors >> "$LOG_FILE"
                    echo -n " "
                    if grep -q "All heap blocks were freed -- no leaks are possible" outputs/valgrind.log; then
                        echo -e "${GREEN}[MOK]${RESET}"
                        echo "Valgrind: OK" >> "$LOG_FILE"
                    else
                        echo -e "${RED}[MKO]${RESET}"
                        echo "Valgrind: LEAKS" >> "$LOG_FILE"
                    fi
                fi
                echo "----------------" >> "$LOG_FILE"
            fi

        else
            if [ -e "main_error.c" ]; then
                echo -n "Test INVALID FDs: "
                echo "Test: INVALID FDs" >> "$LOG_FILE"

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
                        echo "Result: TIMEOUT" >> "$LOG_FILE"
                    elif [ $EXIT_CODE -eq 139 ]; then
                        echo -e "${RED}[SIGSEGV]${RESET}"
                        echo "Result: CRASH" >> "$LOG_FILE"
                    else
                        RESULT=$(cat outputs/error_out.txt)
                        if [ "$RESULT" == "OK" ]; then
                             echo -ne "${GREEN}OK${RESET} "
                             echo "Result: OK" >> "$LOG_FILE"
                             if grep -q "All heap blocks were freed -- no leaks are possible" outputs/valgrind_error.log; then
                                echo -e "${GREEN}[MOK]${RESET}"
                                echo "Valgrind: OK" >> "$LOG_FILE"
                             else
                                echo -e "${RED}[MKO]${RESET}"
                                echo "Valgrind: LEAKS" >> "$LOG_FILE"
                             fi
                        else
                            echo -e "${RED}[KO] (Output: $RESULT)${RESET}"
                            echo "Result: KO (Output: $RESULT)" >> "$LOG_FILE"
                        fi
                    fi
                else
                    echo -e "${RED}[Compilation Fail]${RESET}"
                    echo "Result: Compilation Fail" >> "$LOG_FILE"
                fi
                rm -f gnl_error_tester
                echo "----------------" >> "$LOG_FILE"
            fi

            echo -n "Test STDIN (Pipe): "
            echo "Test: STDIN (Pipe)" >> "$LOG_FILE"
            echo -e "Line 1\nLine 2\nLine 3" | timeout $TIMEOUT_VAL valgrind --leak-check=full --show-leak-kinds=all ./gnl_tester > outputs/user_output.txt 2> outputs/valgrind.log
            EXIT_CODE=$?

            if [ $EXIT_CODE -eq 124 ]; then
                echo -e "${RED}[TIMEOUT]${RESET}"
                echo "Result: TIMEOUT" >> "$LOG_FILE"
            elif [ $EXIT_CODE -eq 139 ]; then
                echo -e "${RED}[SIGSEGV]${RESET}"
                echo "Result: CRASH" >> "$LOG_FILE"
            else
                echo -e "Line 1\nLine 2\nLine 3" > outputs/stdin_expected.txt
                CHECK_OUT=$(python3 $CHECKER_FILE outputs/stdin_expected.txt outputs/user_output.txt)
                echo "$CHECK_OUT" | tr -d '\n'
                echo "$CHECK_OUT" | strip_colors >> "$LOG_FILE"
                echo -n " "
                if grep -q "All heap blocks were freed -- no leaks are possible" outputs/valgrind.log; then
                    echo -e "${GREEN}[MOK]${RESET}"
                    echo "Valgrind: OK" >> "$LOG_FILE"
                else
                    echo -e "${RED}[MKO]${RESET}"
                    echo "Valgrind: LEAKS" >> "$LOG_FILE"
                fi
            fi
            echo "----------------" >> "$LOG_FILE"

            for file in files/*; do
                [ -e "$file" ] || continue
                FILENAME=$(basename "$file")
                
                timeout $TIMEOUT_VAL valgrind --leak-check=full --show-leak-kinds=all ./gnl_tester "$file" > outputs/user_output.txt 2> outputs/valgrind.log
                EXIT_CODE=$?
                
                echo -n "Test $FILENAME: "
                echo "Test: $FILENAME" >> "$LOG_FILE"
                
                if [ $EXIT_CODE -eq 124 ]; then
                    echo -e "${RED}[TIMEOUT]${RESET}"
                    echo "Result: TIMEOUT" >> "$LOG_FILE"
                elif [ $EXIT_CODE -eq 139 ]; then
                    echo -e "${RED}[SIGSEGV]${RESET}"
                    echo "Result: CRASH" >> "$LOG_FILE"
                else
                    CHECK_OUT=$(python3 $CHECKER_FILE "$file" outputs/user_output.txt)
                    echo "$CHECK_OUT" | tr -d '\n'
                    echo "$CHECK_OUT" | strip_colors >> "$LOG_FILE"
                    echo -n " " 
                    
                    if grep -q "All heap blocks were freed -- no leaks are possible" outputs/valgrind.log; then
                        echo -e "${GREEN}[MOK]${RESET}"
                        echo "Valgrind: OK" >> "$LOG_FILE"
                    else
                        echo -e "${RED}[MKO]${RESET}"
                        echo "Valgrind: LEAKS" >> "$LOG_FILE"
                    fi
                fi
                echo "----------------" >> "$LOG_FILE"
            done
        fi
        echo ""
    done

    rm -f gnl_tester
    rm -rf outputs
}

echo -e "\n${CYAN}=== GNL TESTER ===${RESET}"

if [ "$1" == "b" ]; then
    check_allowed_function
    run_gnl_tests "BONUS"
elif [ "$1" == "" ]; then
    check_allowed_function
    run_gnl_tests "MANDATORY"
    run_gnl_tests "BONUS"
elif [ "$1" == "m" ]; then
    check_allowed_function
    run_gnl_tests "MANDATORY"
else
    echo -e "${YELLOW}(Default: MANDATORY)${RESET}"
    check_allowed_function
    run_gnl_tests "MANDATORY"
fi
echo -e "\n${CYAN}=== DONE ===${RESET}"
