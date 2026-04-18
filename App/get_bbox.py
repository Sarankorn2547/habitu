from PIL import Image
import os
import json

d = r"d:\Working\habitu\App\assets\room_obj"
res = {}
for f in os.listdir(d):
    if f.endswith(".png") and f not in ["room_empty.png", "room.png"]:
        path = os.path.join(d, f)
        img = Image.open(path).convert("RGBA")
        bbox = img.getbbox()
        res[f] = bbox

with open(r"d:\Working\habitu\App\bboxes.json", "w") as out:
    json.dump(res, out)
