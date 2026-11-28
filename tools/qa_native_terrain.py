"""Local reversible native QA profiles. Never downloads, kills, or starts DST."""
from pathlib import Path
import argparse, csv, hashlib, json, os, re, subprocess, sys
KNOWN="ac60fd192f0fc8632b9c06c1ff7d8bf1afadf00151695ce0920ee77a99f949d5"
DEFAULT=Path(r"C:\Program Files (x86)\Steam\steamapps\common\Don't Starve Together")
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def guard():
    if os.name!="nt": raise RuntimeError("Windows required")
    output=subprocess.check_output(["tasklist","/FO","CSV","/NH"],text=True,errors="replace")
    if any(row and row[0].lower().startswith("dontstarve") for row in csv.reader(output.splitlines())):
        raise RuntimeError("Feche todos os processos DST, inclusive o dedicado, antes de alterar o perfil.")
def atomic(p,data):
    t=p.with_name(p.name+".qps-qa-tmp")
    if t.exists(): raise RuntimeError("Arquivo temporario existente: "+str(t))
    try:
        with t.open("xb") as f: f.write(data);f.flush();os.fsync(f.fileno())
        os.replace(t,p)
    finally:
        if t.exists(): t.unlink()
def paths(game):
    b=game/"bin64"
    return b/"dinput8.dll", b/"dinput8.dll.qps-qa-disabled", b/"dst_fps.ini", b/"qps-native-qa"
def spatial_off(data):
    # Only the existing exact INI key; preserve all other bytes and line endings.
    rx=rb"(?m)^([ \t]*fast_spatial_query[ \t]*=[ \t]*)1([ \t]*\r?)$"
    result,n=re.subn(rx,rb"\g<1>0\g<2>",data)
    if n!=1: raise RuntimeError("Esperava exatamente fast_spatial_query=1.")
    return result
def apply(game,mode,known=KNOWN):
    dll,disabled,ini,j=paths(game)
    if j.exists() or disabled.exists(): raise RuntimeError("Perfil/backup anterior existe; restaure primeiro.")
    if not dll.is_file() or sha(dll)!=known or not ini.is_file(): raise RuntimeError("DLL/INI inesperados.")
    original=ini.read_bytes()
    changed=spatial_off(original) if mode=="spatial-off" else original
    j.mkdir()
    (j/"original.ini").write_bytes(original)
    state={"mode":mode,"dll":known,"original_ini":hashlib.sha256(original).hexdigest(),"active_ini":hashlib.sha256(changed).hexdigest()}
    (j/"state.json").write_text(json.dumps(state),encoding="utf-8")
    try:
        if mode=="vanilla": dll.rename(disabled)
        elif mode=="spatial-off": atomic(ini,changed)
        else: raise RuntimeError("Perfil invalido")
    except Exception:
        if disabled.exists() and not dll.exists(): disabled.rename(dll)
        if sha(ini)==state["active_ini"] and changed!=original: atomic(ini,original)
        (j/"state.json").unlink();(j/"original.ini").unlink();j.rmdir()
        raise
    print("PERFIL_ATIVO",mode)
def restore(game):
    dll,disabled,ini,j=paths(game)
    state=json.loads((j/"state.json").read_text(encoding="utf-8"))
    original=j/"original.ini"
    if sha(original)!=state["original_ini"] or sha(ini)!=state["active_ini"]:
        raise RuntimeError("INI mudou; restaure manualmente com backup, sem sobrescrever.")
    if state["mode"]=="vanilla":
        if dll.exists() or not disabled.is_file() or sha(disabled)!=state["dll"]: raise RuntimeError("DLL inesperada.")
        disabled.rename(dll)
    elif state["mode"]=="spatial-off":
        if disabled.exists() or not dll.is_file() or sha(dll)!=state["dll"]: raise RuntimeError("DLL inesperada.")
        atomic(ini,original.read_bytes())
    else: raise RuntimeError("Perfil desconhecido.")
    if sha(dll)!=state["dll"] or sha(ini)!=state["original_ini"]: raise RuntimeError("Restauracao nao confirmada.")
    # Keep the backup manifest as evidence outside game bin64 active journal.
    archive=j.with_name(j.name+"-restored-"+str(os.stat(j/"state.json").st_mtime_ns))
    j.rename(archive)
    print("RESTAURADO",archive)
def status(game):
    dll,disabled,ini,j=paths(game)
    for p in (dll,disabled,ini):
        print(p.name,sha(p) if p.is_file() else "ausente")
    if j.exists(): print((j/"state.json").read_text(encoding="utf-8"))
    else: print("Nenhum perfil QA ativo")
def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("mode",choices=["status","vanilla","spatial-off","restore"])
    p.add_argument("--game",type=Path,default=DEFAULT)
    a=p.parse_args()
    if a.mode=="status": status(a.game)
    else:
        guard()
        if a.mode=="restore": restore(a.game)
        else: apply(a.game,a.mode)
if __name__=="__main__":
    try: main()
    except Exception as e: print("ERRO:",e,file=sys.stderr);sys.exit(1)
