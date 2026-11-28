-- Standalone fixture: vanilla placement contract, not a game benchmark.
local f=assert(io.open("modmain.lua","rb"));local src=f:read("*a");f:close()
local block=assert(src:match("%-%- QPS_VANILLA_TERRAIN_BEGIN(.-)%-%- QPS_VANILLA_TERRAIN_END"),"missing vanilla module")
local factory=assert(loadstring or load)
local count,hook,enabled,logs=0,nil,true,{}
local player={}
local class=assert(factory([[
return {
SetBuilder=function(c,b,r,i)
  c.builder,c.recipe,c.invobject=b,r,i
  c.axisalignedplacementallowedbyitem=true
  c.axisalignedplacement=true
  c:InitializeAxisAlignedHelpers()
  return "set-result",nil,7
end,
InitializeAxisAlignedHelpers=function(c) count50();c.axisalignedhelpers={} end,
OnUpdate=function(c) return c.snap_to_tile and "tile" or "other" end
}
]],"@scripts/components/placer.lua"))()
function count50() count=count+50 end
GLOBAL={debug=debug,print=function(s) logs[#logs+1]=s end,ThePlayer=player,
require=function() return class end}
function GetModConfigData() return enabled end
function AddPrefabPostInit(name,fn) assert(name=="gridplacer");hook=fn end
local function new(opts)
  opts=opts or {}
  local inst={prefab=opts.prefab or "gridplacer"}
  local c=setmetatable({inst=inst,snap_to_tile=opts.snap~=false,
  axisalignedhelpers=opts.helpers,OnUpdate=opts.update,SetBuilder=opts.set,InitializeAxisAlignedHelpers=opts.init},{__index=class})
  inst.components={placer=c};if hook then hook(inst) end
  return c
end
enabled=false;assert(factory(block))();assert(not hook)
local c=new();c:SetBuilder(player);assert(count==50)
enabled=true;assert(factory(block))();assert(hook)
local active=new();local a,b,d=active:SetBuilder(player);assert(a=="set-result" and b==nil and d==7)
assert(count==50 and not active.axisalignedhelpers and active:OnUpdate()=="tile")
assert(active.SetBuilder==class.SetBuilder and active.OnUpdate==class.OnUpdate)
for _=1,100 do local n=new();n:SetBuilder(player);assert(not n.axisalignedhelpers) end
assert(count==50)
local remote=new();remote:SetBuilder({});assert(count==100 and remote.axisalignedhelpers)
local other=new({snap=false});other:SetBuilder(player);assert(count==150 and other.axisalignedhelpers)
local existing=new({helpers={}});existing:SetBuilder(player);assert(count==200 and existing.axisalignedhelpers)
local foreign=new({update=function() return "external" end});foreign:SetBuilder(player);assert(count==250 and foreign:OnUpdate()=="external")
local old=class.SetBuilder
class.SetBuilder=function(c,...) return old(c,...) end
local wrapped=new();wrapped:SetBuilder(player);assert(count==300 and wrapped.axisalignedhelpers)
class.SetBuilder=old
local passive=new();assert(not passive.builder);passive:InitializeAxisAlignedHelpers();assert(count==350)
local invalid=new({prefab="modded_placer"});invalid:SetBuilder(player);assert(count==400)
assert(table.concat(logs,"\n"):find("helpers ignorados",1,true))
print("PASS vanilla fixture: opt-in, 100 recreations, preserved original methods, remote, existing helpers, non-tile, foreign wrappers, passive")
