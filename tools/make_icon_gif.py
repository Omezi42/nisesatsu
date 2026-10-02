"""build/icon_frames/ のコマを unityroom 用のアイコンGIF(512KB以下)にまとめる。tools/make_icon.sh から呼ぶ"""
import glob
import os
import sys

from PIL import Image

FRAMES_GLOB = "build/icon_frames/f_*.png"
OUT = "build/unityroom_icon.gif"
SIZE = 320
COLORS = 128
PALETTE_FRAME = 30  # ロゼットを拡大したコマ。色数が最も多い
FRAME_MS = 70
HOLDS = {0: 900, 31: 500}  # 紙幣全体と、拡大しきったところで止める
LIMIT_BYTES = 512 * 1024

files = sorted(glob.glob(FRAMES_GLOB))
if not files:
    sys.exit("コマがありません: " + FRAMES_GLOB)
frames = [Image.open(f).convert("RGB").resize((SIZE, SIZE), Image.LANCZOS) for f in files]
palette = frames[PALETTE_FRAME].quantize(colors=COLORS, method=Image.Quantize.MEDIANCUT)
quantized = [f.quantize(palette=palette, dither=Image.Dither.NONE) for f in frames]
durations = [HOLDS.get(i, FRAME_MS) for i in range(len(quantized))]
quantized[0].save(
    OUT, save_all=True, append_images=quantized[1:], duration=durations, loop=0, optimize=True, disposal=1
)
size = os.path.getsize(OUT)
print(f"{OUT} {size // 1024}KB")
if size > LIMIT_BYTES:
    sys.exit("512KB を超えています。SIZE か COLORS を下げてください")
