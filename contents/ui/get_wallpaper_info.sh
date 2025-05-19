#!/bin/bash

# Script to efficiently get all wallpaper information in a single execution
# Usage: ./get_wallpaper_info.sh

# Get the current wallpaper path
WALLPAPER=$(qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.wallpaper 0 | awk '/^Image:/{sub(/^Image: /,""); print; exit}')

if [ -n "$WALLPAPER" ]; then
    # Strip file:// prefix if present
    WALLPAPER=${WALLPAPER#file://}
    
    # Make sure the path exists
    if [ -f "$WALLPAPER" ]; then
        # Print all the required information at once
        echo "Path: $WALLPAPER"
        echo "Filesize: $(du -h "$WALLPAPER" | cut -f1)"
        
        # Get image dimensions
        if command -v identify &>/dev/null; then 
            echo "Image dimensions: $(identify -format "%wx%h" "$WALLPAPER" 2>/dev/null)"
        else 
            echo "Image dimensions: Unknown"
        fi
        
        echo "Date created: $(stat -c %y "$WALLPAPER" | cut -d. -f1)"
        echo "Filename: $(basename "$WALLPAPER")"
        
        # Get title from metadata - call out to get_title.sh script in the same directory
        DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
        echo "Title metadata: $(bash "$DIR/get_title.sh" "$WALLPAPER")"
    else
        echo "Path: $WALLPAPER"
        echo "Error: File not found"
    fi
else
    echo "Path: No wallpaper path found"
fi