"""Stress the exact Lua production blocks via existing fixtures, not game FPS."""
import pathlib, subprocess, tempfile, sys, hashlib, zipfile
ROOT=pathlib.Path(__file__).resolve().parents[1]
GAME=pathlib.Path(r"C:\Program Files (x86)\Steam\steamapps\common\Don't Starve Together")
GP_EXTRA=r'''
-- Reset the world and production closures after the existing adversarial cases.
GLOBAL.TheWorld.onremove()
GLOBAL.TheWorld=world()
bad=false
logs={}
local base_light,base_removed=light,removed
assert(factory(block))()
local started=os.clock()
local sizes={1,25,49,81,121,130}
local points=0
for i=1,6000 do
    local n=sizes[(i-1)%#sizes+1]
    local c=init()
    assert(c._qps_terrain_pool)
    grid(c,n)
    points=points+n
    local seen={}
    for _,e in pairs(c.build_grid[1]) do
        assert(e.valid and not seen[e]);seen[e]=true
    end
    c:RefreshBuildGrid(0)
    assert(#c.refresh_queue==n)
    while #c.refresh_queue>0 do
        local old=#c.refresh_queue
        c:RefreshBuildGrid(nil)
        assert(#c.refresh_queue<=old and old-#c.refresh_queue<=4)
    end
    assert(c.checked==n)
    c:RemoveBuildGrid()
    assert(c.build_grid==nil and c.refresh_queue==nil)
    local live=(light-base_light)-(removed-base_removed)
    assert(live>=0 and live<=121,"pool overflow or double remove")
end
local all=table.concat(logs,"\n")
local _,first=all:gsub("grade executada","")
assert(first==1)
print(string.format("STRESS_GP cycles=6000 points=%d creations=%d removes=%d retained=%d cpu_seconds=%.3f log_lines=%d",points,light-base_light,removed-base_removed,(light-base_light)-(removed-base_removed),os.clock()-started,#logs))
'''
VANILLA_EXTRA=r'''
local base=count
local n=10000
for i=1,n do
  local c=new()
  c:SetBuilder(player)
  assert(not c.axisalignedhelpers and c:OnUpdate()=="tile")
end
assert(count==base)
for i=1,1000 do
  local c=new({snap=false})
  c:SetBuilder(player)
  assert(c.axisalignedhelpers)
end
assert(count==base+50000)
print("STRESS_VANILLA eligible=10000 avoided_mock_helpers=500000 other_placers=1000 preserved_mock_helpers=50000")
'''
def run(lua, script, extra, args, tmp):
    src=(ROOT/"tools"/script).read_text(encoding="utf-8")
    f=tmp/script
    f.write_text(src+"\n"+extra,encoding="utf-8")
    subprocess.run([lua,str(f),*args],cwd=ROOT,check=True,timeout=120)
def main():
    lua=sys.argv[1] if len(sys.argv)>1 else "lua"
    with tempfile.TemporaryDirectory(prefix="qps-terrain-stress-") as td:
        tmp=pathlib.Path(td)
        run(lua,"test_terrain.lua",GP_EXTRA,[],tmp)
        run(lua,"test_vanilla_terrain.lua",VANILLA_EXTRA,[],tmp)
        zpath=GAME/"data"/"databundles"/"scripts.zip"
        with zipfile.ZipFile(zpath) as z:
            raw=z.read("scripts/components/placer.lua")
        print("INSTALLED_PLACER_SHA256",hashlib.sha256(raw).hexdigest(),flush=True)
        path=tmp/"placer.lua";path.write_bytes(raw)
        run(lua,"test_installed_placer.lua","",[str(path)],tmp)
    print("PASS STRESS (mock native API; no FPS measurement)")
if __name__=="__main__":
    main()
