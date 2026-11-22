# -*- coding: utf-8 -*-
"""Recompila PNG 512 e modicon.tex 128 usando imagem aprovada."""
from pathlib import Path
from PIL import Image
import os, subprocess, tempfile, shutil
root=Path(__file__).resolve().parents[1]
master=root/"art"/"icone-mestre-512.png"
converter=Path(os.environ.get("KLEI_TEXTURE_CONVERTER",
  r"C:\Program Files (x86)\Steam\steamapps\common\Don't Starve Mod Tools\mod_tools\tools\bin\TextureConverter.exe"))
assert master.is_file() and converter.is_file()
with Image.open(master) as im:
    assert im.size==(512,512),im.size
    im=im.convert("RGB")
    im.save(root/"preview.png",optimize=True)
    im.save(root/"icone-workshop-512.png",optimize=True)
    im.resize((128,128),Image.Resampling.LANCZOS).save(root/"art"/"modicon-source-128.png",optimize=True)
with tempfile.TemporaryDirectory(prefix="qps-tex-") as td:
    tex=Path(td)/"modicon.tex"
    p=subprocess.run([str(converter),"-f","argb","-p","opengl","--mipmap","--premultiply","-w","128","-h","128","-i",str(root/"art"/"modicon-source-128.png"),"-o",str(tex)],capture_output=True,text=True)
    if p.returncode:raise RuntimeError(p.stdout+p.stderr)
    assert tex.read_bytes()[:4]==b"KTEX"
    shutil.copyfile(tex,root/"modicon.tex")
print("ICON_512_128_TEX_OK")
