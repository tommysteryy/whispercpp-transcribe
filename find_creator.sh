#!/bin/bash

# Name of the file is passed as a parameter.
name=$1

# Check if the name parameter is not empty.
if [ -z "$name" ]; then
    echo "Please provide a file name as a parameter."
    exit 1
fi

# Search in all "video_list.txt" files within the "transcripts" directory.
paths=$(grep -rlx "$name" ../../../transcripts/*/video_list.txt)

# Check if the file name was found.
if [ -z "$paths" ]; then
    echo "No file found with name $name."
    exit 2
fi

# Check if more than one path was found.
path_count=$(echo "$paths" | wc -l)
if [ "$path_count" -gt 1 ]; then
    echo "Error: More than one file found with name $name."
    exit 3
fi

# Output the directory name that contains the file name.
dir_path=$(dirname "$paths")
dir_name=$(basename "$dir_path")
echo "$dir_name"

exit 0
