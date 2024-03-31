#!/bin/bash

# Sprawdzenie dostępności narzędzi
if ! command -v rec &> /dev/null; then
    echo "Narzędzie 'rec' nie jest dostępne. Zainstaluj SoX (Sound eXchange)."
    exit 1
fi

if ! command -v ffmpeg &> /dev/null; then
    echo "Narzędzie 'ffmpeg' nie jest dostępne. Zainstaluj ffmpeg."
    exit 1
fi

if ! command -v whisper &> /dev/null; then
    echo "Narzędzie 'whisper' nie jest dostępne. Zainstaluj Whisper."
    exit 1
fi

echo "Podaj pełną ścieżkę do zapisu pliku wejściowego (bez rozszerzenia):"
read inputPath

echo "Wybierz format pliku tekstowego (txt/vtt/srt/tsv/json/all):"
read outputFormat

outputDir=$(dirname "$inputPath")
outputBase=$(basename "$inputPath")

# Dalej możesz kontynuować z operacjami na pliku, ponieważ jest już zweryfikowany.


outputWavPath="$inputPath.wav"
outputMp3Path="$inputPath.mp3"

echo "Wybierz język (Polish/English) lub naciśnij Enter, aby użyć domyślnego (Polish):"
read language

if [[ -z "$language" ]]; then
  language="Polish"
else
  language="${language^}"
fi

# Nagrywanie dźwięku i konwersja na MP3
rec "$outputWavPath" &&
ffmpeg -i "$outputWavPath" -vn -ar 44100 -ac 2 -b:a 192k "$outputMp3Path"

# o cos takiego chodzi !!
 #rec /tmp/input.wav && ffmpeg -i /tmp/input.wav -vn -ar 44100 -ac 2 -b:a 192k /tmp/input.mp3 && whisper /tmp/input.mp3 --model small --language Polish --output_dir /tmp --output_format txt --verbose False  --threads 4 --device cuda


# Wywołanie whisper do przetwarzania pliku MP3
whisper "$outputMp3Path" --model small --language "$language" --output_dir "$outputDir" --output_format "$outputFormat" --verbose False --threads 4 --device cuda
	
# Oczekiwanie 1 sekundy i wyświetlenie wyniku
sleep 1

# Sprawdzenie, czy wynik istnieje, a następnie wyświetlenie go
outputFile="$outputDir/$outputBase.$outputFormat"
if [ -f "$outputFile" ]; then
  cat "$outputFile"
else
  echo "Wystąpił błąd podczas przetwarzania."
fi

