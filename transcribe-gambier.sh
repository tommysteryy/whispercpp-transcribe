#!/bin/bash

export PATH=$PATH:/home/t/txu25/.local/bin
# Initialize a variable for the path and model
path=""
model=""

# Use getopts to parse the command line options
while getopts "p:m:" opt; do
  case $opt in
    # If the option is p, set the path variable to its argument
    p) path="$OPTARG"
    ;;
    # If the option is m, set the model variable to its argument
    m) model="$OPTARG"
    ;;
    # If the option is invalid, output an error message
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

# Check if path was specified, if not, output an error message and exit with status 1
if [ -z "$path" ]; then
    echo "ERROR: Must specify a path for the transcripts to be downloaded into. See <repo_root>/transcripts for examples"
    exit 1
fi

# If no model specified, default to "small.en"
if [ -z "$model" ]; then
    echo "Did not specify model, so defaulting to small.en"
    model="small.en"
fi

# Change directory to our whisper cpp transcription service
# cd whispercpp-transcribe

# The file from which we will read the data
inputFile="../curr_video_list_gambier.txt"

# This loop will continue as long as there are lines to be read from the file
# We're using file descriptor 3 instead of stdin to avoid interference during subprocess calls.
while IFS= read -r -u 3 line; do
    # Run the main.sh script with the current line, chosen model, and path as arguments
    ./main-gambier.sh -n "$line" -m "$model" -p "$path"
done 3<"$inputFile"

# Exit the script
exit
