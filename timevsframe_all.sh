#!/bin/bash

# Define root path
root="/kriosdata/tannerjj/tannerjj_20250318_SmPutA_Quant/Images-Disc1"
output="fractions_all_grid_squares.csv"

# Header for the CSV
echo "GridSquare,Filename,Timestamp,FrameCount" > "$output"

# Loop through all matching TIFF files
find "$root" -type f -name "*_Fractions.tiff" | while read file; do
    # Extract GridSquare from path
    gridsquare=$(echo "$file" | grep -oP "GridSquare_\K[0-9]+")
    
    # Extract filename
    filename=$(basename "$file")
    
    # Extract timestamp from filename (format: YYYYMMDD_HHMMSS)
    rawts=$(echo "$filename" | grep -oP '[0-9]{8}_[0-9]{6}')
    
    # Convert to readable format
    if [[ -n "$rawts" ]]; then
        timestamp=$(date -d "${rawts:0:8} ${rawts:9:2}:${rawts:11:2}:${rawts:13:2}" "+%Y-%m-%d %H:%M:%S")
    else
        # Fallback: use file modification time
        timestamp=$(stat -c "%y" "$file" | cut -d'.' -f1)
    fi

    # Get frame count using e2iminfo.py
    frames=$(e2iminfo.py "$file" 2>/dev/null | grep "images in TIFF format" | awk '{print $2}')

    # Write to CSV if valid
    if [[ -n "$frames" && -n "$timestamp" ]]; then
        echo "$gridsquare,$filename,$timestamp,$frames" >> "$output"
        echo "✅ $filename — $frames frames at $timestamp"
    else
        echo "❌ Skipped: $filename (missing frame count or timestamp)"
    fi
done

# Final sorting and saving
tmp="fractions_sorted.csv"
(head -n 1 "$output" && tail -n +2 "$output" | sort -t, -k3,3 -k2,2) > "$tmp"
mv "$tmp" "$output"

echo ""
echo "✅ Done! Output saved to: $output"

