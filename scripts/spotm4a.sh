#!/bin/bash
# path/filename: spotm4a.sh
# Description: Script to download music using spotdl, organize tracks by album, and move tracks to their respective album directories if more than one track exists for an album.

# Ensure the correct number of arguments are passed
if [[ $# -ne 2 ]]; then
    echo "Usage: $0 output_folder link"
    exit 1
fi

output_folder="$1"
link="$2"

# Download using spotdl
spotdl --format m4a --output "$output_folder" "$link"

# Check if spotdl succeeded
if [[ $? -ne 0 ]]; then
    echo "Error: spotdl failed to download."
    exit 2
fi

# Temporarily store album names and corresponding file counts
declare -A album_count

# Populate album_count with album names and file counts
while IFS= read -r file; do
    album=$(ffprobe -v error -show_entries format_tags=album -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null)
    # Check if ffprobe succeeded
    if [[ $? -ne 0 ]]; then
        echo "Error: ffprobe failed to read file tags for $file."
        continue # Skip this file and continue with the next
    fi
    ((album_count["$album"]++))
done < <(find "$output_folder" -type f -name "*.m4a")

# Move files to album folders only if there's more than one file for that album
for file in "$output_folder"/*.m4a; do
    if [[ -f "$file" ]]; then
        album=$(ffprobe -v error -show_entries format_tags=album -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null)
        if [[ ${album_count["$album"]} -gt 1 ]]; then
            mkdir -p "$output_folder/$album" 2>/dev/null
            if [[ $? -ne 0 ]]; then
                echo "Error: Failed to create directory for $album."
                continue # Skip moving this file
            fi
            mv "$file" "$output_folder/$album/"
            if [[ $? -ne 0 ]]; then
                echo "Error: Failed to move $file to $output_folder/$album."
            fi
        fi
    fi
done