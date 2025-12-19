import sys


file_originale = sys.argv[1]
file_utente    = sys.argv[2]


with open(file_originale, 'r') as f1:
    testo_corretto = f1.read()


with open(file_utente, 'r') as f2:
    testo_tuo = f2.read()


if testo_corretto == testo_tuo:
    print("OK")
else:
    print("KO\n")
    print("Expected output: ")
    print("\n")
    print(testo_corretto)
    print("\n")
    print("Your output: ")
    print("\n")
    print(testo_tuo)