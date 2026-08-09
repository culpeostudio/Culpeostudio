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
DURATION_SEC = 45
TOTAL_FRAMES = FPS * DURATION_SEC # 1350 frames

OUT_DIR = "/tmp"
TEMP_FRAMES_DIR = "/tmp/culpeostudio_video_frames"
AUDIO_PATH = "/tmp/promo_audio.wav"
OUTPUT_MP4 = os.path.join(OUT_DIR, "culpeostudio_promo.mp4")

# Color Palette (Culpeo Rust & Ember Orange theme)
COLOR_BG_DARK = (13, 13, 14)         # #0D0D0E
COLOR_BG_CARD = (27, 27, 28)         # #1B1B1C
COLOR_CARD_BORDER = (45, 50, 70)    # #2D3246
COLOR_GOLD = (193, 68, 14)          # #C1440E (Culpeo Rust)
COLOR_GOLD_BRIGHT = (242, 118, 46)  # #F2762E (Ember Orange)
COLOR_WHITE = (250, 247, 242)       # #FAF7F2 (Bone White)
COLOR_GRAY = (140, 148, 165)         # #8C94A5
COLOR_ACCENT = (232, 220, 200)      # #E8DCC8 (Andes Sand)
COLOR_CYAN = (90, 200, 250)          # #5AC8FA
COLOR_GREEN = (52, 199, 89)          # #34C759
COLOR_AMBER = (255, 149, 0)         # #FF9500

# Fonts
FONT_TITLE_PATH = "/usr/share/fonts/truetype/dejavu/DejaVuSansCondensed-Bold.ttf"
FONT_BODY_PATH = "/usr/share/fonts/truetype/dejavu/DejaVuSansCondensed.ttf"
FONT_MONO_PATH = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf"

def get_font(path, size):
    try:
        return ImageFont.truetype(path, size)
    except Exception:
        return ImageFont.load_default()

font_hero = get_font(FONT_TITLE_PATH, 72)
font_title = get_font(FONT_TITLE_PATH, 48)
font_subtitle = get_font(FONT_BODY_PATH, 28)
font_card_title = get_font(FONT_TITLE_PATH, 24)
font_mono = get_font(FONT_MONO_PATH, 20)
font_small = get_font(FONT_BODY_PATH, 18)

# Load Screenshots
screenshots = {}
def load_img(name, path):
    if os.path.exists(path):
        try:
            return Image.open(path).convert("RGBA")
        except Exception as e:
            print(f"Error loading {name}: {e}")
    return None

screenshots["engine"] = load_img("engine", "/home/david/Dokumente/culpeostudio/assets/screenshots/engine.png")
screenshots["marketplace"] = load_img("marketplace", "/home/david/Dokumente/culpeostudio/assets/screenshots/marketplace.png")
screenshots["news"] = load_img("news", "/home/david/Dokumente/culpeostudio/assets/screenshots/news.png")
screenshots["hero"] = load_img("hero", "/home/david/Dokumente/culpeostudio/assets/readme-hero.png")


