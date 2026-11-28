-- Test the exact production block with a GP-shaped class and Lua 5.1.
local f=assert(io.open("modmain.lua","rb"));local src=f:read("*a");f:close()
local block=assert(src:match("%-%- QPS_TERRAIN_BEGIN(.-)%-%- QPS_TERRAIN_END"))
local factory=assert(loadstring or load)
local hooks, config, version = {}, true, "3.2.0"
local tasks, removed, light, bad = {}, 0, 0, false
local logs = {}
local function world()
    local w={valid=true}
    function w:IsValid() return self.valid end
    function w:ListenForEvent(_, fn) self.onremove=fn end
    function w.DoTaskInTime(_, delay, fn)
        local t={fn=fn,delay=delay};function t:Cancel() self.cancelled=true end
        tasks[#tasks+1]=t;return t
    end
    return w
end
local function entity(prefab)
    local e={prefab=prefab,persists=false,_geo_replaced_anim=true,valid=true,
        components={}, Transform={SetRotation=function() end},AnimState={}}
    if prefab=="gridplacer" then e.components.placer={snap_to_tile=true} end
    function e:IsValid() return self.valid end
    function e.HasTag(_, tag) return tag=="NOCLICK" end
    function e:Hide() self.hidden=true end
    function e:Remove() assert(self.valid);self.valid=false;removed=removed+1 end
    return e
end
local gp=assert(factory([[
return {
BuildGridPoint=function(c,x,z,pt,e)
    if not e then e=make("gridplacer"); spawned=spawned+1 end
    c.build_grid[x][z]=e;c.build_grid_positions[x][z]=pt
    table.insert(c.refresh_queue,{x,z})
end,
RemoveBuildGrid=function(c)
    if c.build_grid then for _,row in pairs(c.build_grid) do
        for _,e in pairs(row) do e:Remove() end
    end end
    c.build_grid=nil;c.build_grid_positions=nil;c.refresh_queue=nil
end,
OnUpdate=function(c) if c.refresh_queue then c:RefreshBuildGrid(nil) end end,
RefreshGridPoint=function(c,x,z)
    local row=c.build_grid[x];local e=row and row[z]
    if e then e.hidden=false;c.checked=(c.checked or 0)+1 end
end,
RefreshBuildGrid=function(c)
    while #c.refresh_queue>0 do local pt=table.remove(c.refresh_queue);c:RefreshGridPoint(pt[1],pt[2]) end
end
}
]],"@mods/workshop-351325790/modmain.lua"))
make=entity
_G.spawned=0
local class=gp()
local function spawn(prefab)
    assert(prefab=="tile_outline")
    local e=entity(prefab);light=light+1
    if bad then e._geo_replaced_anim=false end
    return e
end
GLOBAL={debug=debug,os=os,print=function(s) logs[#logs+1]=s end,SpawnPrefab=spawn,
    TheWorld=world(),ThePlayer={HUD={}},require=function() return class end,
    KnownModIndex={GetModInfo=function() return {version=version} end}}
function GetModConfigData() return config end
function AddPrefabPostInit(name,fn) hooks[name]=fn end
local function wrap(fn,id)
    return assert(factory("return function(old) return function(c,dt) c.wrapper_calls=(c.wrapper_calls or 0)+1; return old(c,dt) end end","@mods/workshop-"..id.."/modmain.lua"))()(fn)
end
local function init(wrapper, passive)
    local c=setmetatable({inst=entity("gridplacer"),builder={},snap_to_tile=true,placertype="gridplacer",
        geometry={gridplacer_rotation=0}},{__index=class})
    c.builder=nil
    c.SetBuilder=function(self,builder) self.builder=builder;return "builder-result" end
    if wrapper then c.OnUpdate=wrapper(c.OnUpdate) end
    c.inst.components.placer=c;hooks.gridplacer(c.inst)
    if not passive then assert(c:SetBuilder({})=="builder-result") end
    return c
end
local function grid(c,n)
    c.build_grid={{}};c.build_grid_positions={{}};c.refresh_queue={}
    for i=1,n do c:BuildGridPoint(1,i,i) end
end
config=false;assert(factory(block))();assert(next(hooks)==nil)
config=true;assert(factory(block))()
version="4.0";assert(not init()._qps_terrain_pool);version="3.2.0"
local original=class.BuildGridPoint;class.BuildGridPoint=function() end
assert(not init()._qps_terrain_pool);class.BuildGridPoint=original
-- Verify first use is covered by prewarming, with no heavy marker allocation.
hooks.world(GLOBAL.TheWorld)
for i=1,13 do assert(tasks[i] and not tasks[i].cancelled);tasks[i].fn() end
assert(light==25 and #tasks==13)
local passive=init(nil,true);assert(not passive._qps_terrain_pool)
local unknown=init(function(fn) return function(c,dt) return fn(c,dt) end end)
assert(not unknown._qps_terrain_pool)
local a=init(function(fn) return wrap(wrap(fn,"2302837868"),"2873533916") end)
assert(a._qps_terrain_pool);grid(a,25)
a:OnUpdate(0);assert(a.wrapper_calls==2)
assert(#a.refresh_queue>=21 and #a.refresh_queue<25)
-- rebuild queue for existing budget assertions
a.refresh_queue={};a.checked=0
for i=1,25 do a.refresh_queue[i]={1,i};a.build_grid[1][i].hidden=true end
assert(_G.spawned==0 and light==25)
local first=a.build_grid[1][1];assert(first.prefab=="tile_outline" and first.hidden)
a:RefreshBuildGrid(0);assert(#a.refresh_queue==25)
a:RefreshBuildGrid(nil);assert(#a.refresh_queue>=21 and #a.refresh_queue<25)
while #a.refresh_queue>0 do a:RefreshBuildGrid(nil) end
assert(a.checked==25 and not first.hidden)
a:RemoveBuildGrid();assert(first.valid and first.hidden and removed==0)
local b=init(function(fn) return wrap(fn,"2302837868") end);assert(b._qps_terrain_pool);grid(b,25);assert(_G.spawned==0 and light==25)
b:RemoveBuildGrid();assert(#tasks==14)
tasks[14].fn();assert(removed==8)
while removed<25 do tasks[#tasks].fn() end
assert(removed==25)
local c=init();grid(c,130);c:RemoveBuildGrid();assert(removed==34)
local previous=GLOBAL.TheWorld;previous.onremove();assert(tasks[#tasks].cancelled)
GLOBAL.TheWorld=world()
local d=init();grid(d,1);assert(light==156)
d.snap_to_tile=false;d:RemoveBuildGrid();assert(removed==35)
local other=init();other.placeTestFn=function() end;grid(other,1)
assert(_G.spawned==1);other:RefreshBuildGrid(nil);assert(other.checked==1)
other:RemoveBuildGrid();assert(removed==36)
bad=true;local fallback=init();grid(fallback,1);assert(_G.spawned==2)
assert(fallback.build_grid[1][1].prefab=="gridplacer")
fallback:RemoveBuildGrid();assert(removed==38)
assert(#logs>=3)
print("PASS: opt-in, GP provenance, prewarm 25, light markers, capped refresh, pool, expiry, world reset, fallback")
