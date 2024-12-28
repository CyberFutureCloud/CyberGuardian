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
required_packages=("curl" "wget" "jq" "postgresql")
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

# Instalacja zależności dla Pythona
echo "Instalowanie zależności Pythona..."
if ! command -v pip &> /dev/null; then
    echo "pip nie jest zainstalowany. Instalowanie..."
    sudo apt-get install -y python3-pip
fi

pip install supabase

# Weryfikacja klucza licencyjnego
read -p "Wprowadź klucz licencyjny: " license_key

# Zmienna środowiskowa z URL do Supabase
SUPABASE_URL="https://qfsnfurfqvhychkmxlvl.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFmc25mdXJmcXZoeWNoa214bHZsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzUzMzY0OTIsImV4cCI6MjA1MDkxMjQ5Mn0.l14dBfHv1yW01VuRWViqOFlojOcLdVpfWCI92AuAbxI"

# Funkcja do weryfikacji klucza licencyjnego za pomocą klienta Supabase w Pythonie
verify_license_online() {
    python3 - <<EOF
from supabase import create_client, Client

# URL i klucz API (z panelu Supabase)
url = "$SUPABASE_URL"
key = "$SUPABASE_KEY"

# Utworzenie klienta Supabase
supabase: Client = create_client(url, key)

# Zapytanie do tabeli z kluczem licencyjnym (przykład)
response = supabase.table('licenses').select('license_key').eq('license_key', '$license_key').execute()

# Sprawdzanie odpowiedzi
if response.data:
    print("Klucz licencyjny jest poprawny")
    exit(0)
else:
    print("Klucz licencyjny jest nieprawidłowy")
    exit(1)
EOF
}

verify_license_online
if [ $? -ne 0 ]; then
    echo "Zatrzymywanie skryptu z powodu błędnego klucza licencyjnego."
    exit 1
fi

# Tworzenie katalogu konfiguracyjnego
config_dir="$HOME/.cyberguardian"
mkdir -p $config_dir

# Zapisz dane konfiguracyjne do pliku
echo "Zapisuję dane konfiguracyjne..."
echo "{\"license_key\": \"$license_key\", \"language\": \"English\"}" > $config_dir/config.json

# Pobranie bota
bot_url="https://www.mediafire.com/file/u5cm3pmjf3e2ygp/CyberGuard.py/file"
bot_destination="$config_dir/cyberguardian_bot.py"
download_file $bot_url $bot_destination

# Sprawdzanie pliku bota przed uruchomieniem (opcjonalne)
echo "Sprawdzam plik bota..."
if ! python3 -m py_compile $bot_destination; then
    echo "Błąd w pliku bota. Nie można uruchomić."
    exit 1
fi

# Uruchomienie bota
echo "Uruchamianie bota..."
python3 $bot_destination &

echo "Instalacja zakończona sukcesem! Bot został uruchomiony."

