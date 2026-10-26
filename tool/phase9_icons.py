"""Rasterize the existing project flask geometry consistently for platform launchers.
No new identity or external artwork. Canonical vector: drawable/physics_icon.xml.
"""
from pathlib import Path
import json
from PIL import Image,ImageDraw

def flask(size):
 im=Image.new('RGB',(size*4,size*4),'#245ce7');draw=ImageDraw.Draw(im)
 def points(values):return [(x*size*4/108,y*size*4/108) for x,y in values]
 draw.polygon(points([(43,23),(65,23),(65,29),(61,29),(61,45),(80,78),(80,85),(28,85),(28,78),(47,45),(47,29),(43,29)]),fill='white')
 draw.polygon(points([(52,29),(56,29),(56,47),(73,77),(35,77),(52,47)]),fill='#245ce7')
 draw.polygon(points([(43,64),(65,64),(73,77),(35,77)]),fill='#54d2ca')
 return im.resize((size,size),Image.Resampling.LANCZOS)
for density,size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:flask(size).save(Path('android/app/src/main/res')/f'mipmap-{density}/ic_launcher.png')
folder=Path('ios/Runner/Assets.xcassets/AppIcon.appiconset')
for row in json.loads((folder/'Contents.json').read_text())['images']:
 if 'filename' in row:
  size=round(float(row['size'].split('x')[0])*float(row['scale'].rstrip('x')));flask(size).save(folder/row['filename'])
print('Existing flask identity applied to Android and iOS source icon slots; iOS device appearance remains untested.')
