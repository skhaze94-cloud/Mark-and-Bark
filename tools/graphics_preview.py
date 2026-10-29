#!/usr/bin/env python3
"""Make small review sheets from the native Godot fixtures, also readable in CI logs."""
import base64
from pathlib import Path
from PIL import Image, ImageDraw

folder=Path('test_output')
for number,phase in enumerate(['floor','mid','summit'],1):
    names=[f'{level}_{phase}' for level in ['library','bedroom','attic']]
    names.append('story_'+['school','garden','workshop'][number-1])
    sheet=Image.new('RGB',(1280,768),'#203849')
    draw=ImageDraw.Draw(sheet)
    for index,name in enumerate(names):
        source=folder/f'graphics_{name}.png'
        if not source.is_file():
            raise RuntimeError(f'Missing native graphics fixture: {source}')
        with Image.open(source) as image:
            image=image.convert('RGB').resize((640,360),Image.Resampling.LANCZOS)
            x=(index%2)*640;y=(index//2)*384
            sheet.paste(image,(x,y+24))
            draw.text((x+12,y+5),name.replace('_',' ').upper(),fill='#fff3d3')
    output=folder/f'graphics_preview_{number}.jpg'
    sheet.save(output,quality=74,optimize=True)
    # A single review-sheet payload stays small; chunks avoid CI log line limits.
    encoded=base64.b64encode(output.read_bytes()).decode('ascii')
    print(f'GRAPHICS_PREVIEW_{number}_BEGIN')
    for start in range(0,len(encoded),8192):
        print(f'GRAPHICS_PREVIEW_{number}_CHUNK:'+encoded[start:start+8192])
    print(f'GRAPHICS_PREVIEW_{number}_END')
