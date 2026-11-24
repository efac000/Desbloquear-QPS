# -*- coding: utf-8 -*-
"""Teste estatico para o pacote Cafe Smooth v1.0.0 (nenhum arquivo modificado)."""
from pathlib import Path
import re, hashlib, struct, subprocess, shutil, sys
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
info=(ROOT/"modinfo.lua").read_text(encoding="utf-8-sig")
assert 'name = "Desbloquear QPS"' in info
assert 'author = "café"' in info
assert 'version = "1.0.0"' in info
assert 'client_only_mod = true' in info
s=info.split("configuration_options = {",1)[1]
names=re.findall(r'(?m)^\s*name = "([a-z_0-9]+)"',s)
defaults=re.findall(r'(?m)^\s*default = ([^\n,]+)',s)
expected_defaults={
 "target_fps":"240","visual_preset":"0",
 "visual_af16":"false","visual_full_lightmap":"false",
 "visual_cas":"false","visual_contact_ao":"false",
 "visual_calm_env":"false","visual_soft_bloom":"false",
 "visual_storybook_tone":"false",
 "skeletal_tween":"true","smooth_camera":"true",
 "smooth_ui_240hz":"true","reduce_240hz_churn":"true",
 "keep_shard_assets":"true","fast_mod_scan":"true",
 "skip_top_mods_query":"true","skip_motd_delay":"true",
 "show_fps_hud":"true","show_1pct_low":"true","auto_60hz_sim":"true",
 "hotkey_cycle":'"KEY_DISABLED"',"hotkey_skeletal":'"KEY_DISABLED"',
 "hotkey_hud":'"KEY_DISABLED"',"hotkey_visual":'"KEY_DISABLED"'
}
assert len(names)==len(defaults)==24 and len(set(names))==24, (len(names),len(defaults))
assert dict(zip(names,defaults))==expected_defaults,dict(zip(names,defaults))
values=re.findall(r'\bdata = ([^},\n]+)',s)
# 7 FPS, 4 perfis, 7 opcoes visuais binarias, 11 opcoes funcionais binarias.
expected_values = ["60","120","144","165","240","360","0","0","1","2","3"] + ["false","true"]*7 + ["true","false"]*11
assert [v.strip() for v in values] == expected_values, values

for filename in ["modinfo.lua","modmain.lua","keybind.lua"]:
    file=ROOT/filename
    code=file.read_text(encoding="utf-8")
    assert not re.search(r'[\u3400-\u9fff]',code),file
    t=subprocess.run(["luac","-p",str(file)],capture_output=True,text=True)
    assert t.returncode==0,(file,t.stderr)
print("PASS: modinfo / 24 chaves / Lua 5.1 / sem ideogramas")

for n in ["hs_kawase_down.ksh","hs_kawase_up.ksh","hs_postprocess_bloom.ksh","hs_visual_final.ksh"]:
    assert (ROOT/"shaders"/n).stat().st_size>250
assert b'<Texture filename="modicon.tex"' in (ROOT/"modicon.xml").read_bytes()
assert (ROOT/"modicon.tex").read_bytes()[:4]==b"KTEX"
assert (ROOT/"modicon.tex").stat().st_size>10000
with Image.open(ROOT/"preview.png") as im:assert im.size==(512,512)
with Image.open(ROOT/"icone-workshop-512.png") as im:assert im.size==(512,512)
with Image.open(ROOT/"art"/"icone-mestre-512.png") as im:assert im.size==(512,512)
with Image.open(ROOT/"art"/"modicon-source-128.png") as im:assert im.size==(128,128)
print("PASS: shaders / icone 512 e 128 / textura KTEX / atlas")

binfile=ROOT/"bin64"/"dinput8.dll"
raw=binfile.read_bytes()
assert raw[:2]==b"MZ"
pe=struct.unpack_from("<I",raw,0x3C)[0]
assert raw[pe:pe+4]==b"PE\x00\x00"
assert struct.unpack_from("<H",raw,pe+4)[0]==0x8664
sha=hashlib.sha256(raw).hexdigest()
assert sha=="64d47e0188734069535b9d0b4de70099ac7caf377ba78b8e3c58d2d3884eb5c8",sha
cpp=(ROOT/"native_plugin"/"dinput8.cpp").read_text(encoding="utf-8")
assert "HookHsEglSwapInterval" in cpp
assert "LEGACY_CFG_FILENAME" in (ROOT/"modmain.lua").read_text(encoding="utf-8")
assert "desbloquear_qps_cfg_v1" in (ROOT/"modmain.lua").read_text(encoding="utf-8")
assert "HookHsEglSwapBuffers" in cpp
assert "force_unsynced_presentation" in cpp
ini=(ROOT/"bin64"/"dst_fps.ini").read_text(encoding="utf-8")
assert "force_unsynced_presentation=1" in ini
assert "low_latency_gpu_sync=0" in ini
for f in ["LICENSE","licenses/libdeflate-COPYING","licenses/mimalloc-LICENSE"]:
    assert (ROOT/f).stat().st_size>200
assert "Hakimi Tech Lab" in (ROOT/"LICENSE").read_text(encoding="utf-8")
print("PASS: DLL PE x64 / hash conhecido / fonte EGL / configuracao / licencas")

