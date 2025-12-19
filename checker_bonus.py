import sys
from itertools import zip_longest

GREEN = "\033[92m"
RED   = "\033[91m"
RESET = "\033[0m"

def solve():
    if len(sys.argv) < 4:
        return

    file1_path = sys.argv[1]
    file2_path = sys.argv[2]
    user_output_path = sys.argv[3]

    expected_output = []

    try:
        with open(file1_path, 'r', errors='ignore') as f1, open(file2_path, 'r', errors='ignore') as f2:
            lines1 = f1.readlines()
            lines2 = f2.readlines()
            
            for l1, l2 in zip_longest(lines1, lines2, fillvalue=None):
                if l1 is not None:
                    expected_output.append(l1)
                if l2 is not None:
                    expected_output.append(l2)
    except Exception as e:
        print(f"{RED}Error reading input files: {e}{RESET}")
        return

    expected_string = "".join(expected_output)

    try:
        with open(user_output_path, 'r', errors='ignore') as fu:
            actual_string = fu.read()
    except Exception as e:
        print(f"{RED}Error reading user output: {e}{RESET}")
        return

    if expected_string == actual_string:
        print(f"{GREEN}[OK]{RESET}")
    else:
        print(f"{RED}[KO]{RESET}")
        print("--- EXPECTED MIX ---")
        print(expected_string)
        print("--- YOUR MIX ---")
        print(actual_string)

if __name__ == "__main__":
    solve()