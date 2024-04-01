#!/bin/bash

# Check the availability of tools
if ! command -v rec &> /dev/null; then
    echo "The 'rec' tool is not available. Please install SoX (Sound eXchange) which includes 'rec'."
    exit 1
fi

if ! command -v ffmpeg &> /dev/null; then
    echo "The 'ffmpeg' utility is not available. Install ffmpeg."
    exit 1
fi

if ! command -v whisper &> /dev/null; then
    echo "The 'whisper' tool is not available. Install Whisper."
#Imoprtant note - use OpenAI-Whisper, installation via pip install git+https://github.com/openai/whisper.git
    exit 1
fi

echo "Provide the full path to save the input file (without extension), example '/tmp/myfile' :"
read inputPath

echo "Select text file format (txt/vtt/srt/tsv/json/all):"
read outputFormat

outputDir=$(dirname "$inputPath")
outputBase=$(basename "$inputPath")

outputWavPath="$inputPath.wav"
outputMp3Path="$inputPath.mp3"

echo "Select language (Polish/English) or press Enter to use default (English):"
#Important: Whisper includes dozens of languages, this is just a PoC wrapper 
read language

if [[ -z "$language" ]]; then
  language="English"
else
  language="${language^}"
fi

# Record audio and convert to MP3
rec "$outputWavPath" &&
ffmpeg -i "$outputWavPath" -vn -ar 44100 -ac 2 -b:a 192k "$outputMp3Path"

# Whisper converts MP3 to textfile
whisper "$outputMp3Path" --model small --language "$language" --output_dir "$outputDir" --output_format "$outputFormat" --verbose False --threads 4 --device cuda

sleep 1

# Final check and print the result
outputFile="$outputDir/$outputBase.$outputFormat"
if [ -f "$outputFile" ]; then
  cat "$outputFile"
else
  echo "Error! You may try to run sub-sections of script separately to see where the problem comes from."
fi
