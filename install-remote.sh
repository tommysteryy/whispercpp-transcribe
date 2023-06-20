#!/bin/bash
set -e

msg() {
    echo [`date "+%Y-%m-%d %H:%M:%S"`] "${1-}"
}

export PATH=$PATH:/home/t/txu25/.local/bin

ffmpeg_location=""

while getopts "f:" opt; do
  case $opt in
    f) ffmpeg_location="$OPTARG"     # File of the zip for ffmpeg binary
    ;;
    \?) echo "Invalid option -$OPTARG" >&2   # Invalid option error message.
    ;;
  esac
done

# Check if a path was specified.
if [ -z "$ffmpeg_location" ]; then
  echo "ERROR: ffmpeg zip must be specified"
  exit 1
fi

if ! command -v yt-dlp &> /dev/null ; then
    msg "yt-dlp is not installed yet. Installing yt-dlp using pip... "
    pip install yt-dlp
fi

if ! command -v ffmpeg &> /dev/null ; then

    if ! command -v ./ffmpeg &> /dev/null ; then
        msg "Checking if ffmpeg zip is valid..."
        
        # Check if the file exists and is a valid zip file.
        if [ -f "$ffmpeg_location" ] && zipinfo $ffmpeg_location >/dev/null 2>&1 ; then
            msg "Install ffmpeg into $pwd/ffmpeg"
            unzip $ffmpeg_location
            msg "ffmpeg can now be ran with ./ffmpeg"
        else
            msg "ERROR: ffmpeg zip is not valid or does not exist"
            exit 1
        fi
    fi

fi

whisper_dir="whisper.cpp"
whisper_models=$( jq -r '.whisper_models' config.json; )
if ! [ -d "$whisper_dir" ]; then
    msg "Install whisper.cpp and download $whisper_models..."
    git clone https://github.com/ggerganov/whisper.cpp.git
    
    cd whisper.cpp
    for i in $whisper_models; do ./models/download-ggml-model.sh "$i"; done
    # replace origin main.cpp with modified output_txt() to remove extra new line characters
    cp ../main.cpp examples/main/
    make
fi

msg "Installation is finished."