def create_audio():
    print("Synthesizing audio track...")
    os.makedirs(os.path.dirname(AUDIO_PATH), exist_ok=True)
    sample_rate = 44100
    num_samples = sample_rate * DURATION_SEC
    wav_file = wave.open(AUDIO_PATH, 'w')
    wav_file.setnchannels(2) # Stereo
    wav_file.setsampwidth(2) # 16-bit
    wav_file.setframerate(sample_rate)

    raw_data = bytearray()
    
    # Sound synth math
    for i in range(num_samples):
        t = i / sample_rate
        
        # Sub Bass 55Hz / 110Hz tone pulse
        bass_freq = 55.0 if (int(t * 2) % 4 != 3) else 110.0
        bass = math.sin(2 * math.pi * bass_freq * t) * 0.25
        
        # Arpeggio (C minor: C4=261.63, Eb4=311.13, G4=392.00, Bb4=466.16)
        arp_notes = [261.63, 311.13, 392.00, 466.16, 523.25]
        note_idx = int(t * 8) % len(arp_notes)
        note_freq = arp_notes[note_idx]
        note_env = math.exp(-6 * ( (t * 8) % 1.0 ))
        arp = math.sin(2 * math.pi * note_freq * t) * note_env * 0.15
        
        # Hi-Hat pulse every 0.25s
        hat_env = math.exp(-25 * ( (t * 4) % 1.0 ))
        hat_noise = (math.sin(t * 12345.678) * 0.5 + math.sin(t * 8765.432) * 0.5) * hat_env * 0.08

        # Scene riser sweeps at transition points (7, 16, 25, 34)
        riser = 0
        for transition in [7.0, 16.0, 25.0, 34.0]:
            if transition - 1.5 <= t < transition:
                dt = (t - (transition - 1.5)) / 1.5
                sweep_freq = 200 + dt * 1200
                riser += math.sin(2 * math.pi * sweep_freq * t) * dt * 0.2

        sample_val = bass + arp + hat_noise + riser
        # Clamp sample
        sample_val = max(-0.95, min(0.95, sample_val))
        
        packed_val = int(sample_val * 32767)
        # Stereo (left & right)
        raw_data.extend(struct.pack('<h', packed_val))
        raw_data.extend(struct.pack('<h', packed_val))

    wav_file.writeframes(raw_data)
    wav_file.close()
    print("Audio track created successfully!")


def draw_background(draw, frame_num):
    # Base dark gradient background
    for y in range(0, HEIGHT, 4):
        ratio = y / HEIGHT
        r = int(COLOR_BG_DARK[0] + ratio * 8)
        g = int(COLOR_BG_DARK[1] + ratio * 10)
        b = int(COLOR_BG_DARK[2] + ratio * 15)
        draw.rectangle([0, y, WIDTH, y+4], fill=(r, g, b))

    # Grid background lines
    grid_size = 80
    offset_x = (frame_num * 1.5) % grid_size
    offset_y = (frame_num * 1.0) % grid_size
    
    grid_color = (25, 30, 45, 120)
    for x in range(0, WIDTH + grid_size, grid_size):
        gx = int(x - offset_x)
        draw.line([(gx, 0), (gx, HEIGHT)], fill=grid_color, width=1)
        
    for y in range(0, HEIGHT + grid_size, grid_size):
        gy = int(y - offset_y)
        draw.line([(0, gy), (WIDTH, gy)], fill=grid_color, width=1)

    # Floating tech ambient particles
    for p in range(25):
        px = int((p * 137 + frame_num * (1 + p % 3)) % WIDTH)
        py = int((p * 263 - frame_num * (0.8 + (p % 2))) % HEIGHT)
        radius = 2 + (p % 3)
        draw.ellipse([px-radius, py-radius, px+radius, py+radius], fill=(COLOR_GOLD[0], COLOR_GOLD[1], COLOR_GOLD[2]))


def draw_framed_image(base_img, target_img, box, border_color=COLOR_GOLD):
    # box = (x, y, w, h)
    x, y, w, h = box
    if target_img is None:
        return
    
    # Scale image maintaining aspect ratio
    img_w, img_h = target_img.size
    scale = min(w / img_w, h / img_h)
    new_w = int(img_w * scale)
    new_h = int(img_h * scale)
    
    resized = target_img.resize((new_w, new_h), Image.Resampling.LANCZOS)
    
    offset_x = x + (w - new_w) // 2
    offset_y = y + (h - new_h) // 2
    
    draw = ImageDraw.Draw(base_img)
    
    # Draw Outer Glow/Card background
    pad = 8
    card_rect = [offset_x - pad, offset_y - pad, offset_x + new_w + pad, offset_y + new_h + pad]
    draw.rectangle(card_rect, fill=COLOR_BG_CARD, outline=border_color, width=2)
    
    # Paste screenshot
    base_img.paste(resized, (offset_x, offset_y), resized if resized.mode == 'RGBA' else None)


