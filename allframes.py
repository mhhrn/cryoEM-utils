import os
import csv
import re
from datetime import datetime
from pathlib import Path
import subprocess
from tqdm import tqdm


root = "/kriosdata/tannerjj"
output = "fractions_all_grid_squares.csv"

with open(output, 'w', newline='') as csvfile:
    writer = csv.writer(csvfile)
    writer.writerow(["GridSquare", "Filename", "Timestamp", "FrameCount"])

    all_files = list(Path(root).rglob("*_Fractions.tiff"))
    for filepath in tqdm(all_files, desc="Processing TIFFs", unit="file"):
        filename = filepath.name
        gridsquare = re.search(r'GridSquare_(\d+)', str(filepath))
        rawts = re.search(r'(\d{8}_\d{6})', filename)
        
        # Extract timestamp
        if rawts:
            ts = datetime.strptime(rawts.group(1), "%Y%m%d_%H%M%S")
        else:
            ts = datetime.fromtimestamp(filepath.stat().st_mtime)

        # Frame count using e2iminfo.py
        try:
            output = subprocess.check_output(["e2iminfo.py", str(filepath)], stderr=subprocess.DEVNULL)
            output_text = output.decode()
            print(f"INFO: {output_text}")  # Debug print
            match = re.search(r'(\d+) images in TIFF format', output_text)
            frames = match.group(1) if match else None
        except Exception as e:
            print(f"ERROR running e2iminfo.py: {e}")
            frames = None

        if gridsquare and frames:
            writer.writerow([gridsquare.group(1), filename, ts, frames])
            print(f"✅ {filename} — {frames} frames at {ts}")
        else:
            print(f"❌ Skipped: {filename}")

