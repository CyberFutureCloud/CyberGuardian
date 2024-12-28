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
required_packages=("curl" "wget" "jq")
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

# Weryfikacja klucza licencyjnego
read -p "Wprowadź klucz licencyjny: " license_key

SUPABASE_URL="https://qfsnfurfqvhychkmxlvl.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFmc25mdXJmcXZoeWNoa214bHZsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzUzMzY0OTIsImV4cCI6MjA1MDkxMjQ5Mn0.l14dBfHv1yW01VuRWViqOFlojOcLdVpfWCI92AuAbxI"

verify_license_online() {
    key=$1

    response=$(curl -s -X POST \
        -H "apikey: $SUPABASE_KEY" \
        -H "Authorization: Bearer $SUPABASE_KEY" \
        -H "Content-Type: application/json" \
        -d '{"license_key": "'"$key"'"}' \
        "$SUPABASE_URL/rest/v1/rpc/verify_license")

    valid=$(echo "$response" | jq -r '.valid')
    if [ "$valid" == "true" ]; then
        echo "Licencja zweryfikowana pomyślnie."
        return 0
    else
        echo "Nieprawidłowy klucz licencyjny."
        return 1
    fi
}

verify_license_online $license_key
if [ $? -ne 0 ]; then
    exit 1
fi

# Tworzenie katalogu konfiguracyjnego
config_dir="$HOME/.cyberguardian"
mkdir -p $config_dir

# Zapisz konfigurację do pliku
echo "Zapisuję dane konfiguracyjne..."
echo "{\"license_key\": \"$license_key\", \"email\": \"$email\", \"language\": \"English\"}" > $config_dir/config.json

# Pobranie bota
bot_url="https://www.mediafire.com/file/u5cm3pmjf3e2ygp/CyberGuard.py/file"
bot_destination="$config_dir/cyberguardian_bot.py"
download_file $bot_url $bot_destination

# Uruchomienie bota
echo "Uruchamianie bota..."
python3 $bot_destination &

echo "Instalacja zakończona sukcesem! Bot został uruchomiony."


