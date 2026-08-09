#!/usr/bin/env python3
import time
import sys
import os

# --- COLOR CODES (Culpeo Rust & Ember Orange Theme) ---
RUST = "\033[38;2;193;68;14m"       # #C1440E
EMBER = "\033[38;2;242;118;46m"     # #F2762E
WHITE = "\033[38;2;250;247;242m"    # #FAF7F2
GRAY = "\033[38;2;140;148;165m"     # #8C94A5
CYAN = "\033[38;2;90;200;250m"      # #5AC8FA
GOLD = "\033[38;2;255;184;0m"       # #FFB800
RESET = "\033[0m"
BOLD = "\033[1m"
CLEAR_LINE = "\033[K"
HIDE_CURSOR = "\033[?25l"
SHOW_CURSOR = "\033[?25h"

# --- ANIMATED FOX FRAMES ---
FOX_FRAME_1 = [
    f"{EMBER}  /\\___/\\  {RESET}",
    f"{EMBER} ( {WHITE}o{EMBER}_{WHITE}o{EMBER}  ) {RUST}____{RESET}",
    f"{EMBER}   =^=   {RUST}(____){RESET}",
    f"{EMBER}  /   {EMBER}\\  {RUST}/\\  /\\{RESET}"
]

FOX_FRAME_2 = [
    f"{EMBER}  /\\___/\\  {RESET}",
    f"{EMBER} ( {WHITE}o{EMBER}_{WHITE}o{EMBER}  ) {RUST}~~~_{RESET}",
    f"{EMBER}   =^=   {RUST}(____){RESET}",
    f"{EMBER}  /|  |\\ {RUST} /\\  /\\{RESET}"
]

FOX_FRAME_3 = [
    f"{EMBER}  /\\___/\\  {RESET}",
    f"{EMBER} ( {GOLD}^   ^{EMBER} ) {RUST}_____{RESET}",
    f"{EMBER}   =^=   {RUST}(____){RESET}",
    f"{EMBER}   |  /  {RUST}  \\  \\{RESET}"
]

FOX_FRAME_4 = [
    f"{EMBER}  /\\___/\\  {RESET}",
    f"{EMBER} ( {WHITE}o{EMBER}_{WHITE}o{EMBER}  ) {RUST}~~~~_{RESET}",
    f"{EMBER}   =^=   {RUST}(____){RESET}",
    f"{EMBER}  /|  /\\ {RUST}  /  /{RESET}"
]

FOX_FRAMES = [FOX_FRAME_1, FOX_FRAME_2, FOX_FRAME_3, FOX_FRAME_4]

STATUS_MESSAGES = [
    "🧠 Initializing Hardware-Aware Engine...",
    "⚡ Scanning GPU VRAM & System Memory...",
    "🤖 Spawning Scout Agent Swarm...",
    "🗂️ Indexing SQLite FTS5 Vector Memory...",
    "🚀 Local Model llama.cpp Ready!"
]

def run_fox_animation():
    os.system('clear' if os.name == 'posix' else 'cls')
    print(HIDE_CURSOR, end="")
    
    print(f"{BOLD}{EMBER}=== CULPEO STUDIO TERMINAL FOX MASCOT ==={RESET}\n")
    
    try:
        width = 60
        pos = 0
        direction = 1
        frame_idx = 0
        msg_idx = 0
        step_counter = 0

        while True:
            # Move cursor back up to redraw fox
            print("\033[H\033[2B", end="")
            
            indent = " " * pos
            current_frame = FOX_FRAMES[frame_idx % len(FOX_FRAMES)]
            
            # Print Fox Frame
            for line in current_frame:
                print(f"{CLEAR_LINE}{indent}{line}")
                
            # Ground Line
            ground = f"{RUST}~{EMBER}={RUST}~" * (width // 3)
            print(f"{CLEAR_LINE}{GRAY}{ground}{RESET}")
            
            # Status Text
            current_msg = STATUS_MESSAGES[msg_idx % len(STATUS_MESSAGES)]
            print(f"\n{CLEAR_LINE}{BOLD}{CYAN}{current_msg}{RESET}")
            print(f"{CLEAR_LINE}{GRAY}Press Ctrl+C to stop...{RESET}")

            # Position & Frame Updates
            pos += direction
            if pos >= width - 15:
                direction = -1
            elif pos <= 0:
                direction = 1
                
            frame_idx += 1
            step_counter += 1
            if step_counter % 20 == 0:
                msg_idx += 1
                
            time.sleep(0.12)
            
    except KeyboardInterrupt:
        print(f"\n\n{EMBER}Culpeo Fox sits down. Goodbye! 🦊{RESET}")
    finally:
        print(SHOW_CURSOR, end="")

if __name__ == "__main__":
    run_fox_animation()
