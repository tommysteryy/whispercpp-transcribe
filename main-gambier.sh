#!/bin/bash

# Make the script exit when a command fails.
set -e

# Function to display a message with a timestamp.
msg() {
    echo [`date "+%Y-%m-%d %H:%M:%S"`] "${1-}"
}

# Store the start time of the script.
start_time="$(date -u +%s)"

# Initialize variables.
file=""
url=""
mode=""
lang="en"
name=""
path=""

# Parse the command line arguments.
while getopts "f:u:m:l:n:p:" opt; do
  case $opt in
    f) file="$OPTARG"     # File name.
    ;;
    u) url="$OPTARG"      # URL.
    ;;
    m) model="$OPTARG"    # Model.
    ;;
    l) lang="$OPTARG"     # Language.
    ;;
    n) name="$OPTARG"     # Name.
    ;;
    p) path="$OPTARG"     # Path.
    ;;
    \?) echo "Invalid option -$OPTARG" >&2   # Invalid option error message.
    ;;
  esac
done

# Check if a URL or a name was specified.
if [ -z "$url" ] && [ -z "$name" ]; then
  echo "Either a Url or a Name must be specified"
  exit 1
fi

# Check if a path was specified.
if [ -z "$path" ]; then
  echo "ERROR: Path must be specified"
  exit 1
fi

# If a name is specified, form the URL.
if [ ! -z "$name" ]; then
  url="https://youtu.be/$name"
fi

# Check if a transcript for "$name" already exists.
if grep -Fxq -- "$name" "../completed_videos_gambier.txt" ; then
  echo "File $name.txt already completed. Stopping job."
  exit 0
fi

# Check if a model was specified.
if [ -z "$model" ]; then
  echo "Model not specified. Defaulting to small.en"
  model="small.en"
fi

# Assign a name to the audio file.
if [ ! -z "$file" ] 
then
  audio_file_name=$file
else
  audio_file_name="temp_gambier"
fi


# Define the directory for transcripts.
transcripts_dir="../../../transcripts/$path"

# If the directory doesn't exist, create it.
if [ ! -d "$transcripts_dir" ]; then
    echo "Output path specified of $transcripts_dir does not exist yet. Creating."
    mkdir $transcripts_dir
fi

echo "Transcript will be saved to $transcripts_dir/$name"

# If a URL is specified, extract the audio from it.
if [ ! -z "$url" ]; then
  echo "URL: $url"
  msg "Extracting mp3 from $url..."
  yt-dlp -f bestaudio -x --audio-format mp3 --audio-quality 0 --add-metadata -o "$audio_file_name.%(ext)s" $url --write-info-json --force-overwrites -q
fi

# Convert the audio to the needed format.
msg "Converting mp3 to wav 16kHz..."
ffmpeg -i "$audio_file_name.mp3" -ar 16000 -ac 1 -c:a pcm_s16le "$audio_file_name.wav" -nostats -loglevel 16 -y

# Use the model to transcribe the audio.
msg "Transcribing using model $model..."
whisper.cpp/main -f "$audio_file_name.wav" -otxt -of "$transcripts_dir/$name" -nt -pp -m whisper.cpp/models/ggml-$model.bin -l $lang -p 4

# After successful transcription, add the name to processed videos list
echo "$name" >> "../completed_videos_gambier.txt"
echo "Added $name to the completed videos."

# End of the script operations.
msg "All DONE!"

# Calculate and display the elapsed time.
end_time="$(date -u +%s)"
secs="$(($end_time-$start_time))"
elapsed=$(printf '%02dh:%02dm:%02ds\n' $(($secs/3600)) $(($secs%3600/60)) $(($secs%60)))
msg "Total elapsed time: $elapsed"

# Clean up temporary files.
msg "Clean up..."
rm -f $audio_file_name.mp3
rm -f $audio_file_name.wav
rm -f $audio_file_name.json
rm -f $audio_file_name.webm
