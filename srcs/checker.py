import sys
from datetime import datetime
from itertools import zip_longest

GREEN = "\033[92m"
RED   = "\033[91m"
RESET = "\033[0m"

file_originale = sys.argv[1]
file_utente    = sys.argv[2]

with open(file_originale, 'r', errors='ignore') as f1:
    expected_lines = f1.readlines()

with open(file_utente, 'r', errors='ignore') as f2:
    received_lines = f2.readlines()

for i, (e, r) in enumerate(zip_longest(expected_lines, received_lines, fillvalue=None), start=1):
    if e != r:
        print(f"{RED}KO{RESET}")
        try:
            with open('errors.log', 'a', encoding='utf-8', errors='ignore') as logf:
                logf.write(f"--- {datetime.now().isoformat()} ---\n")
                logf.write(f"MISMATCH AT READ #{i}\n")
                logf.write("EXPECTED_LINE:\n")
                logf.write(repr(e) + "\n")
                logf.write("RECEIVED_LINE:\n")
                logf.write(repr(r) + "\n")
                logf.write("FULL EXPECTED:\n")
                if expected_lines:
                    logf.writelines(expected_lines)
                    if not expected_lines[-1].endswith('\n'):
                        logf.write('\n')
                logf.write("---\n")
                logf.write("FULL RECEIVED:\n")
                if received_lines:
                    logf.writelines(received_lines)
                    if not received_lines[-1].endswith('\n'):
                        logf.write('\n')
                logf.write("\n")
        except Exception:
            pass
        break
else:
    print(f"{GREEN}OK{RESET}")