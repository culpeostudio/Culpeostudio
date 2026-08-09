#!/usr/bin/env python3
import os
import subprocess
from PIL import Image

SPRITESHEET_PATH = "/home/david/.gemini/antigravity/brain/727c4d10-669d-4dca-9f3e-5e5d8eb87668/culpeo_fox_walk_spritesheet_1786218260095.jpg"
OUT_GIF = "/home/david/Dokumente/culpeo-studio/assets/culpeo_fox_walk.gif"
OUT_MP4 = "/home/david/Dokumente/culpeo-studio/assets/culpeo_fox_walk.mp4"
TEMP_DIR = "/tmp/fox_walk_frames"

def extract_and_animate():
    if not os.path.exists(SPRITESHEET_PATH):
        print(f"Spritesheet not found at {SPRITESHEET_PATH}")
        return
        
    img = Image.open(SPRITESHEET_PATH)
    width, height = img.size
    
    # 2 rows x 3 columns of sprites
    cols = 3
    rows = 2
    frame_w = width // cols
    frame_h = height // rows
    
    frames = []
    os.makedirs(TEMP_DIR, exist_ok=True)
    
    frame_num = 0
    for r in range(rows):
        for c in range(cols):
            box = (c * frame_w, r * frame_h, (c + 1) * frame_w, (r + 1) * frame_h)
            frame = img.crop(box)
            frames.append(frame)
            frame.save(os.path.join(TEMP_DIR, f"frame_{frame_num:02d}.png"))
            frame_num += 1
            
    # Save animated GIF (smooth loop)
    # Loop sequence: 0 -> 1 -> 2 -> 3 -> 4 -> 5 -> 4 -> 3 -> 2 -> 1
    walk_cycle = [frames[0], frames[1], frames[2], frames[3], frames[4], frames[1]]
    walk_cycle[0].save(
        OUT_GIF,
        save_all=True,
        append_images=walk_cycle[1:],
        duration=120, # 120ms per frame
        loop=0
    )
    print(f"✅ GIF saved to {OUT_GIF}")
    
    # Render MP4 video loop with FFmpeg
    ffmpeg_cmd = [
        "ffmpeg", "-y",
        "-ignore_loop", "0",
        "-i", OUT_GIF,
        "-c:v", "libx264",
        "-t", "6",
        "-pix_fmt", "yuv420p",
        OUT_MP4
    ]
    res = subprocess.run(ffmpeg_cmd, capture_output=True, text=True)
    if res.returncode == 0:
        print(f"✅ MP4 saved to {OUT_MP4}")
    else:
        print(f"FFmpeg error: {res.stderr}")

if __name__ == "__main__":
    extract_and_animate()
