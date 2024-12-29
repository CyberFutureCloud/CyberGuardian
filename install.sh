#!/bin/bash

# Funkcja do pobierania pliku
download_file() {
    url=$1
    destination=$2
    echo "Pobieranie pliku z $url..."
    curl -L $url -o $destination
    if [ $? -ne 0 ]; then
        echo "Błąd podczas pobierania pliku."
        exit 1
    fi
    echo "Plik pobrany do: $destination"
}

# Instalacja wymaganych pakietów
echo "Instalowanie wymaganych pakietów..."
required_packages=("curl" "wget" "jq" "python3-venv" "python3-pip")
for pkg in "${required_packages[@]}"; do
    if ! command -v $pkg &> /dev/null; then
        echo "$pkg nie jest zainstalowany. Instalowanie..."
        sudo apt-get install -y $pkg
        if [ $? -ne 0 ]; then
            echo "Błąd podczas instalacji $pkg."
            exit 1
        fi
    fi
done

# Tworzenie wirtualnego środowiska
echo "Tworzenie wirtualnego środowiska..."
python3 -m venv venv

# Aktywacja wirtualnego środowiska
source venv/bin/activate

# Instalowanie wymaganych pakietów Pythona
echo "Instalowanie wymaganych pakietów Python..."
pip install --upgrade pip
pip install requests

# Wprowadzenie e-maila użytkownika
read -p "Wprowadź e-mail przypisany do licencji: " user_email

# Wprowadzenie kodu produktu
read -p "Wprowadź kod produktu (Product Key): " product_key

# Wprowadzenie klucza licencyjnego
read -p "Wprowadź klucz licencyjny (License Key): " license_key

# Zmienna środowiskowa z URL do Payhip API
PAYHIP_API_URL="https://payhip.com/api/v2/license/verify"

# Klucz API (na stałe w skrypcie)
API_KEY="prod_sk_DrFnK_31e3c894dcd73549cc47020ef10ed00f1c15a555"

# Funkcja do weryfikacji klucza licencyjnego za pomocą API Payhip
verify_license_online() {
    python3 - <<EOF
import requests
import json

# URL API Payhip
api_url = "$PAYHIP_API_URL"
api_key = "$API_KEY"  # Klucz API (predefiniowany)
license_key = "$license_key"  # Klucz licencyjny
product_key = "$product_key"  # Kod produktu
user_email = "$user_email"  # Adres e-mail

# Nagłówki zawierające klucz API
headers = {
    "Authorization": f"Bearer {api_key}"
}

# Parametry zapytania
params = {
    "license_key": license_key,
    "product_key": product_key
}

# Wysłanie zapytania GET do API
response = requests.get(api_url, headers=headers, params=params)

# Logowanie odpowiedzi dla diagnostyki
try:
    print(f"Status code: {response.status_code}")
    print(f"Response: {response.text}")
    if response.status_code == 200:
        data = response.json()
        if "data" in data:
            # Sprawdzenie, czy e-mail w odpowiedzi zgadza się z wprowadzonym
            if data['data']['buyer_email'].lower() == user_email.lower():
                print("Klucz licencyjny jest poprawny.")
                print(f"Buyer Email: {data['data']['buyer_email']}")
                print(f"License Key: {data['data']['license_key']}")
                print(f"Product Key: {product_key}")
                print(f"Product Link: {data['data']['product_link']}")
                print(f"Enabled: {data['data']['enabled']}")
                exit(0)
            else:
                print("E-mail przypisany do tego klucza licencyjnego nie zgadza się z wprowadzonym e-mailem.")
                exit(1)
        else:
            print("Nie znaleziono danych licencji w odpowiedzi.")
            exit(1)
    else:
        print(f"Błąd weryfikacji: Status {response.status_code}")
        exit(1)
except Exception as e:
    print(f"Nieoczekiwany błąd: {e}")
    exit(1)
EOF
}

# Wywołanie funkcji weryfikacji
verify_license_online

# Sprawdzenie, czy funkcja zakończyła się powodzeniem
if [ $? -ne 0 ]; then
    echo "Zatrzymywanie skryptu z powodu błędnego klucza licencyjnego lub niezgodnego e-maila."
    exit 1
fi

# Tworzenie katalogu konfiguracyjnego
config_dir="$HOME/.cyberguardian"
mkdir -p $config_dir

# Zapisz dane konfiguracyjne do pliku
echo "Zapisuję dane konfiguracyjne..."
echo "{\"license_key\": \"$license_key\", \"language\": \"English\"}" > $config_dir/config.json

# Pobranie bota
bot_repo_url="https://github.com/CyberFutureCloud/BOT-CYBG-1.git"
bot_destination="$config_dir/CyberGuardian"

echo "Klonowanie repozytorium z $bot_repo_url..."
git clone $bot_repo_url $bot_destination

if [ $? -ne 0 ]; then
    echo "Błąd podczas klonowania repozytorium z GitHub."
    exit 1
fi

echo "Repozytorium zostało pomyślnie sklonowane do: $bot_destination"

cd $bot_destination

# Sprawdzanie pliku bota przed uruchomieniem
echo "Sprawdzam plik bota..."
main_bot_file="cyberguardian_bot.py"
if [ ! -f "$main_bot_file" ]; then
    echo "Błąd: Nie znaleziono głównego pliku bota ($main_bot_file)."
    exit 1
fi

# Kompilacja pliku bota
if ! python3 -m py_compile "$main_bot_file"; then
    echo "Błąd w pliku bota. Nie można uruchomić."
    exit 1
fi

# Uruchomienie bota
echo "Uruchamianie bota..."
python3 "$main_bot_file" &

echo "Instalacja zakończona sukcesem! Bot został uruchomiony."




