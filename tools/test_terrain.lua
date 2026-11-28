-- Exercise the exact production block with mocked DST/GP entities.
local f=assert(io.open("modmain.lua","rb")); local src=f:read("*a"); f:close()
local block=assert(src:match("%-%- QPS_TERRAIN_BEGIN(.-)%-%- QPS_TERRAIN_END"))
local factory=assert(loadstring or load)
local hook, config, version = nil, true, "3.2.0"
local tasks, removed = {}, 0
local function world()
    local w={valid=true}
    function w:IsValid() return self.valid end
    function w:ListenForEvent(_, fn) self.onremove=fn end
    function w.DoTaskInTime(_, delay, fn)
        local t={fn=fn,delay=delay}; function t:Cancel() self.cancelled=true end
        tasks[#tasks+1]=t; return t
    end
    return w
end
local function entity()
    local e={prefab="gridplacer",persists=false,_geo_replaced_anim=true,valid=true,
        components={placer={snap_to_tile=true}}, Transform={SetRotation=function() end}}
    function e:IsValid() return self.valid end
    function e.HasTag(_, tag) return tag=="NOCLICK" end
    function e:Hide() self.hidden=true end
    function e:Remove() assert(self.valid);self.valid=false;removed=removed+1 end
    return e
end
local gp=assert(factory([[
return function(c,x,z,pt,e)
    if not e then e=make(); spawned=spawned+1 end
    c.build_grid[x][z]=e; c.build_grid_positions[x][z]=pt
end,
function(c)
    if c.build_grid then for _,row in pairs(c.build_grid) do
        for _,e in pairs(row) do e:Remove() end
    end end
    c.build_grid=nil;c.build_grid_positions=nil
end, function() end, function() end
]],"@mods/workshop-351325790/modmain.lua"))
-- Use real Lua source provenance, not a mocked debug result.
make=entity
_G.spawned=0
local build, remove, update, refresh=gp()
GLOBAL={debug=debug,TheWorld=world(),KnownModIndex={GetModInfo=function() return {version=version} end}}
function GetModConfigData() return config end
function AddPrefabPostInit(name,fn) assert(name=="gridplacer");hook=fn end
local function init()
    local c={inst=entity(),snap_to_tile=true,placertype="gridplacer",
        geometry={gridplacer_rotation=0},BuildGridPoint=build,RemoveBuildGrid=remove,
        OnUpdate=update,RefreshGridPoint=refresh}
    c.inst.components.placer=c;hook(c.inst);return c
end
local function grid(c,n)
    c.build_grid={{}};c.build_grid_positions={{}}
    for i=1,n do c:BuildGridPoint(1,i,i) end
end
config=false;assert(factory(block))();assert(hook==nil)
config=true;assert(factory(block))()
version="4.0";assert(not init()._qps_terrain_pool);version="3.2.0"
-- Unknown methods must pass through with no wrapping.
local original=build;build=function() end
assert(not init()._qps_terrain_pool);build=original
local a=init();assert(a._qps_terrain_pool);grid(a,25);assert(_G.spawned==25)
local first=a.build_grid[1][1];a:RemoveBuildGrid();assert(first.valid and first.hidden and removed==0)
local b=init();grid(b,25);assert(_G.spawned==25 and b.build_grid[1][25]==first)
b:RemoveBuildGrid();assert(#tasks==1)
tasks[1].fn();assert(removed==8)
while #tasks>1 and removed<25 do tasks[#tasks].fn() end
assert(removed==25)
local c=init();grid(c,130);c:RemoveBuildGrid();assert(removed==34)
local previous=GLOBAL.TheWorld;previous.onremove();assert(tasks[#tasks].cancelled)
GLOBAL.TheWorld=world()
local d=init();grid(d,1);assert(_G.spawned==156)
d.snap_to_tile=false;d:RemoveBuildGrid();assert(removed==35)
local other=init();other.placeTestFn=function() end;grid(other,1);other:RemoveBuildGrid();assert(removed==36)
print("PASS: opt-in, unsupported version, 25 recycled markers, bounded pool, batch expiry, world reset, unsupported placers")
