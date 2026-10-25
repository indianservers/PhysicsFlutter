"""QA-only contact sheets; source screenshots remain unchanged."""
import sys
from pathlib import Path
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[1]
pattern = sys.argv[1] if len(sys.argv) > 1 else 'phase3-before-s0*-e*.png'
files = sorted((root / 'screenshots').glob(pattern))
sheet = Image.new('RGB', (6 * 240, ((len(files) + 5) // 6) * 450), 'white')
draw = ImageDraw.Draw(sheet)
for i, path in enumerate(files):
    image = Image.open(path).convert('RGB')
    image.thumbnail((232, 420))
    x, y = (i % 6) * 240, (i // 6) * 450
    sheet.paste(image, (x, y + 20))
    draw.text((x + 4, y + 3), path.stem, fill='black')
out = root / 'screenshots' / ('contact-' + pattern.replace('*', '').replace('.png', '') + '.jpg')
sheet.save(out, quality=88)
print(out)
