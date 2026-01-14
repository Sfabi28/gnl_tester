import sys
import time
from datetime import datetime

GREEN = "\033[92m"
RED   = "\033[91m"
RESET = "\033[0m"

if len(sys.argv) < 3:
    print(f"{RED}Usage: checker.py expected_file user_output_file{RESET}")
    raise SystemExit(1)

file_originale = sys.argv[1]
file_utente    = sys.argv[2]

try:
    with open(file_originale, 'r', errors='ignore') as f1:
        expected_lines = f1.readlines()
except Exception:
    print(f"{RED}Error reading expected file{RESET}")
    raise SystemExit(1)

try:
    with open(file_utente, 'r', errors='ignore') as fu:
        for i, expected in enumerate(expected_lines, start=1):
            timeout = time.time() + 10.0
            received = None
            while True:
                pos = fu.tell()
                line = fu.readline()
                if line == '':
                    if time.time() > timeout:
                        print(f"{RED}KO{RESET}")
                        try:
                            with open('checker.log', 'a', encoding='utf-8', errors='ignore') as logf:
                                logf.write(f"--- {datetime.now().isoformat()} ---\n")
                                logf.write(f"TIMEOUT AT READ #{i}\n")
                                logf.write("EXPECTED_LINE:\n")
                                logf.write(repr(expected) + "\n")
                                logf.write("RECEIVED_LINE:\n")
                                logf.write(repr(None) + "\n")
                                logf.write("FULL EXPECTED:\n")
                                logf.writelines(expected_lines)
                                if expected_lines and not expected_lines[-1].endswith('\n'):
                                    logf.write('\n')
                                logf.write("---\n")
                                logf.write("FULL RECEIVED:\n")
                                fu.seek(0)
                                full = fu.read()
                                logf.write(full)
                                if full and not full.endswith('\n'):
                                    logf.write('\n')
                                logf.write("\n")
                        except Exception:
                            pass
                        raise SystemExit(1)
                    time.sleep(0.05)
                    fu.seek(pos)
                    continue
                else:
                    received = line
                    if received != expected:
                        print(f"{RED}KO{RESET}")
                        try:
                            with open('checker.log', 'a', encoding='utf-8', errors='ignore') as logf:
                                logf.write(f"--- {datetime.now().isoformat()} ---\n")
                                logf.write(f"MISMATCH AT READ #{i}\n")
                                logf.write("EXPECTED_LINE:\n")
                                logf.write(repr(expected) + "\n")
                                logf.write("RECEIVED_LINE:\n")
                                logf.write(repr(received) + "\n")
                                logf.write("FULL EXPECTED:\n")
                                logf.writelines(expected_lines)
                                if expected_lines and not expected_lines[-1].endswith('\n'):
                                    logf.write('\n')
                                logf.write("---\n")
                                logf.write("FULL RECEIVED:\n")
                                fu.seek(0)
                                full = fu.read()
                                logf.write(full)
                                if full and not full.endswith('\n'):
                                    logf.write('\n')
                                logf.write("\n")
                        except Exception:
                            pass
                        raise SystemExit(1)
                    break
        print(f"{GREEN}OK{RESET}")
except Exception:
    print(f"{RED}Error reading user file{RESET}")
    raise SystemExit(1)