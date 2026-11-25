# -*- coding: utf-8 -*-
"""Pacotes determinísticos do Desbloquear QPS.

Uso:
  python tools/gerar_pacotes.py
  python tools/gerar_pacotes.py --verificar

O pacote Workshop contém só o mod e seus recursos; a DLL permanece
exclusivamente no pacote completo. Não envia nada automaticamente à Steam.
"""
from __future__ import annotations
import argparse
import hashlib
import zipfile
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/"pacotes"
FOLDER="Desbloquear QPS"
DATE=(2026,11,22,12,0,0)
MOD_FILES=[
    "modinfo.lua","modmain.lua","keybind.lua",
    "modicon.tex","modicon.xml","preview.png","icone-workshop-512.png",
]
ALL_ROOT_FILES=[
    "README.md","LICENSE","HISTORICO.md","INSTALAR DLL.bat",*MOD_FILES,
]
ALL_DIRS=["shaders","bin64","native_plugin","licenses","art","docs","tools"]

def collect(files:list[str],dirs:list[str])->list[Path]:
    paths=[]
    for name in files:
        p=ROOT/name
        if not p.is_file():
            raise FileNotFoundError("Arquivo ausente: "+str(p))
        paths.append(p)
    for name in dirs:
        d=ROOT/name
        if not d.is_dir():
            raise FileNotFoundError("Pasta ausente: "+str(d))
        for p in sorted(d.rglob("*")):
            if not p.is_file():
                continue
            if any(part in {".build","third_party","__pycache__"} for part in p.relative_to(ROOT).parts):
                continue
            if p.suffix.lower() in (".pyc",".o",".obj",".log",".tmp"):
                continue
            paths.append(p)
    result=sorted(set(paths),key=lambda p:p.relative_to(ROOT).as_posix())
    if len(result)!=len(paths):
        raise RuntimeError("Arquivo duplicado no pacote.")
    return result

def entries(paths:list[Path])->dict[str,bytes]:
    return {FOLDER+"/"+p.relative_to(ROOT).as_posix():p.read_bytes() for p in paths}

def make(name:str,files:dict[str,bytes]):
    destination=OUT/name
    with zipfile.ZipFile(destination,"w",compression=zipfile.ZIP_DEFLATED,compresslevel=9) as archive:
        for arc,contents in sorted(files.items()):
            z=zipfile.ZipInfo(arc,date_time=DATE)
            z.compress_type=zipfile.ZIP_DEFLATED
            z.external_attr=0o644<<16
            archive.writestr(z,contents,compress_type=zipfile.ZIP_DEFLATED,compresslevel=9)
    return destination

def verify(name:str,expected:dict[str,bytes])->None:
    f=OUT/name
    with zipfile.ZipFile(f) as z:
        assert z.testzip() is None, "Arquivo ZIP corrompido: "+str(f)
        assert set(z.namelist())==set(expected), "Lista de arquivos inesperada em "+name
        for n,data in expected.items():
            assert z.read(n)==data, "Conteúdo divergente no ZIP: "+n
    print("OK",name,"arquivos",len(expected),"tamanho",f.stat().st_size,
          "SHA256",hashlib.sha256(f.read_bytes()).hexdigest())

def main()->None:
    arg=argparse.ArgumentParser(description="Empacota/verifica os lançamentos do Desbloquear QPS")
    arg.add_argument("--verificar",action="store_true",help="Apenas confere os pacotes, sem gravar")
    opts=arg.parse_args()
    full=entries(collect(ALL_ROOT_FILES,ALL_DIRS))
    workshop=entries(collect(MOD_FILES,["shaders"]))
    # Para assinantes da Workshop: DLL, INI, instalador e instruções.
    # O ZIP não pode conter os scripts do mod e criar versões duplicadas.
    complemento=entries(collect([
        "bin64/dinput8.dll", "bin64/dst_fps.ini", "tools/instalar_local.ps1",
        "tools/instalar_workshop.ps1", "INSTALAR DLL.bat"
    ],[]))
    complemento[FOLDER+"/LEIA-ME-ANTES-DE-INSTALAR.txt"]=(ROOT/"docs"/"INSTRUCOES_DLL.txt").read_bytes()
    assert len(complemento)==6
    assert not any(n.endswith(".lua") or "/shaders/" in n for n in complemento)
    assert len(workshop)>=11, "Arquivos Workshop incompletos"
    assert "Desbloquear QPS/bin64/dinput8.dll" in full
    assert "Desbloquear QPS/bin64/dinput8.dll" not in workshop
    assert not any("/native_plugin/" in s or s.endswith(".ps1") for s in workshop)
    OUT.mkdir(parents=True,exist_ok=True)
    names=[
      ("Desbloquear-QPS-v1.0.2-Completo.zip",full),
      ("Desbloquear-QPS-v1.0.2-Workshop.zip",workshop),
      ("Desbloquear-QPS-DLL-Windows-x64.zip",complemento),
    ]
    if not opts.verificar:
        for n,data in names:
            make(n,data)
    for n,data in names:
        verify(n,data)
    print("PACOTES_APROVADOS")

if __name__=="__main__":
    main()
