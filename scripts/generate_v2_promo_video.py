#!/usr/bin/env python3
import os
import math
import wave
import struct
import subprocess
import shutil
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageEnhance

# --- CONFIGURATION ---
WIDTH = 1920
HEIGHT = 1080
FPS = 30
DURATION_SEC = 20
TOTAL_FRAMES = FPS * DURATION_SEC # 600 frames

OUT_DIR = "/tmp"
TEMP_FRAMES_DIR = "/tmp/culpeo_v2_video_frames"
AUDIO_PATH = "/tmp/v2_promo_audio.wav"
OUTPUT_MP4 = os.path.join(OUT_DIR, "culpeo_v2_promo_video.mp4")

HERO_IMAGE_PATH = "/home/david/Dokumente/culpeo-studio/assets/promo-v2.0.0-option1.jpg"

# Colors
COLOR_BG_DARK = (13, 13, 14)         # #0D0D0E
COLOR_BG_CARD = (27, 27, 28)         # #1B1B1C
COLOR_CARD_BORDER = (45, 50, 70)    # #2D3246
COLOR_RUST = (193, 68, 14)           # #C1440E (Culpeo Rust)
COLOR_EMBER = (242, 118, 46)        # #F2762E (Ember Orange)
COLOR_WHITE = (250, 247, 242)       # #FAF7F2 (Bone White)
COLOR_GRAY = (140, 148, 165)        # #8C94A5
COLOR_SAND = (232, 220, 200)        # #E8DCC8 (Andes Sand)
COLOR_CYAN = (90, 200, 250)         # #5AC8FA
COLOR_GREEN = (52, 199, 89)         # #34C759

# Fonts
FONT_TITLE_PATH = "/usr/share/fonts/truetype/dejavu/DejaVuSansCondensed-Bold.ttf"
FONT_BODY_PATH = "/usr/share/fonts/truetype/dejavu/DejaVuSansCondensed.ttf"
FONT_MONO_PATH = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf"

def get_font(path, size):
    try:
        return ImageFont.truetype(path, size)
    except Exception:
        return ImageFont.load_default()

font_hero = get_font(FONT_TITLE_PATH, 80)
font_title = get_font(FONT_TITLE_PATH, 54)
font_subtitle = get_font(FONT_BODY_PATH, 32)
font_card_title = get_font(FONT_TITLE_PATH, 26)
font_mono = get_font(FONT_MONO_PATH, 22)
font_small = get_font(FONT_BODY_PATH, 20)

# Load Hero Image
hero_img = None
if os.path.exists(HERO_IMAGE_PATH):
    try:
        hero_img = Image.open(HERO_IMAGE_PATH).convert("RGBA")
        hero_img = hero_img.resize((WIDTH, HEIGHT), Image.Resampling.LANCZOS)
    except Exception as e:
        print(f"Error loading hero image: {e}")