# Exercita a funcao real do mod, e nao uma copia no teste.
modmain=(ROOT/"modmain.lua").read_text(encoding="utf-8")
fn=re.search(r"local function IsSupportedTargetFps\(value\).*?\nend\n",modmain,re.S)
assert fn is not None, "Validador de FPS persistido ausente"
runtime='local FPS_PRESETS={60,120,144,165,240,360,0}\n'+fn.group(0)+"""
for _,v in ipairs({60,120,144,165,240,360,0}) do
    assert(IsSupportedTargetFps(v), "preset legitimo rejeitado")
end
for _,v in ipairs({-1,61,75,720,1001,"240",true}) do
    assert(not IsSupportedTargetFps(v), "preset invalido aceito")
end
assert(not IsSupportedTargetFps(nil))
"""
run=subprocess.run(["lua","-e",runtime],capture_output=True,text=True)
assert run.returncode==0,run.stderr
assert "if IsSupportedTargetFps(sf) and mf == TARGET_FPS then" in modmain
assert "if not current_show_fps_hud and toast_timer <= 0 then" in modmain
assert modmain.count("local VISUAL_HUD_MODE_TAGS = {")==1
assert "local mode_tags = {" not in modmain
installer=(ROOT/"tools"/"instalar_local.ps1").read_text(encoding="utf-8")
assert "if (!$Aplicar)" in installer and "PermitirOutraDLL" in installer and "SomenteDLL" in installer
print("PASS: presets testados em Lua / telemetria HUD oculto / instalador em simulacao")
print("SUITE_ESTATICA_APROVADA")


# Auditoria dos textos próprios, sem alterar nomes internos de teclas/API.
info=(ROOT/"modinfo.lua").read_text(encoding="utf-8")
assert 'name = "Desbloquear QPS"' in info
assert 'key_labels_ptbr' in info and 'numpad_labels_ptbr' in info
assert 'local enabled_str = "Ativado"' in modmain
assert 'local disabled_str = "Desativado"' in modmain
assert "Usage:" not in modmain and "Unknown option" not in modmain
assert "[Café Smooth" not in modmain
for doc in ["README.md","docs/INSTALACAO.md","docs/BAIXAR_DLL.md",
            "docs/INSTRUCOES_DLL.txt","docs/PUBLICACAO_WORKSHOP.md","docs/FAQ.md"]:
    assert (ROOT/doc).is_file(),doc
readme=(ROOT/"README.md").read_text(encoding="utf-8")
assert "Desbloquear-QPS-DLL-Windows-x64.zip" in readme
assert "releases/latest/download/dinput8.dll" in readme
assert "releases/latest/download/dst_fps.ini" in readme

# O modinfo não pode depender dos globais Lua removidos pelo sandbox da Klei.
bare = """local env = {}
local code
if type(setfenv) == "function" then
    code = assert(loadfile("modinfo.lua"))
    setfenv(code, env)
else
    code = assert(loadfile("modinfo.lua", "t", env))
end
assert(pcall(code))
assert(env.name == "Desbloquear QPS")
assert(env.client_only_mod == true)
assert(type(env.configuration_options) == "table" and #env.configuration_options == 24)
assert(type(env.keys) == "table" and #env.keys > 70)
"""
test = subprocess.run(["lua","-e",bare],cwd=str(ROOT),capture_output=True,text=True)
assert test.returncode == 0,test.stderr
print("PASS: textos da edição PT-BR / sandbox do modinfo / guias de instalação")


# Página estática de download (publicação via GitHub Pages em main/docs).
site=(ROOT/"docs"/"index.html").read_text(encoding="utf-8")
assert '<html lang="pt-BR">' in site
assert "Versão atual: v1.0.0" in site
assert "Desbloquear-QPS-DLL-Windows-x64.zip" in site
assert "releases/latest/download/dinput8.dll" in site
assert "releases/latest/download/dst_fps.ini" in site
assert "Instale em 3 passos" in site
assert "ATENÇÃO: A DLL É NECESSÁRIA" in site
assert "border:2px solid #f16d72" in site
assert "notice-title" in site and "notice-emphasis" in site
assert (ROOT/"docs"/".nojekyll").is_file()
assert (ROOT/"docs"/"icone-workshop-512.png").read_bytes()==(ROOT/"icone-workshop-512.png").read_bytes()
print("PASS: página PT-BR, versão atual, links diretos, ícone e instruções")
# O instalador de duplo clique deve ser incluso no ZIP de DLL e no completo,
# sem duplicar os arquivos do mod da Workshop.
launcher=(ROOT/"INSTALAR DLL.bat").read_text(encoding="utf-8")
wrapper=(ROOT/"tools"/"instalar_workshop.ps1").read_text(encoding="utf-8")
assert "tools\\instalar_workshop.ps1" in launcher
assert "-SomenteDLL -Aplicar -PastaJogo" in wrapper
assert "FindDST" in wrapper and "CanWrite" in wrapper
assert "Start-Process -FilePath $powershell -Verb RunAs" in wrapper
assert "INSTALAR DLL.bat" in (ROOT/"README.md").read_text(encoding="utf-8")
assert "INSTALAR DLL.bat" in site
print("PASS: instalador de dois cliques e instruções da Workshop")