def render_scene_1(frame_num, progress):
    # Intro scene: 0s - 7s
    img = Image.new("RGB", (WIDTH, HEIGHT), COLOR_BG_DARK)
    draw = ImageDraw.Draw(img)
    draw_background(draw, frame_num)

    alpha = min(1.0, progress * 4.0) if progress < 0.2 else (1.0 if progress < 0.85 else max(0.0, (1.0 - progress) * 6.6))
    
    # Title badge top
    badge_y = int(220 - (1.0 - alpha) * 40)
    draw.rectangle([WIDTH//2 - 160, badge_y, WIDTH//2 + 160, badge_y + 36], fill=COLOR_BG_CARD, outline=COLOR_GOLD, width=1)
    draw.text((WIDTH//2, badge_y + 18), "LOCAL-FIRST LLM STUDIO", fill=COLOR_GOLD, font=font_small, anchor="mm")

    # Main Hero Title
    title_y = int(320 - (1.0 - alpha) * 30)
    draw.text((WIDTH//2, title_y), "Culpeo Studio", fill=COLOR_WHITE, font=font_hero, anchor="mm")
    
    # Gold accent line below title
    line_w = int(400 * min(1.0, progress * 3.0))
    draw.line([(WIDTH//2 - line_w//2, title_y + 55), (WIDTH//2 + line_w//2, title_y + 55)], fill=COLOR_GOLD, width=4)

    # Subtitle
    sub_y = title_y + 110
    draw.text((WIDTH//2, sub_y), "Das hardware-bewusste Desktop-Studio für Sprachmodelle", fill=COLOR_GRAY, font=font_subtitle, anchor="mm")

    # 3 Pill Badges
    pills = ["⚡ Hardware-Aware Engine", "🔒 100% Privacy & Local Storage", "🌐 AGPL-3.0 Open Source"]
    pill_w = 340
    start_x = WIDTH//2 - (len(pills) * pill_w + (len(pills)-1)*30) // 2
    pill_y = sub_y + 130
    
    for idx, pill_text in enumerate(pills):
        px = start_x + idx * (pill_w + 30)
        p_alpha = max(0.0, min(1.0, (progress - 0.15 - idx*0.08) * 5.0))
        if p_alpha > 0:
            py = pill_y + int((1.0 - p_alpha) * 30)
            draw.rectangle([px, py, px + pill_w, py + 60], fill=COLOR_BG_CARD, outline=COLOR_CARD_BORDER, width=2)
            draw.rectangle([px, py, px + 6, py + 60], fill=COLOR_GOLD)
            draw.text((px + pill_w//2 + 3, py + 30), pill_text, fill=COLOR_WHITE, font=font_small, anchor="mm")

    # Bottom platform indicator
    plat_y = pill_y + 160
    draw.text((WIDTH//2, plat_y), "Verfügbar für Linux · Windows · macOS", fill=COLOR_CYAN, font=font_small, anchor="mm")

    return img


def render_scene_2(frame_num, progress):
    # Hardware-Aware Engine scene: 7s - 16s
    img = Image.new("RGB", (WIDTH, HEIGHT), COLOR_BG_DARK)
    draw = ImageDraw.Draw(img)
    draw_background(draw, frame_num)

    # Header
    draw.text((100, 80), "01 // HARDWARE-AWARE ENGINE", fill=COLOR_GOLD, font=font_small)
    draw.text((100, 120), "Automatische Hardware-Erkennung & Sichere Kontext-Planung", fill=COLOR_WHITE, font=font_title)

    # Left HUD panel (Telemetry box)
    hud_box = [100, 220, 680, 880]
    draw.rectangle(hud_box, fill=COLOR_BG_CARD, outline=COLOR_CARD_BORDER, width=2)
    # HUD title bar
    draw.rectangle([100, 220, 680, 270], fill=(35, 40, 58))
    draw.text((120, 245), "🧠 HARDWARE TELEMETRY & AUTO-PLANNER", fill=COLOR_GOLD, font=font_card_title, anchor="lm")

    # Telemetry rows
    y_pos = 300
    rows = [
        ("SYSTEM RAM:", "32.0 GB Detected", COLOR_WHITE),
        ("GPU VRAM:", "16.0 GB (RTX 4090)", COLOR_CYAN),
        ("DETECTED RUNTIME:", "llama.cpp (GGUF CUDA)", COLOR_GREEN),
        ("MODEL BINDING:", "Llama-3.1-8B-Instruct.Q4_K_M", COLOR_WHITE),
    ]
    
    for label, val, color in rows:
        draw.text((130, y_pos), label, fill=COLOR_GRAY, font=font_mono)
        draw.text((360, y_pos), val, fill=color, font=font_mono)
        y_pos += 45

    # Animated Fallback Simulation Box
    draw.rectangle([120, y_pos + 10, 660, y_pos + 210], fill=(20, 23, 35), outline=COLOR_GOLD, width=1)
    draw.text((140, y_pos + 35), "⚡ CONTEXT PLANNER DECISION:", fill=COLOR_GOLD, font=font_small)
    
    ctx_req = "Requested: 64,000 tokens"
    draw.text((140, y_pos + 70), ctx_req, fill=COLOR_GRAY, font=font_small)
    
    fb_step = min(1.0, max(0.0, (progress - 0.2) * 3.0))
    if fb_step < 0.5:
        status_txt = "⏳ Estimating VRAM allocation..."
        status_col = COLOR_AMBER
        bar_w = int(500 * (fb_step * 2))
    else:
        status_txt = "✓ Auto-Fallback: 32,000 tokens (SAFE FIT)"
        status_col = COLOR_GREEN
        bar_w = 260

    draw.rectangle([140, y_pos + 100, 140 + 500, y_pos + 120], fill=(40, 45, 60))
    draw.rectangle([140, y_pos + 100, 140 + bar_w, y_pos + 120], fill=status_col)
    draw.text((140, y_pos + 150), status_txt, fill=status_col, font=font_card_title)
    draw.text((140, y_pos + 185), "Keine Abstürze durch VRAM-Überlauf (OOM Protection)", fill=COLOR_GRAY, font=font_small)

    # Right side Screenshot
    draw_framed_image(img, screenshots.get("engine"), (720, 220, 1100, 660), border_color=COLOR_GOLD)

    # Bottom summary tag
    draw.rectangle([100, 920, WIDTH-100, 990], fill=COLOR_BG_CARD, outline=COLOR_GOLD, width=1)
    draw.text((WIDTH//2, 955), "Culpeo Studio berechnet RAM & VRAM vor dem Start. Schlägt die 1. Konfiguration fehl, greift der automatische Fallback.", fill=COLOR_WHITE, font=font_subtitle, anchor="mm")

    return img


def render_scene_3(frame_num, progress):
    # Marketplace scene: 16s - 25s
    img = Image.new("RGB", (WIDTH, HEIGHT), COLOR_BG_DARK)
    draw = ImageDraw.Draw(img)
    draw_background(draw, frame_num)

    # Header
    draw.text((100, 80), "02 // UNIFIED MARKETPLACE", fill=COLOR_GOLD, font=font_small)
    draw.text((100, 120), "Ein Katalog für Lokale Modelle & Cloud-APIs", fill=COLOR_WHITE, font=font_title)

    # Left side Screenshot
    draw_framed_image(img, screenshots.get("marketplace"), (100, 210, 1150, 680), border_color=COLOR_GOLD)

    # Right side feature cards
    card_x = 1290
    card_w = 530
    
    cards = [
        ("📁 Hugging Face GGUF", "Direkter Download von lokal ausführbaren Modellen mit Hardware-Fit Bewertung.", COLOR_CYAN),
        ("☁️ OpenRouter & Cloud APIs", "Nutze Cloud-Provider im selben Interface wenn zusätzliche Power benötigt wird.", COLOR_GOLD),
        ("📊 Hardware-Fit Indicator", "Sofortige Anzeige ob ein Modell auf deiner GPU flüssig läuft oder zu groß ist.", COLOR_GREEN),
        ("🔒 Sichere Key-Speicherung", "API-Keys bleiben lokal verschlüsselt und gehen nur an den jeweiligen Provider.", COLOR_WHITE),
    ]

    card_y = 210
    for idx, (ctitle, cdesc, ccol) in enumerate(cards):
        c_alpha = max(0.0, min(1.0, (progress - 0.1 - idx*0.12) * 4.0))
        if c_alpha > 0:
            cy = card_y + int((1.0 - c_alpha) * 30)
            draw.rectangle([card_x, cy, card_x + card_w, cy + 145], fill=COLOR_BG_CARD, outline=COLOR_CARD_BORDER, width=2)
            draw.rectangle([card_x, cy, card_x + 6, cy + 145], fill=ccol)
            draw.text((card_x + 25, cy + 30), ctitle, fill=ccol, font=font_card_title)
            draw.text((card_x + 25, cy + 70), cdesc, fill=COLOR_GRAY, font=font_small)
        card_y += 175

    # Bottom banner
    draw.rectangle([100, 920, WIDTH-100, 990], fill=COLOR_BG_CARD, outline=COLOR_GOLD, width=1)
    draw.text((WIDTH//2, 955), "Nahtloser Wechsel zwischen lokalen Quantisierungen und Cloud-Modellen in einer einzigen Oberfläche.", fill=COLOR_WHITE, font=font_subtitle, anchor="mm")

    return img


def render_scene_4(frame_num, progress):
    # Scouts & Memory scene: 25s - 34s
    img = Image.new("RGB", (WIDTH, HEIGHT), COLOR_BG_DARK)
    draw = ImageDraw.Draw(img)
    draw_background(draw, frame_num)

    # Header
    draw.text((100, 80), "03 // SCOUTS & LONG-TERM MEMORY", fill=COLOR_GOLD, font=font_small)
    draw.text((100, 120), "Maßgeschneiderte Assistenten mit Langzeitgedächtnis", fill=COLOR_WHITE, font=font_title)

    # Left Screenshot
    draw_framed_image(img, screenshots.get("news"), (100, 210, 1100, 660), border_color=COLOR_GOLD)

    # Right side highlights
    rx = 1240
    rw = 580
    
    highlights = [
        ("🤖 Scouts mit Werkzeugen", "Erstelle eigene Assistenten mit individuellen Prompts, Systemregeln & Trigger-Wörtern."),
        ("🗂️ SQLite FTS5 Vector Memory", "Erinnert sich über mehrere Sessions hinweg an projektspezifischen Kontext."),
        ("📈 Rich Visuals & LaTeX", "Direkte Darstellung von Diagrammen, Code-Snippets, Tabellen & Formeln im Chat."),
        ("🔍 Integrierte Web-Suche", "Durchsuche das Web via DuckDuckGo, Brave oder Wikipedia mit automatischer Zusammenfassung.")
    ]

    ry = 210
    for idx, (htitle, hdesc) in enumerate(highlights):
        h_alpha = max(0.0, min(1.0, (progress - 0.1 - idx*0.12) * 4.0))
        if h_alpha > 0:
            cur_y = ry + int((1.0 - h_alpha) * 25)
            draw.rectangle([rx, cur_y, rx + rw, cur_y + 140], fill=COLOR_BG_CARD, outline=COLOR_CARD_BORDER, width=2)
            draw.rectangle([rx, cur_y, rx + 6, cur_y + 140], fill=COLOR_GOLD)
            draw.text((rx + 25, cur_y + 30), htitle, fill=COLOR_WHITE, font=font_card_title)
            draw.text((rx + 25, cur_y + 70), hdesc, fill=COLOR_GRAY, font=font_small)
        ry += 165

    # Bottom summary tag
    draw.rectangle([100, 920, WIDTH-100, 990], fill=COLOR_BG_CARD, outline=COLOR_GOLD, width=1)
    draw.text((WIDTH//2, 955), "Behalte die volle Kontrolle über deinen Kontext, deine Bots und deine lokalen Projektdaten.", fill=COLOR_WHITE, font=font_subtitle, anchor="mm")

    return img


def render_scene_5(frame_num, progress):
    # Outro / CTA Scene: 34s - 45s
    img = Image.new("RGB", (WIDTH, HEIGHT), COLOR_BG_DARK)
    draw = ImageDraw.Draw(img)
    draw_background(draw, frame_num)

    # Top Tag
    draw.rectangle([WIDTH//2 - 200, 100, WIDTH//2 + 200, 140], fill=COLOR_BG_CARD, outline=COLOR_GOLD, width=1)
    draw.text((WIDTH//2, 120), "SCOUT STUDIO // READY FOR YOU", fill=COLOR_GOLD, font=font_small, anchor="mm")

    # Center Hero Screenshot Preview
    draw_framed_image(img, screenshots.get("hero"), (WIDTH//2 - 600, 170, 1200, 440), border_color=COLOR_GOLD)

    # Main Headline Below Screenshot
    draw.text((WIDTH//2, 650), "Bereit für dein lokales KI-Studio?", fill=COLOR_WHITE, font=font_hero, anchor="mm")
    draw.text((WIDTH//2, 730), "Starte heute mit Culpeo Studio — Schnell, sicher und 100% datenschutzkonform.", fill=COLOR_GRAY, font=font_subtitle, anchor="mm")

    # Pulsing CTA Button
    pulse = (1.0 + 0.08 * math.sin(frame_num * 0.2))
    btn_w = int(480 * pulse)
    btn_h = int(70 * pulse)
    btn_x = WIDTH//2 - btn_w//2
    btn_y = 800 - (btn_h - 70)//2

    draw.rectangle([btn_x, btn_y, btn_x + btn_w, btn_y + btn_h], fill=COLOR_GOLD, outline=COLOR_GOLD_BRIGHT, width=3)
    draw.text((WIDTH//2, btn_y + btn_h//2), "JETZT KOSTENLOS HERUNTERLADEN ➔", fill=(15, 17, 23), font=font_card_title, anchor="mm")

    # GitHub Repository link & badges
    draw.text((WIDTH//2, 920), "GitHub: github.com/culpeostudio/Culpeostudio", fill=COLOR_CYAN, font=font_card_title, anchor="mm")
    draw.text((WIDTH//2, 965), "Open Source unter AGPL-3.0 License · Linux · Windows · macOS", fill=COLOR_GRAY, font=font_small, anchor="mm")

    return img


def generate_frames():
    print(f"Generating {TOTAL_FRAMES} video frames at 1920x1080 resolution...")
    os.makedirs(TEMP_FRAMES_DIR, exist_ok=True)

    for i in range(TOTAL_FRAMES):
        time_sec = i / FPS
        
        if time_sec < 7.0:
            prog = time_sec / 7.0
            frame_img = render_scene_1(i, prog)
        elif time_sec < 16.0:
            prog = (time_sec - 7.0) / 9.0
            frame_img = render_scene_2(i, prog)
        elif time_sec < 25.0:
            prog = (time_sec - 16.0) / 9.0
            frame_img = render_scene_3(i, prog)
        elif time_sec < 34.0:
            prog = (time_sec - 25.0) / 9.0
            frame_img = render_scene_4(i, prog)
        else:
            prog = (time_sec - 34.0) / 11.0
            frame_img = render_scene_5(i, prog)

        out_frame_path = os.path.join(TEMP_FRAMES_DIR, f"frame_{i:04d}.png")
        frame_img.save(out_frame_path, format="PNG")
        
        if i % 150 == 0 or i == TOTAL_FRAMES - 1:
            print(f"Rendered frame {i}/{TOTAL_FRAMES} ({(i/TOTAL_FRAMES)*100:.1f}%)")

    print("All frames rendered!")


def compile_mp4():
    print("Encoding video with FFmpeg...")
    cmd = [
        "ffmpeg", "-y",
        "-framerate", str(FPS),
        "-i", os.path.join(TEMP_FRAMES_DIR, "frame_%04d.png"),
        "-i", AUDIO_PATH,
        "-c:v", "libx264",
        "-pix_fmt", "yuv420p",
        "-preset", "fast",
        "-crf", "18",
        "-c:a", "aac",
        "-b:a", "192k",
        OUTPUT_MP4
    ]
    
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if res.returncode == 0:
        print(f"SUCCESS: Promotional video generated at {OUTPUT_MP4}")
    else:
        print(f"FFmpeg Error:\n{res.stderr}")


def main():
    create_audio()
    generate_frames()
    compile_mp4()
    print("Done!")

if __name__ == "__main__":
    main()
