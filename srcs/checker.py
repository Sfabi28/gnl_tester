import sys
from datetime import datetime

GREEN = "\033[92m"
RED   = "\033[91m"
RESET = "\033[0m"

file_originale = sys.argv[1]
file_utente    = sys.argv[2]

with open(file_originale, 'r', errors='ignore') as f1:
    testo_corretto = f1.read()

with open(file_utente, 'r', errors='ignore') as f2:
    testo_tuo = f2.read()

if testo_corretto == testo_tuo:
    print(f"{GREEN}OK{RESET}")
else:
    print(f"{RED}KO{RESET}")
    try:
        with open('checker.log', 'a', encoding='utf-8', errors='ignore') as logf:
            logf.write(f"--- {datetime.now().isoformat()} ---\n")
            logf.write("EXPECTED:\n")
            logf.write(testo_corretto)
            if not testo_corretto.endswith('\n'):
                logf.write('\n')
            logf.write("---\n")
            logf.write("RECEIVED:\n")
            logf.write(testo_tuo)
            if not testo_tuo.endswith('\n'):
                logf.write('\n')
            logf.write("\n")
    except Exception:
        pass