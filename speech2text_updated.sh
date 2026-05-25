#!/usr/bin/env bash
set -euo pipefail

# =========================
# CHECK DEPENDENCIES
# =========================

if ! command -v ffmpeg &>/dev/null; then
    echo "[!] Brak ffmpeg"
    exit 1
fi

if ! command -v rec &>/dev/null; then
    echo "[!] Brak 'rec' (SoX)."
    echo "Zainstaluj:"
    echo "sudo apt install sox"
    exit 1
fi

# Whisper CLI fallback
WHISPER_CMD=""

if command -v whisper &>/dev/null; then
    WHISPER_CMD="whisper"
elif python3 -c "import whisper" &>/dev/null; then
    WHISPER_CMD="python3 -m whisper"
else
    echo "[!] Whisper nie znaleziony."
    echo "Install:"
    echo "pip install openai-whisper"
    exit 1
fi

# =========================
# INPUT
# =========================

read -rp "Podaj ścieżkę zapisu (bez rozszerzenia): " inputPath
read -rp "Format output (txt/vtt/srt/tsv/json/all): " outputFormat

outputDir=$(dirname "$inputPath")
outputBase=$(basename "$inputPath")

outputWavPath="${inputPath}.wav"
outputMp3Path="${inputPath}.mp3"

read -rp "Język [Polish/English] (default: Polish): " language

language=$(echo "$language" | tr '[:upper:]' '[:lower:]')

case "$language" in
  Polish|polish|pl|"")
    language="pl"
    ;;
  English|english|en)
    language="en"
    ;;
  *)
    language="pl"
    ;;
esac

mkdir -p "$outputDir"

# =========================
# RECORDING
# =========================

echo
echo "======================================"
echo "🎤 Za chwilę zacznie się nagrywanie"
echo "Naciśnij CTRL+C aby anulować"
echo "Nagrywanie zatrzymasz ENTEREM"
echo "======================================"

for i in 3 2 1; do
    echo "Start za: $i"
    sleep 1
done

echo
echo "🔴 NAGRYWANIE..."
echo "➡️  Mów teraz. ENTER kończy."

rec "$outputWavPath" &
REC_PID=$!

read -r

kill -INT "$REC_PID"
wait "$REC_PID" 2>/dev/null || true

echo "✅ Nagranie zakończone"

# =========================
# CONVERT
# =========================

echo "[*] Konwersja WAV → MP3"

ffmpeg -y \
    -i "$outputWavPath" \
    -vn \
    -ar 44100 \
    -ac 2 \
    -b:a 192k \
    "$outputMp3Path" \
    -loglevel error

echo "✅ MP3 gotowe"

# =========================
# WHISPER
# =========================

echo "[*] Transkrypcja (CPU)..."

python3 - <<EOF
from faster_whisper import WhisperModel


#TO ROBIMY JAK CHCEMY MIEC CUDA
#model = WhisperModel(
#    "small",
#    device="cuda",
#    compute_type="float16"
#)

model = WhisperModel(
    "small",
    device="cpu",
    compute_type="int8"
)
segments, info = model.transcribe(
    "$outputMp3Path",
    language="$language",
    beam_size=1
)

outfile = "$outputDir/$outputBase.$outputFormat"

with open(outfile, "w", encoding="utf-8") as f:
    for segment in segments:
        f.write(segment.text.strip() + "\n")

print("DONE")
EOF

# =========================
# SHOW RESULT
# =========================

sleep 1

outputFile="$outputDir/$outputBase.$outputFormat"

if [[ -f "$outputFile" ]]; then
    echo
    echo "========== WYNIK =========="
    cat "$outputFile"
else
    echo "[!] Nie znaleziono wyniku: $outputFile"
fi
      
