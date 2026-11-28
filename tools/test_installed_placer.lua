-- Run locally against the user's installed scripts.zip, extracted to an ignored .tmp.
-- Native functions are mocked: this measures allocations, not FPS or GPU time.
local f=assert(io.open("modmain.lua","rb"));local src=f:read("*a");f:close()
local block=assert(src:match("%-%- QPS_VANILLA_TERRAIN_BEGIN(.-)%-%- QPS_VANILLA_TERRAIN_END"))
local f2=assert(io.open(arg[1],"rb"));local actual=f2:read("*a");f2:close()
local count, wall, removed = 0,0,0
local hooks = {}
local player={entity={LocalToWorldSpace=function() return 1,0,1 end}}
local controller, calls, allowed = false, 0, true
local function noop() end
local function object()
    local e={entity={SetParent=noop},AnimState=setmetatable({},{__index=function() return noop end}),
        Transform={SetPosition=noop},ListenForEvent=noop,IsValid=function() return true end,
        Remove=function() removed=removed+1 end}
    return e
end
local env=setmetatable({
    require=noop,
    Class=function(ctor)
        local c={}
        return setmetatable(c,{__call=function(_,inst) local o=setmetatable({},{__index=c});ctor(o,inst);return o end})
    end,
    SpawnPrefab=function(name) assert(name=="axisalignedplacement_outline");count=count+1;return object() end,
    TheWorld={Map={GetTileCenterPoint=function() return 2,0,2 end}},
    ThePlayer=player,TheInput={ControllerAttached=function() return controller end,GetWorldPosition=function() return {Get=function() return 5,0,5 end} end},
    TriggerDeployHelpers=function() calls=calls+1 end,
    KnownModIndex={IsModEnabled=function() return false end},KNOWN_AXISALIGNED_MODS={},
    Profile={GetAxisAlignedPlacement=function() return true end},
    TUNING={AXISALIGNEDPLACEMENT_INTERVALS=1,AXISALIGNEDPLACEMENT_CIRCLESIZE=4},TILE_SCALE=4,
    DEPLOYMODE={NONE=0,TURF=1,WALL=2}
},{__index=_G})
local chunk=assert(loadstring(actual,"@scripts/components/placer.lua"));setfenv(chunk,env)
local class=chunk()
GLOBAL={debug=debug,os=os,print=print,ThePlayer=player,require=function() return class end}
function GetModConfigData(n) return n=="terrain_vanilla_helpers" or n=="terrain_grid_pool" end
function AddPrefabPostInit(name,fn) if name=="gridplacer" then hooks[#hooks+1]=fn end end
local function make(snap,apply)
    local inst=object();inst.prefab="gridplacer";inst.StartWallUpdatingComponent=function() wall=wall+1 end
    inst.Transform.GetWorldPosition=function() return 2,0,2 end
    inst.GetPosition=function() return {} end;inst.GetRotation=function() return 0 end
    local c=class(inst);inst.components={placer=c};c.snap_to_tile=snap;c.hide_inv_icon=false
    c.testfn=function() return allowed,false end
    c.oncanbuild=function(i) i.visual="valid" end;c.oncannotbuild=function(i) i.visual="invalid" end
    if apply then for _,fn in ipairs(hooks) do fn(inst) end end
    return c
end
local a=make(true,false);a:SetBuilder(player);assert(count==50 and wall==1 and a.axisalignedhelpers)
assert(a.axisalignedhelpers.total==49);a:OnUpdate(0);assert(a.can_build and a.inst.visual=="valid");a:OnRemoveEntity();assert(removed==1)
local gpblock=assert(src:match("%-%- QPS_TERRAIN_BEGIN(.-)%-%- QPS_TERRAIN_END"))
assert(loadstring(gpblock))()
assert(loadstring(block))()
local b=make(true,true);b:SetBuilder(player);assert(count==50 and wall==2 and not b.axisalignedhelpers)
assert(b.SetBuilder==class.SetBuilder and b.OnUpdate==class.OnUpdate)
b:OnUpdate(0);assert(b.can_build and b.inst.visual=="valid")
allowed=false;b:OnUpdate(0);assert(not b.can_build and b.inst.visual=="invalid")
controller=true;b:OnUpdate(0);assert(not b.can_build and b.inst.visual=="invalid")
controller=false;allowed=true
assert(calls==4);b:OnRemoveEntity();assert(removed==1)
local c=make(false,true);c:SetBuilder(player);assert(count==100 and wall==3 and c.axisalignedhelpers)
local item={replica={inventoryitem={GetDeployMode=function() return env.DEPLOYMODE.TURF end}}}
local d=make(true,true);d:SetBuilder(player,nil,item);assert(count==100 and wall==4 and d.axisalignedplacementallowedbyitem==false)
for _=1,100 do local p=make(true,true);p:SetBuilder(player);p:OnRemoveEntity() end
assert(count==100 and wall==104)
print("PASS installed vanilla SetBuilder: 50 native helper creations baseline vs 0 optimized; turf, normal placement, 100 recreations, mouse/controller and valid/invalid update, both options on without GP; native calls mocked")
