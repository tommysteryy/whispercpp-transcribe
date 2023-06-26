#!/bin/bash

# Initialize a variable for the path and model
model=""

# Use getopts to parse the command line options
while getopts "m:" opt; do
  case $opt in
    # If the option is m, set the model variable to its argument
    m) model="$OPTARG"
    ;;
    # If the option is invalid, output an error message
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

# If no model specified, default to "small.en"
if [ -z "$model" ]; then
    echo "Did not specify model, so defaulting to small.en"
    model="small.en"
fi

# The file from which we will read the data
inputFile="../curr_video_list.txt"

# This loop will continue as long as there are lines to be read from the file
# We're using file descriptor 3 instead of stdin to avoid interference during subprocess calls.
while IFS= read -r -u 3 line; do

    # Find the path with the path finding script
    youtuber=$(./find_creator.sh "$line")

    # Check if the result starts with "Error" or "No file found", meaning it did not match a youtuber
    
    if [[ $youtuber == Error* || $youtuber == "No file found"* ]]; then
        echo "Error finding path for $line: $youtuber. Skipping"
        continue  # Skip to the next iteration
    fi

    # Run the main.sh script with the current line, chosen model, and path as arguments
    ./main.sh -n "$line" -m "$model" -p "$youtuber"
done 3<"$inputFile"

# Exit the script
exit