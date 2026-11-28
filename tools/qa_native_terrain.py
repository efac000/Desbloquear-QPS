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
INI_PROFILES={"spatial-off":b"fast_spatial_query","texture-off":b"timeslice_tex_upload"}
def feature_off(data,key):
    # Require a unique key in OPTIMIZE. Refuse ambiguous duplicates, even 0/1.
    matches=list(re.finditer(rb"(?im)^([ \t]*"+re.escape(key)+rb"[ \t]*=[ \t]*)([^\r\n]*)(\r?)$",data))
    if len(matches)!=1: raise RuntimeError("Chave ausente/duplicada: "+key.decode())
    m=matches[0]
    headers=list(re.finditer(rb"(?im)^\s*\[([^\]\r\n]+)\][ \t]*\r?$",data[:m.start()]))
    if not headers or headers[-1].group(1).strip().lower()!=b"optimize":
        raise RuntimeError("Chave fora de OPTIMIZE: "+key.decode())
    value=m.group(2)
    if not re.fullmatch(rb"1[ \t]*",value): raise RuntimeError("Esperava "+key.decode()+"=1.")
    return data[:m.start(2)]+b"0"+data[m.start(2)+1:]
def spatial_off(data):
    return feature_off(data,INI_PROFILES["spatial-off"])
def apply(game,mode,known=KNOWN):
    dll,disabled,ini,j=paths(game)
    if j.exists() or disabled.exists(): raise RuntimeError("Perfil/backup anterior existe; restaure primeiro.")
    if not dll.is_file() or sha(dll)!=known or not ini.is_file(): raise RuntimeError("DLL/INI inesperados.")
    if mode not in ("vanilla",*INI_PROFILES): raise RuntimeError("Perfil invalido")
    original=ini.read_bytes()
    changed=feature_off(original,INI_PROFILES[mode]) if mode in INI_PROFILES else original
    j.mkdir()
    (j/"original.ini").write_bytes(original)
    state={"mode":mode,"dll":known,"original_ini":hashlib.sha256(original).hexdigest(),"active_ini":hashlib.sha256(changed).hexdigest()}
    (j/"state.json").write_text(json.dumps(state),encoding="utf-8")
    try:
        if mode=="vanilla": dll.rename(disabled)
        elif mode in INI_PROFILES: atomic(ini,changed)
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
    elif state["mode"] in INI_PROFILES:
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
    p.add_argument("mode",choices=["status","vanilla",*INI_PROFILES,"restore"])
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
