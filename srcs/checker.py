import sys

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
    print(RED)
    print("KO\n")
    print("Expected output: ")
    print("\n")
    print(testo_corretto)
    print("\n")
    print("Your output: ")
    print("\n")
    print(testo_tuo)
    print(RESET)