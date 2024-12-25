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
required_packages=("curl" "wget")
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

verify_license_online() {
    key=$1
    response=$(curl -s -X POST -H "Content-Type: application/json" -d '{"license_key": "'$key'"}' https://your-license-server.com/api/verify)
    if [[ "$response" == *"\"valid\":true"* ]]; then
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
echo "{\"license_key\": \"$license_key\", \"language\": \"English\"}" > $config_dir/config.json

# Pobranie bota
bot_url="https://www.mediafire.com/file/u5cm3pmjf3e2ygp/CyberGuard.py/file"
bot_destination="$config_dir/cyberguardian_bot.py"
download_file $bot_url $bot_destination

# Tworzenie bazy danych
database_file="$config_dir/cyberguardian.db"
if [ ! -f "$database_file" ]; then
    echo "Tworzenie bazy danych..."
    sqlite3 $database_file "CREATE TABLE licenses (key TEXT PRIMARY KEY, valid_until DATE);"
    sqlite3 $database_file "INSERT INTO licenses (key, valid_until) VALUES ('$license_key', '2025-12-31');"
fi

# Uruchomienie bota
echo "Uruchamianie bota..."
python3 $bot_destination &

echo "Instalacja zakończona sukcesem! Bot został uruchomiony."

