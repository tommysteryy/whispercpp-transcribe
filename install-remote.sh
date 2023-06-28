#!/bin/bash
set -e

msg() {
    echo [`date "+%Y-%m-%d %H:%M:%S"`] "${1-}"
}

## Need to add your local bin, which is where yt-dlp will be downloaded by pip
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

if ! command -v yt-dlp &> /dev/null ; then
    msg "yt-dlp is not installed yet. Installing yt-dlp using pip... "
    pip install yt-dlp
fi

if ! command -v ffmpeg &> /dev/null ; then

    echo "ffmpeg command not currently found. Needs to be installed"

    # Check if a path was specified.
    if [ -z "$ffmpeg_location" ]; then
        echo "ERROR: ffmpeg zip must be specified"
        exit 1
    fi

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
whisper_binary="whisper.cpp/main"
whisper_models=$( jq -r '.whisper_models' config.json; )

# Check if the whisper directory does not exist
if [ ! -d "$whisper_dir" ]; then
    msg "Install whisper.cpp..."
    git clone https://github.com/ggerganov/whisper.cpp.git
fi

# Check if the whisper binary does not exist or if it is not executable
if [ ! -f "$whisper_binary" ] || [ ! -x "$whisper_binary" ]; then
    msg "Download $whisper_models and build whisper.cpp..."
    cd whisper.cpp
    for i in $whisper_models; do ./models/download-ggml-model.sh "$i"; done
    # replace origin main.cpp with modified output_txt() to remove extra new line characters
    cp ../main.cpp examples/main/
    make
fi

echo "Installation complete."