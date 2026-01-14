import sys
import os
from datetime import datetime

GREEN = "\033[92m"
RED   = "\033[91m"
RESET = "\033[0m"

file_originale = sys.argv[1]
file_utente    = sys.argv[2]
marker = '\x04'

with open(file_originale, 'r', errors='ignore') as f1:
    testo_corretto = f1.read()

with open(file_utente, 'r', errors='ignore') as f2:
    testo_tuo = f2.read()

problem = None
for idx in range(len(testo_tuo)-1):
    if testo_tuo[idx] == '\n':
        if testo_tuo[idx+1] != marker:
            problem = ("marker_missing_after_newline", idx)
            break

testo_tuo_clean = testo_tuo.replace(marker, "")
if problem is None and testo_tuo_clean != testo_corretto:
    problem = ("content_mismatch_after_strip", None)

if problem is None:
    print(f"{GREEN}[OK]{RESET}")
else:
    print(f"{RED}[KO]{RESET}")
    try:
        with open('checker.log', 'a', encoding='utf-8', errors='ignore') as logf:
            logf.write(f"--- {datetime.now().isoformat()} ---\n")
            logf.write(f"PROBLEM: {problem[0]}\n")
            if problem[1] is not None:
                logf.write(f"POSITION: {problem[1]}\n")
            logf.write("EXPECTED:\n")
            logf.write(testo_corretto)
            if not testo_corretto.endswith('\n'):
                logf.write('\n')
            logf.write("---\n")
            logf.write("RECEIVED (cleaned):\n")
            logf.write(testo_tuo_clean)
            if not testo_tuo_clean.endswith('\n'):
                logf.write('\n')
            logf.write("RECEIVED (raw):\n")
            logf.write(testo_tuo)
            if not testo_tuo.endswith('\n'):
                logf.write('\n')
            logf.write("\n")
    except Exception:
        pass