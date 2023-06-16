#!/bin/bash
set -e

msg() {
    echo [`date "+%Y-%m-%d %H:%M:%S"`] "${1-}"
}
start_time="$(date -u +%s)"

file=""
url=""
mode=""
lang="en"
name=""
path=""

# Parse the named arguments
while getopts "f:u:m:l:n:p:" opt; do
  case $opt in
    f) file="$OPTARG"
    ;;
    u) url="$OPTARG"
    ;;
    m) model="$OPTARG"
    ;;
    l) lang="$OPTARG"
    ;;
    n) name="$OPTARG"
    ;;
    p) path="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

# Check that either a file or a URL was specified
if [ -z "$url" ] && [ -z "$name" ]; then
  echo "Either a Url or a Name must be specified"
  exit 1
fi

if [ -z "$path" ]; then
  echo "ERROR: Path must be specified"
  exit 1
fi

if [ ! -z "$file" ] 
then
  audio_file_name=$file
else
  audio_file_name="temp"
fi

if [ ! -z "$name" ]; then
  url="https://youtu.be/$name"
fi

transcripts_dir="../../../transcripts/$path"

if [ ! -d "$transcripts_dir" ]; then
    echo "Output path specified of $transcripts_dir does not exist yet. Creating."
    mkdir $transcripts_dir
fi

if [ ! -z "$url" ]; then
  echo "URL: $url"
  msg "Extracting mp3 from $url..."
  yt-dlp -f bestaudio -x --audio-format mp3 --audio-quality 0 --add-metadata -o "$audio_file_name.%(ext)s" $url --write-info-json --force-overwrites -q
fi

msg "Converting mp3 to wav 16kHz..."
ffmpeg -i "$audio_file_name.mp3" -ar 16000 -ac 1 -c:a pcm_s16le "$audio_file_name.wav" -nostats -loglevel 16 -y

msg "Transcribing using model $model..."
whisper.cpp/main -f "$audio_file_name.wav" -otxt -of "$transcripts_dir/$name" -nt -pp -m whisper.cpp/models/ggml-$model.bin -l $lang

msg "All DONE!"
end_time="$(date -u +%s)"
secs="$(($end_time-$start_time))"
elapsed=$(printf '%02dh:%02dm:%02ds\n' $(($secs/3600)) $(($secs%3600/60)) $(($secs%60)))
msg "Total elapsed time: $elapsed"

msg "Clean up..."
rm -f temp.mp3
rm -f $audio_file_name.wav
rm -f temp.info.json
rm -f temp.webm