def create_audio():
    print("Synthesizing audio track for Version 2.0.0 promo...")
    os.makedirs(os.path.dirname(AUDIO_PATH), exist_ok=True)
    sample_rate = 44100
    num_samples = sample_rate * DURATION_SEC
    wav_file = wave.open(AUDIO_PATH, 'w')
    wav_file.setnchannels(2) # Stereo
    wav_file.setsampwidth(2) # 16-bit
    wav_file.setframerate(sample_rate)

    raw_data = bytearray()
    
    for i in range(num_samples):
        t = i / sample_rate
        
        # Sub Bass 55Hz pulse with drop at 4s
        bass_freq = 55.0 if t < 4.0 else (65.41 if (int(t * 2) % 4 != 3) else 87.31)
        bass_amp = 0.15 if t < 4.0 else 0.35
        bass = math.sin(2 * math.pi * bass_freq * t) * bass_amp
        
        # Arpeggio (C minor / Eb major synth lead)
        arp_notes = [261.63, 311.13, 392.00, 523.25, 622.25]
        note_idx = int(t * 12) % len(arp_notes)
        note_freq = arp_notes[note_idx]
        note_env = math.exp(-8 * ((t * 12) % 1.0))
        arp = math.sin(2 * math.pi * note_freq * t) * note_env * 0.18
        
        # Beat / Kick drum on beats (starts at 4s)
        kick = 0
        if t >= 4.0:
            kick_t = (t * 2) % 1.0
            kick_env = math.exp(-15 * kick_t)
            kick_freq = 150 * math.exp(-30 * kick_t)
            kick = math.sin(2 * math.pi * kick_freq * kick_t) * kick_env * 0.4
            
        # Hi-Hat
        hat_env = math.exp(-30 * ((t * 4) % 1.0))
        hat_noise = (math.sin(t * 15432.1) * 0.5 + math.sin(t * 9876.5) * 0.5) * hat_env * 0.07

        # Risers at transitions (4s, 10s, 15s)
        riser = 0
        for transition in [4.0, 10.0, 15.0]:
            if transition - 1.2 <= t < transition:
                dt = (t - (transition - 1.2)) / 1.2
                sweep_freq = 150 + dt * 1500
                riser += math.sin(2 * math.pi * sweep_freq * t) * dt * 0.25

        sample_val = bass + arp + kick + hat_noise + riser
        sample_val = max(-0.95, min(0.95, sample_val))
        
        packed_val = int(sample_val * 32767)
        raw_data.extend(struct.pack('<h', packed_val))
        raw_data.extend(struct.pack('<h', packed_val))

    wav_file.writeframes(raw_data)
    wav_file.close()
    print("Audio track generated!")

def draw_particles(draw, frame_num, speed=1.0):
    for p in range(40):
        px = int((p * 173 + frame_num * (1.5 + p % 4) * speed) % WIDTH)
        py = int((p * 293 - frame_num * (1.0 + (p % 3)) * speed) % HEIGHT)
        radius = 2 + (p % 4)
        alpha = int(100 + 155 * math.sin(frame_num * 0.1 + p))
        draw.ellipse([px-radius, py-radius, px+radius, py+radius], fill=(COLOR_EMBER[0], COLOR_EMBER[1], COLOR_EMBER[2]))

def render_frame(frame_num):
    t = frame_num / FPS
    
    # Create base background
    if hero_img is not None:
        # Smooth zoom / pan on hero image
        zoom_factor = 1.0 + 0.05 * math.sin(t * 0.3)
        w_crop = int(WIDTH / zoom_factor)
        h_crop = int(HEIGHT / zoom_factor)
        x_off = int((WIDTH - w_crop) / 2 + 15 * math.cos(t * 0.2))
        y_off = int((HEIGHT - h_crop) / 2 + 10 * math.sin(t * 0.2))
        
        cropped = hero_img.crop((x_off, y_off, x_off + w_crop, y_off + h_crop))
        frame = cropped.resize((WIDTH, HEIGHT), Image.Resampling.LANCZOS)
    else:
        frame = Image.new("RGBA", (WIDTH, HEIGHT), COLOR_BG_DARK + (255,))
        
    draw = ImageDraw.Draw(frame)
    draw_particles(draw, frame_num)

    # Vignette & Dark Overlay for text contrast
    overlay = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    odraw = ImageDraw.Draw(overlay)
    
    # SCENE CONTROL
    if t < 4.0:
        # Scene 1: Teaser Intro (0s - 4s)
        progress = t / 4.0
        alpha = min(1.0, progress * 2.5) if progress < 0.8 else max(0.0, (1.0 - progress) * 5.0)
        
        odraw.rectangle([0, 0, WIDTH, HEIGHT], fill=(13, 13, 14, int(180 * alpha)))
        frame = Image.alpha_composite(frame, overlay)
        draw = ImageDraw.Draw(frame)
        
        # Countdown / Teaser banner
        draw.rectangle([WIDTH//2 - 250, 180, WIDTH//2 + 250, 230], fill=COLOR_BG_CARD, outline=COLOR_RUST, width=2)
        draw.text((WIDTH//2, 205), "🔥 MORGEN LIVE · LAUNCHING TOMORROW", fill=COLOR_EMBER, font=font_small, anchor="mm")
        
        draw.text((WIDTH//2, 360), "Culpeo Studio", fill=COLOR_WHITE, font=font_hero, anchor="mm")
        draw.text((WIDTH//2, 460), "DAS GRÖSSTE UPDATE JEMALS", fill=COLOR_SAND, font=font_title, anchor="mm")
        
        # Glow pulse line
        line_w = int(600 * min(1.0, progress * 2.0))
        draw.line([(WIDTH//2 - line_w//2, 530), (WIDTH//2 + line_w//2, 530)], fill=COLOR_EMBER, width=5)
        
    elif t < 10.0:
        # Scene 2: Massive 2.0.0 Reveal (4s - 10s)
        progress = (t - 4.0) / 6.0
        
        odraw.rectangle([0, 0, WIDTH, HEIGHT], fill=(0, 0, 0, 80))
        frame = Image.alpha_composite(frame, overlay)
        draw = ImageDraw.Draw(frame)
        
        # Top Badge
        badge_y = 120
        draw.rectangle([WIDTH//2 - 220, badge_y, WIDTH//2 + 220, badge_y + 44], fill=COLOR_RUST, outline=COLOR_EMBER, width=2)
        draw.text((WIDTH//2, badge_y + 22), "THE BIGGEST UPDATE EVER", fill=COLOR_WHITE, font=font_card_title, anchor="mm")
        
        # Big Announcement Banner
        title_scale = 1.0 + 0.02 * math.sin(t * 3.0)
        draw.text((WIDTH//2, 280), "VERSION 2.0.0", fill=COLOR_EMBER, font=font_hero, anchor="mm")
        draw.text((WIDTH//2, 380), "Hardware-Aware · Local LLMs · Swarm Agents", fill=COLOR_WHITE, font=font_subtitle, anchor="mm")
        
        # Feature highlight pills
        pills = ["⚡ Hardware-Engine 2.0", "🤖 Multi-Agent Scouts", "🗂️ SQLite FTS5 Memory", "🚀 100% Local Privacy"]
        pill_w = 360
        start_x = WIDTH//2 - (2 * pill_w + 30) // 2
        
        for idx, pill_text in enumerate(pills):
            row = idx // 2
            col = idx % 2
            px = start_x + col * (pill_w + 30)
            py = 480 + row * 70
            
            p_alpha = max(0.0, min(1.0, (progress - idx*0.05) * 4.0))
            if p_alpha > 0:
                draw.rectangle([px, py, px + pill_w, py + 55], fill=COLOR_BG_CARD, outline=COLOR_CARD_BORDER, width=2)
                draw.rectangle([px, py, px + 8, py + 55], fill=COLOR_RUST)
                draw.text((px + pill_w//2 + 4, py + 27), pill_text, fill=COLOR_WHITE, font=font_card_title, anchor="mm")
                
    elif t < 15.0:
        # Scene 3: Deep Feature Highlights (10s - 15s)
        progress = (t - 10.0) / 5.0
        
        odraw.rectangle([0, 0, WIDTH, HEIGHT], fill=(13, 13, 14, 140))
        frame = Image.alpha_composite(frame, overlay)
        draw = ImageDraw.Draw(frame)
        
        draw.text((WIDTH//2, 120), "WAS IST NEU IN VERSION 2.0.0?", fill=COLOR_EMBER, font=font_title, anchor="mm")
        
        # 3 Feature Cards
        cards = [
            ("🧠 Hardware Engine 2.0", "Erkennt RAM & VRAM automatisch.\nWählt das optimale Modell & Kontext."),
            ("🤖 Multi-Agent Swarms", "Assistenten mit eigenen Prompts,\nTools, Memory & Diff-Vorschau."),
            ("⚡ High-Speed Vector Memory", "SQLite FTS5 + Vektor-Suche.\nRecall über Sessions hinweg.")
        ]
        
        card_w = 520
        card_h = 240
        start_x = WIDTH//2 - (len(cards) * card_w + (len(cards)-1)*40) // 2
        card_y = 240
        
        for idx, (ctitle, cdesc) in enumerate(cards):
            cx = start_x + idx * (card_w + 40)
            c_alpha = max(0.0, min(1.0, (progress - idx*0.12) * 4.0))
            if c_alpha > 0:
                cy = card_y + int((1.0 - c_alpha) * 40)
                draw.rectangle([cx, cy, cx + card_w, cy + card_h], fill=COLOR_BG_CARD, outline=COLOR_RUST, width=2)
                draw.rectangle([cx, cy, cx + card_w, cy + 50], fill=(35, 40, 58))
                draw.text((cx + 20, cy + 25), ctitle, fill=COLOR_EMBER, font=font_card_title, anchor="lm")
                
                # Split description lines
                lines = cdesc.split("\n")
                for l_idx, line in enumerate(lines):
                    draw.text((cx + 20, cy + 90 + l_idx * 35), line, fill=COLOR_WHITE, font=font_small, anchor="lm")

        # Call to Action bar below
        draw.rectangle([WIDTH//2 - 300, 580, WIDTH//2 + 300, 640], fill=COLOR_RUST)
        draw.text((WIDTH//2, 610), "⚡ 100% LOKAL & KOSTENLOS", fill=COLOR_WHITE, font=font_card_title, anchor="mm")
        
    else:
        # Scene 4: Outro & Download CTA (15s - 20s)
        progress = (t - 15.0) / 5.0
        
        odraw.rectangle([0, 0, WIDTH, HEIGHT], fill=(13, 13, 14, 210))
        frame = Image.alpha_composite(frame, overlay)
        draw = ImageDraw.Draw(frame)
        
        draw.rectangle([WIDTH//2 - 200, 160, WIDTH//2 + 200, 210], fill=COLOR_BG_CARD, outline=COLOR_EMBER, width=2)
        draw.text((WIDTH//2, 185), "RELEASE MORGEN!", fill=COLOR_EMBER, font=font_card_title, anchor="mm")
        
        draw.text((WIDTH//2, 300), "Culpeo Studio v2.0.0", fill=COLOR_WHITE, font=font_hero, anchor="mm")
        draw.text((WIDTH//2, 400), "Jetzt auf GitHub herunterladen", fill=COLOR_SAND, font=font_subtitle, anchor="mm")
        
        # Link box
        draw.rectangle([WIDTH//2 - 400, 480, WIDTH//2 + 400, 560], fill=COLOR_BG_CARD, outline=COLOR_RUST, width=3)
        draw.text((WIDTH//2, 520), "github.com/culpeohq/CulpeoStudio", fill=COLOR_EMBER, font=font_card_title, anchor="mm")
        
        draw.text((WIDTH//2, 630), "Linux · Windows · macOS", fill=COLOR_CYAN, font=font_small, anchor="mm")

    return frame.convert("RGB")

def main():
    print("Generating frames...")
    os.makedirs(TEMP_FRAMES_DIR, exist_ok=True)
    
    for f in range(TOTAL_FRAMES):
        if f % 30 == 0:
            print(f"Rendering frame {f}/{TOTAL_FRAMES} ({(f/TOTAL_FRAMES)*100:.1f}%)...")
        frame_img = render_frame(f)
        frame_path = os.path.join(TEMP_FRAMES_DIR, f"frame_{f:04d}.png")
        frame_img.save(frame_path, quality=95)
        
    create_audio()
    
    print("Encoding MP4 video with FFmpeg...")
    ffmpeg_cmd = [
        "ffmpeg", "-y",
        "-framerate", str(FPS),
        "-i", os.path.join(TEMP_FRAMES_DIR, "frame_%04d.png"),
        "-i", AUDIO_PATH,
        "-c:v", "libx264",
        "-preset", "medium",
        "-crf", "18",
        "-pix_fmt", "yuv420p",
        "-c:a", "aac",
        "-b:a", "192k",
        "-shortest",
        OUTPUT_MP4
    ]
    
    res = subprocess.run(ffmpeg_cmd, capture_output=True, text=True)
    if res.returncode == 0:
        print(f"\n✅ VIDEO SUCCESS! Saved to: {OUTPUT_MP4}")
    else:
        print(f"\n❌ FFmpeg Error: {res.stderr}")
        
    # Cleanup temp frames
    shutil.rmtree(TEMP_FRAMES_DIR, ignore_errors=True)

if __name__ == "__main__":
    main()
