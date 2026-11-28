local GLOBAL = GLOBAL
local TheSim = GLOBAL.TheSim
local TheInput = GLOBAL.TheInput
local KnownModIndex = GLOBAL.KnownModIndex
local Text = GLOBAL.require("widgets/text")
local TEMPLATES = GLOBAL.require("widgets/redux/templates")
local pcall = GLOBAL.pcall
local rawget = GLOBAL.rawget
local rawset = GLOBAL.rawset
local getmetatable = GLOBAL.getmetatable
local type = GLOBAL.type
local pairs = GLOBAL.pairs
local ipairs = GLOBAL.ipairs
local next = GLOBAL.next
local math = GLOBAL.math
local string = GLOBAL.string
local table = GLOBAL.table
local tonumber = GLOBAL.tonumber
local tostring = GLOBAL.tostring

if type(Asset) == "function" then
    Assets = {
        Asset("SHADER", "shaders/hs_kawase_down.ksh"),
        Asset("SHADER", "shaders/hs_kawase_up.ksh"),
        Asset("SHADER", "shaders/hs_postprocess_bloom.ksh"),
        Asset("SHADER", "shaders/hs_visual_final.ksh"),
    }
end

local VISUAL_PRESET = GetModConfigData("visual_preset")
if type(VISUAL_PRESET) ~= "number" then VISUAL_PRESET = 0 end
if VISUAL_PRESET < 0 or VISUAL_PRESET > 3 then VISUAL_PRESET = 0 end

-- Player-First: 7 independent per-effect toggles (ALL default OFF -> 100% Vanilla Pure out of the box!)
local CFG_VIS_AF16       = GetModConfigData("visual_af16") == true
local CFG_VIS_LIGHTMAP   = GetModConfigData("visual_full_lightmap") == true
local CFG_VIS_CAS        = GetModConfigData("visual_cas") == true
local CFG_VIS_AO         = GetModConfigData("visual_contact_ao") == true
local CFG_VIS_ENV        = GetModConfigData("visual_calm_env") == true
local CFG_VIS_SOFT_BLOOM = GetModConfigData("visual_soft_bloom") == true
local CFG_VIS_TONE       = GetModConfigData("visual_storybook_tone") == true
local CFG_VIS_MASK = (CFG_VIS_AF16 and 1 or 0)
    + (CFG_VIS_LIGHTMAP and 2 or 0)
    + (CFG_VIS_CAS and 4 or 0)
    + (CFG_VIS_AO and 8 or 0)
    + (CFG_VIS_ENV and 16 or 0)
    + (CFG_VIS_SOFT_BLOOM and 32 or 0)
    + (CFG_VIS_TONE and 64 or 0)
if VISUAL_PRESET == 0 and CFG_VIS_MASK > 0 then
    VISUAL_PRESET = 3 -- User enabled individual switches in Mod Config -> honor Custom mode directly!
end

local SKELETAL_TWEEN = GetModConfigData("skeletal_tween")
if SKELETAL_TWEEN == nil then SKELETAL_TWEEN = true end
local SMOOTH_CAMERA = GetModConfigData("smooth_camera")
if SMOOTH_CAMERA == nil then SMOOTH_CAMERA = true end
local SMOOTH_UI_240HZ = GetModConfigData("smooth_ui_240hz")
if SMOOTH_UI_240HZ == nil then SMOOTH_UI_240HZ = true end
local REDUCE_240HZ_CHURN = GetModConfigData("reduce_240hz_churn")
if REDUCE_240HZ_CHURN == nil then REDUCE_240HZ_CHURN = true end
local KEEP_SHARD_ASSETS = GetModConfigData("keep_shard_assets")
if KEEP_SHARD_ASSETS == nil then KEEP_SHARD_ASSETS = true end
local SKIP_TOP_MODS_QUERY = GetModConfigData("skip_top_mods_query")
if SKIP_TOP_MODS_QUERY == nil then SKIP_TOP_MODS_QUERY = true end
local SKIP_MOTD_DELAY = GetModConfigData("skip_motd_delay")
if SKIP_MOTD_DELAY == nil then SKIP_MOTD_DELAY = true end
local SHOW_FPS_HUD = GetModConfigData("show_fps_hud")
if SHOW_FPS_HUD == nil then SHOW_FPS_HUD = true end
local SHOW_1PCT_LOW = GetModConfigData("show_1pct_low")
if SHOW_1PCT_LOW == nil then SHOW_1PCT_LOW = true end
local AUTO_60HZ_SIM = GetModConfigData("auto_60hz_sim")
if AUTO_60HZ_SIM == nil then AUTO_60HZ_SIM = true end

local CFG_FILENAME = "desbloquear_qps_cfg_v1"
local LEGACY_CFG_FILENAME = "dst_smooth_highfps_cfg"
local FPS_PRESETS = {60, 120, 144, 165, 240, 360, 0}
local function NextFpsPreset(value)
    for _, preset in ipairs(FPS_PRESETS) do
        if preset == 0 or preset > value then return preset end
    end
end

local MIN_CUSTOM_FPS, MAX_CUSTOM_FPS = 30, 1000
local function IsSupportedTargetFps(value)
    return type(value) == "number" and (value == 0
        or (value >= MIN_CUSTOM_FPS and value <= MAX_CUSTOM_FPS and value % 1 == 0))
end

local function OpenCustomFps(current, accept)
    local Screen = GLOBAL.require("widgets/screen")
    local Image = GLOBAL.require("widgets/image")
    local ImageButton = GLOBAL.require("widgets/imagebutton")
    local frontend = GLOBAL.TheFrontEnd
    local popup = Screen("QPSTargetFps")
    popup:AddChild(TEMPLATES.BackgroundTint())
    local root = popup:AddChild(TEMPLATES.ScreenRoot())
    local value = IsSupportedTargetFps(current) and current > 0 and current or 240
    local dialog = root:AddChild(TEMPLATES.CurlyWindow(560, 210, "Limite personalizado de FPS", {
        {text = "Usar valor", cb = function()
            frontend:PopScreen(popup)
            accept(value)
        end},
        {text = "Cancelar", controller_control = GLOBAL.CONTROL_CANCEL,
            cb = function() frontend:PopScreen(popup) end},
    }, nil, "Arraste para escolher de 30 a 1000 FPS"))
    local readout = dialog:AddChild(Text(GLOBAL.CHATFONT, 28))
    readout:SetPosition(0, -12)
    local track = dialog:AddChild(Image("images/global.xml", "square.tex"))
    track:SetSize(420, 4)
    track:SetPosition(0, 30)
    track:SetTint(.38, .32, .23, 1)
    local knob = dialog:AddChild(Image("images/global_redux.xml", "scrollbar_handle.tex"))
    knob:SetScale(.3, .3, 1)
    local hit = dialog:AddChild(ImageButton("images/global.xml", "square.tex"))
    hit:SetPosition(0, 30)
    hit:ForceImageSize(436, 36)
    hit.image:SetTint(1, 1, 1, 0)
    hit.scale_on_focus = false
    hit.move_on_click = false
    local function update()
        local fraction = (value - MIN_CUSTOM_FPS) / (MAX_CUSTOM_FPS - MIN_CUSTOM_FPS)
        knob:SetPosition(420 * (fraction - .5), 30)
        readout:SetString(tostring(value) .. " FPS")
    end
    local function drag()
        knob:SetPosition(-210, 30)
        local left = knob:GetWorldPosition().x
        knob:SetPosition(210, 30)
        local right = knob:GetWorldPosition().x
        if right <= left or type(frontend.lastx) ~= "number" then update(); return end
        local fraction = math.max(0, math.min(1, (frontend.lastx - left) / (right - left)))
        value = math.floor(MIN_CUSTOM_FPS + fraction * (MAX_CUSTOM_FPS - MIN_CUSTOM_FPS) + .5)
        update()
    end
    hit:SetOnDown(drag)
    hit:SetWhileDown(drag)
    update()
    frontend:PushScreen(popup)
end
local function NormalizeCustomFps(value)
    if type(value) == "number" and value >= MIN_CUSTOM_FPS and value <= MAX_CUSTOM_FPS then
        return math.floor(value + .5)
    end
    return 0
end

-- Configs Extend computes drag positions in floating point even with a discrete step.
local function FixCustomFpsDisplay(screen, _, _, _, slider_data)
    if not slider_data or not slider_data.qps_integer_display or not screen.value_display then
        return
    end

    local display = screen.value_display
    local set_string = display.SetString
    display.SetString = function(widget, value)
        local numeric = tonumber(value)
        if numeric then
            value = tostring(NormalizeCustomFps(numeric))
        end
        return set_string(widget, value)
    end
    display:SetCharacterFilter("0123456789")
    display:SetString(display:GetString())
    display.last_safe_string = display:GetString()

    local get_value = screen.GetCurrentValue
    screen.GetCurrentValue = function(widget)
        return NormalizeCustomFps(get_value(widget))
    end
end

local remi_slider_path = "widgets/remi_sliderscreen"
if pcall(GLOBAL.require, remi_slider_path) then
    AddClassPostConstruct(remi_slider_path, FixCustomFpsDisplay)
end

local function ResolveConfiguredFps(mode, preset, custom)
    if mode == "custom" then
        local fps = NormalizeCustomFps(custom)
        return fps > 0 and fps or 240
    end
    return IsSupportedTargetFps(preset) and preset or 240
end

local TARGET_FPS = ResolveConfiguredFps(
    GetModConfigData("target_fps_mode"),
    GetModConfigData("target_fps"),
    GetModConfigData("target_fps_custom")
)

AddClassPostConstruct("screens/redux/modconfigurationscreen", function(screen)
    if screen.modname ~= modname then return end
    local grid = screen.options_scroll_list
    local apply = grid.update_fn
    grid.update_fn = function(context, row, data, index)
        apply(context, row, data, index)
        local active = data and data.option.name == "target_fps_custom"
        if active and not row.qps_custom_button then
            row.qps_custom_button = row.opt:AddChild(TEMPLATES.StandardButton(function()
                local current = row.opt.data
                if not current or current.option.name ~= "target_fps_custom" then return end
                OpenCustomFps(NormalizeCustomFps(current.selected_value), function(value)
                    current.selected_value = value
                    current.option.value = value
                    screen:MakeDirty()
                    grid:RefreshView()
                end)
            end, "Ajustar", {76, 28}))
            row.qps_custom_button:SetPosition(-160, 0)
        end
        if row.qps_custom_button then
            if active then row.qps_custom_button:Show() else row.qps_custom_button:Hide() end
        end
    end
    grid:RefreshView()
end)

-- Persistent HUD strings: no table allocation on each telemetry refresh.
local VISUAL_HUD_MODE_TAGS = { [0] = "Original", [1] = "HD",
    [2] = "Ilustração suave", [3] = "Personalizado" }
local current_target_fps = TARGET_FPS
local current_visual_preset = VISUAL_PRESET
local custom_vis_flags = {
    af16       = CFG_VIS_AF16,
    full_lm    = CFG_VIS_LIGHTMAP,
    cas        = CFG_VIS_CAS,
    ao         = CFG_VIS_AO,
    env        = CFG_VIS_ENV,
    soft_bloom = CFG_VIS_SOFT_BLOOM,
    tone       = CFG_VIS_TONE,
}
local current_skeletal_tween = SKELETAL_TWEEN and true or false
local current_show_fps_hud = SHOW_FPS_HUD and true or false
local fps_hud_text = nil
local hud_dirty_now = false
local visual_bench_timer = 0
local visual_bench_pinned = false

local visual_shaders_ready = false
local user_bloom_enabled = false
local orig_SetBloomEnabled = nil
local hd2d_smooth_wetness = 0.0

-- Player-First Presets (0 = 100% Vanilla Pure default; 1 = Eye-Care HD; 2 = Soft Storybook; 3 = Custom)
local VISUAL_PRESET_FLAGS = {
    [0] = { af16 = false, full_lm = false, cas = false, ao = false, env = false, soft_bloom = false, tone = false },
    [1] = { af16 = true,  full_lm = true,  cas = true,  ao = true,  env = false, soft_bloom = true,  tone = false },
    [2] = { af16 = true,  full_lm = true,  cas = true,  ao = true,  env = true,  soft_bloom = true,  tone = true  },
}

local function GetActiveVisualFlags()
    if current_visual_preset == 3 then
        return custom_vis_flags
    end
    return VISUAL_PRESET_FLAGS[current_visual_preset] or VISUAL_PRESET_FLAGS[0]
end

local function EncodeCustomVisMask(fl)
    return (fl.af16 and 1 or 0)
        + (fl.full_lm and 2 or 0)
        + (fl.cas and 4 or 0)
        + (fl.ao and 8 or 0)
        + (fl.env and 16 or 0)
        + (fl.soft_bloom and 32 or 0)
        + (fl.tone and 64 or 0)
end

local function DecodeCustomVisMask(m)
    if type(m) ~= "number" then return end
    local function has_bit(val, b)
        return math.floor(val / b) % 2 == 1
    end
    custom_vis_flags.af16       = has_bit(m, 1)
    custom_vis_flags.full_lm    = has_bit(m, 2)
    custom_vis_flags.cas        = has_bit(m, 4)
    custom_vis_flags.ao         = has_bit(m, 8)
    custom_vis_flags.env        = has_bit(m, 16)
    custom_vis_flags.soft_bloom = has_bit(m, 32)
    custom_vis_flags.tone       = has_bit(m, 64)
end

-- Zero-allocation independent World Shader uniform sync:
--   params[1] = contactAoStr (ANIM only: gentle base Contact AO + white-glare soft shoulder)
--   params[2] = calmEnvStr   (OCEAN_COMB + GROUND only: whisper coastal blend + matte rain darkening)
-- When both are 0.0 -> bit-for-bit identical vanilla fragment output!
local function PushHd2dEnvToNative(dt_step)
    local fnHd2d = rawget(GLOBAL, "HyperSmooth_SetHd2d")
    if type(fnHd2d) ~= "function" then
        return
    end
    local fl = GetActiveVisualFlags()
    local ao_str  = fl.ao  and (fl.tone and 1.10 or 1.0) or 0.0
    local env_str = fl.env and 1.0 or 0.0
    if ao_str <= 0.001 and env_str <= 0.001 then
        pcall(fnHd2d, 0.0, 0.0, 0.0, 0.70, 0.707, 0.707, 0.0, -1.0, 1.0, 0.94, 0.82, 0.0)
        return
    end

    local target_wet = 0.0
    if env_str > 0.001 then
        local world = rawget(GLOBAL, "TheWorld")
        local state = world and world.state or nil
        local is_cave = world ~= nil and world.HasTag ~= nil and world:HasTag("cave") or false
        if not is_cave and state then
            if state.israining then
                local rate = type(state.precipitationrate) == "number" and state.precipitationrate or 0.6
                target_wet = math.min(1.0, math.max(0.35, rate))
            elseif type(state.wetness) == "number" and state.wetness > 5 then
                target_wet = math.min(1.0, state.wetness / 60.0)
            end
        end
    end
    local step = (type(dt_step) == "number" and dt_step > 0) and math.min(1.0, dt_step * 0.45) or 1.0
    hd2d_smooth_wetness = hd2d_smooth_wetness + (target_wet - hd2d_smooth_wetness) * step

    pcall(fnHd2d, ao_str, env_str, 0.0, 0.70, 0.707, 0.707, 0.0, -1.0, 1.0, 0.94, 0.82, hd2d_smooth_wetness)
end

local function ApplyVisualPostProcess()
    local pp = rawget(GLOBAL, "PostProcessor")
    local ppe = rawget(GLOBAL, "PostProcessorEffects")
    local uv = rawget(GLOBAL, "UniformVariables")
    if not (visual_shaders_ready and pp and ppe and uv) then
        return
    end
    local fl = GetActiveVisualFlags()

    local bloom_str   = fl.tone and 0.82 or 0.68
    local bloom_knee  = fl.tone and 0.50 or 0.55
    local bloom_chr   = fl.tone and 0.14 or 0.10
    local bloom_prot  = 0.85 -- strong highlight protection: keeps white faces & marble crisp even if Bloom ON
    local cas_val     = fl.cas  and (fl.tone and 0.28 or 0.24) or 0.0
    local grade_val   = fl.tone and 0.35 or 0.0
    local dither_val  = fl.cas  and 1.5  or 0.0
    local vig_val     = fl.tone and 0.06 or 0.0
    local use_final   = fl.cas or fl.tone

    if uv.HS_BLOOM_PARAMS then
        pcall(pp.SetUniformVariable, pp, uv.HS_BLOOM_PARAMS, bloom_str, bloom_knee, bloom_chr, bloom_prot)
    end
    if uv.HS_VISUAL_PARAMS then
        pcall(pp.SetUniformVariable, pp, uv.HS_VISUAL_PARAMS, cas_val, grade_val, dither_val, vig_val)
    end

    -- Mutual exclusion: never forces Bloom ON if player disabled game Bloom; restores vanilla Bloom when OFF!
    if ppe.Bloom ~= nil and ppe.HS_Bloom ~= nil then
        local use_hs_bloom = fl.soft_bloom and user_bloom_enabled
        local use_vanilla_bloom = (not fl.soft_bloom) and user_bloom_enabled
        pcall(pp.EnablePostProcessEffect, pp, ppe.Bloom, use_vanilla_bloom)
        pcall(pp.EnablePostProcessEffect, pp, ppe.HS_Bloom, use_hs_bloom)
    end
    if ppe.HS_VisualFinal ~= nil then
        pcall(pp.EnablePostProcessEffect, pp, ppe.HS_VisualFinal, use_final)
    end
end

local function HasNativePlugin()
    return type(rawget(GLOBAL, "HyperSmooth_SetFps")) == "function"
end

local function ApplyHudVisibility()
    if fps_hud_text and fps_hud_text.inst and fps_hud_text.inst:IsValid() then
        if current_show_fps_hud then
            fps_hud_text:Show()
            hud_dirty_now = true
        else
            fps_hud_text:Hide()
        end
    end
end

local function SyncToNativePlugin(save_persist)
    -- Primary path (v2.2.1+): 0ms direct C++ <-> Lua VM memory bridge (immune to
    -- Documents/OneDrive/WeGame/Steam Cloud path mismatches!)
    local fnFps = rawget(GLOBAL, "HyperSmooth_SetFps")
    if type(fnFps) == "function" then
        pcall(fnFps, current_target_fps)
    end
    local fnSkel = rawget(GLOBAL, "HyperSmooth_SetSkeletal")
    if type(fnSkel) == "function" then
        pcall(fnSkel, current_skeletal_tween)
    end
    local fnVis = rawget(GLOBAL, "HyperSmooth_SetVisual")
    if type(fnVis) == "function" then
        local fl = GetActiveVisualFlags()
        pcall(fnVis, fl.af16 and 16 or 1, fl.full_lm)
    end
    PushHd2dEnvToNative(0)
    ApplyVisualPostProcess()
    ApplyHudVisibility()
    -- Persist user choices (and modinfo fingerprints mf/ms/mh/mvp/mvm so explicit modinfo changes win cleanly)
    if save_persist ~= false and TheSim and TheSim.SetPersistentString then
        local payload = string.format("fps=%d;skeletal=%d;hud=%d;vp=%d;vm=%d;mf=%d;ms=%d;mh=%d;mvp=%d;mvm=%d",
            current_target_fps,
            current_skeletal_tween and 1 or 0,
            current_show_fps_hud and 1 or 0,
            current_visual_preset,
            EncodeCustomVisMask(custom_vis_flags),
            TARGET_FPS,
            SKELETAL_TWEEN and 1 or 0,
            SHOW_FPS_HUD and 1 or 0,
            VISUAL_PRESET,
            CFG_VIS_MASK)
        TheSim:SetPersistentString(CFG_FILENAME, payload, false)
    end
end

-- Restore visual choices. FPS starts from the selected mod configuration mode.
if TheSim and TheSim.GetPersistentString then
    local function RestoreSavedSettings(load_success, str)
        if load_success and type(str) == "string" and #str > 0 then
            local ss = tonumber(str:match("skeletal=(%d+)"))
            local sh = tonumber(str:match("hud=(%d+)"))
            local svp = tonumber(str:match("vp=(%d+)"))
            local svm = tonumber(str:match("vm=(%d+)"))
            local ms = tonumber(str:match("ms=(%d+)"))
            local mh = tonumber(str:match("mh=(%d+)"))
            local mvp = tonumber(str:match("mvp=(%d+)"))
            local mvm = tonumber(str:match("mvm=(%d+)"))
            if ss ~= nil and ms == (SKELETAL_TWEEN and 1 or 0) then
                current_skeletal_tween = (ss ~= 0)
            end
            if sh ~= nil and mh == (SHOW_FPS_HUD and 1 or 0) then
                current_show_fps_hud = (sh ~= 0)
            end
            if svp ~= nil and svp >= 0 and svp <= 3 and mvp == VISUAL_PRESET and mvm == CFG_VIS_MASK then
                current_visual_preset = svp
                if svm ~= nil then
                    DecodeCustomVisMask(svm)
                end
            end
        end
        SyncToNativePlugin(true)
    end
    -- Migration only: prefer the independent namespace and read the old
    -- persistent settings once when updating from Café Smooth/HyperSmooth.
    TheSim:GetPersistentString(CFG_FILENAME, function(ok, saved)
        if ok and type(saved) == "string" and #saved > 0 then
            RestoreSavedSettings(ok, saved)
        else
            TheSim:GetPersistentString(LEGACY_CFG_FILENAME, RestoreSavedSettings)
        end
    end)
else
    SyncToNativePlugin(true)
end

--------------------------------------------------------------------------------
-- 0. Player-First Opt-In Visual Fidelity Pipeline (v2.5.1-remaster)
--    - Default state is 100% Vanilla Pure (ZERO forced post-processing, ZERO visual burden!)
--    - Every effect is independently toggleable (Mod Config or live c_hsopt)
--    - Disabling restores 100% vanilla rendering cleanly
--------------------------------------------------------------------------------
local function ResolveModShaderPath(rel)
    local rfp = rawget(GLOBAL, "resolvefilepath")
    if type(rfp) == "function" then
        local ok, resolved = pcall(rfp, rel)
        if ok and type(resolved) == "string" and #resolved > 0 then
            return resolved
        end
    end
    return (MODROOT or "") .. rel
end

if type(AddModShadersInit) == "function" and type(AddModShadersSortAndEnable) == "function" then
    AddModShadersInit(function()
        local net = rawget(GLOBAL, "TheNet")
        if net and net.IsDedicated and net:IsDedicated() then return end
        local pp = rawget(GLOBAL, "PostProcessor")
        local ppe = rawget(GLOBAL, "PostProcessorEffects")
        local se = rawget(GLOBAL, "SamplerEffects")
        local uv = rawget(GLOBAL, "UniformVariables")
        local SS = rawget(GLOBAL, "SamplerSizes")
        local SCM = rawget(GLOBAL, "SamplerColourMode")
        local SEB = rawget(GLOBAL, "SamplerEffectBase")
        local FM = rawget(GLOBAL, "FILTER_MODE")
        local MFM = rawget(GLOBAL, "MIP_FILTER_MODE")
        local WM = rawget(GLOBAL, "WRAP_MODE")
        if not (pp and ppe and se and uv and SS and SCM and SEB and FM and MFM and WM) then
            return
        end

        local ok_build = pcall(function()
            local sh_down  = ResolveModShaderPath("shaders/hs_kawase_down.ksh")
            local sh_up    = ResolveModShaderPath("shaders/hs_kawase_up.ksh")
            local sh_bloom = ResolveModShaderPath("shaders/hs_postprocess_bloom.ksh")
            local sh_final = ResolveModShaderPath("shaders/hs_visual_final.ksh")

            -- Player-First: only upgrade BloomSampler to 0.5x when user explicitly enabled Soft Bloom!
            local init_fl = GetActiveVisualFlags()
            if init_fl.soft_bloom then
                pp:SetBloomSamplerParams(SS.Relative, 0.5, 0.5, SCM.RGB)
            end

            uv.HS_BLOOM_PARAMS  = pp:AddUniformVariable("HS_BLOOM_PARAMS", 4)
            uv.HS_VISUAL_PARAMS = pp:AddUniformVariable("HS_VISUAL_PARAMS", 4)

            se.HS_KawaseDown1 = pp:AddSamplerEffect(sh_down, SS.Relative, 0.5, 0.5, SCM.RGB, SEB.BloomSampler)
            pp:SetEffectUniformVariables(se.HS_KawaseDown1, uv.SAMPLER_PARAMS)
            pp:SetSamplerEffectState(se.HS_KawaseDown1, WM.CLAMP_TO_EDGE)
            pp:SetSamplerEffectFilter(se.HS_KawaseDown1, FM.LINEAR, FM.LINEAR, MFM.NONE)

            se.HS_KawaseDown2 = pp:AddSamplerEffect(sh_down, SS.Relative, 0.25, 0.25, SCM.RGB, SEB.Shader, se.HS_KawaseDown1)
            pp:SetEffectUniformVariables(se.HS_KawaseDown2, uv.SAMPLER_PARAMS)
            pp:SetSamplerEffectState(se.HS_KawaseDown2, WM.CLAMP_TO_EDGE)
            pp:SetSamplerEffectFilter(se.HS_KawaseDown2, FM.LINEAR, FM.LINEAR, MFM.NONE)

            se.HS_KawaseDown3 = pp:AddSamplerEffect(sh_down, SS.Relative, 0.125, 0.125, SCM.RGB, SEB.Shader, se.HS_KawaseDown2)
            pp:SetEffectUniformVariables(se.HS_KawaseDown3, uv.SAMPLER_PARAMS)
            pp:SetSamplerEffectState(se.HS_KawaseDown3, WM.CLAMP_TO_EDGE)
            pp:SetSamplerEffectFilter(se.HS_KawaseDown3, FM.LINEAR, FM.LINEAR, MFM.NONE)

            se.HS_KawaseUp = pp:AddSamplerEffect(sh_up, SS.Relative, 0.5, 0.5, SCM.RGB, SEB.Shader, se.HS_KawaseDown1)
            pp:AddSampler(se.HS_KawaseUp, SEB.Shader, se.HS_KawaseDown2)
            pp:AddSampler(se.HS_KawaseUp, SEB.Shader, se.HS_KawaseDown3)
            pp:SetEffectUniformVariables(se.HS_KawaseUp, uv.SAMPLER_PARAMS)
            pp:SetSamplerEffectState(se.HS_KawaseUp, WM.CLAMP_TO_EDGE)
            pp:SetSamplerEffectFilter(se.HS_KawaseUp, FM.LINEAR, FM.LINEAR, MFM.NONE)

            ppe.HS_Bloom = pp:AddPostProcessEffect(sh_bloom)
            pp:AddSampler(ppe.HS_Bloom, SEB.Shader, se.HS_KawaseUp)
            pp:SetEffectUniformVariables(ppe.HS_Bloom, uv.HS_BLOOM_PARAMS)

            ppe.HS_VisualFinal = pp:AddPostProcessEffect(sh_final)
            pp:SetEffectUniformVariables(ppe.HS_VisualFinal, uv.HS_VISUAL_PARAMS)

            visual_shaders_ready = true
        end)

        if not ok_build then
            visual_shaders_ready = false
        end
    end)

    AddModShadersSortAndEnable(function()
        if not visual_shaders_ready then return end
        local pp = rawget(GLOBAL, "PostProcessor")
        local ppe = rawget(GLOBAL, "PostProcessorEffects")
        if not (pp and ppe) then return end

        pcall(function()
            if ppe.HS_Bloom and ppe.Bloom then
                pp:SetPostProcessEffectAfter(ppe.HS_Bloom, ppe.Bloom)
            end
            local tail_anchor = ppe.MoonPulseGrading or ppe.MoonPulse or ppe.Lunacy or ppe.ColourCube
            if ppe.HS_VisualFinal and tail_anchor then
                pp:SetPostProcessEffectAfter(ppe.HS_VisualFinal, tail_anchor)
            end

            -- Sync with vanilla Graphics -> Bloom toggle so both stay strictly mutually exclusive
            local mt = getmetatable(pp)
            local idx = mt and mt.__index
            if type(idx) == "table" and type(idx.SetBloomEnabled) == "function" and not idx._hs_bloom_hooked then
                idx._hs_bloom_hooked = true
                orig_SetBloomEnabled = idx.SetBloomEnabled
                if type(idx.IsBloomEnabled) == "function" then
                    local ok_b, cur_b = pcall(idx.IsBloomEnabled, pp)
                    if ok_b and cur_b ~= nil then
                        user_bloom_enabled = cur_b and true or false
                    end
                end
                idx.SetBloomEnabled = function(self, enabled)
                    user_bloom_enabled = enabled and true or false
                    if orig_SetBloomEnabled then
                        orig_SetBloomEnabled(self, user_bloom_enabled)
                    end
                    ApplyVisualPostProcess()
                end
            end

            ApplyVisualPostProcess()
        end)
    end)
end

-- Diagnostic & live per-effect console helpers:
--   c_hsvisual()                  - print active toggles + live GPU/VRAM telemetry
--   c_hsopt("cas"|"ao"|"env"|"af16"|"lightmap"|"bloom"|"tone"|"off", [true|false])
--   c_hsbench([true|false])       - pin/unpin compact HUD benchmark strip
local function PrintVisualReport()
    local names = { [0] = "Original(0)", [1] = "HDConfortavel(1)", [2] = "IlustracaoSuave(2)", [3] = "Personalizado(3)" }
    local fl = GetActiveVisualFlags()
    local fnV = rawget(GLOBAL, "HyperSmooth_GetVisualStats")
    local fnP = rawget(GLOBAL, "HyperSmooth_GetVisualPerf")
    local line1 = string.format(
        "[Desbloquear QPS — Visual] perfil=%s | efeitos(af16=%s lm=%s cas=%s ao=%s env=%s softBloom=%s tone=%s) | bloomJogo=%s",
        names[current_visual_preset] or tostring(current_visual_preset),
        tostring(fl.af16), tostring(fl.full_lm), tostring(fl.cas), tostring(fl.ao),
        tostring(fl.env), tostring(fl.soft_bloom), tostring(fl.tone), tostring(user_bloom_enabled))
    if type(fnV) == "function" then
        local ok, af, hw, hits, lmp, lms = pcall(fnV)
        if ok then
            line1 = line1 .. string.format(" | AF=%dx (hw=%.0fx hits=%d) LM=%.1fx", af or 1, hw or 1, hits or 0, lms or 0.5)
        end
    end
    if type(fnP) == "function" then
        local ok, hdAct, progs, mStr, wMs, pMs, bMs, gMs, vCur, vPk, vBud = pcall(fnP)
        if ok then
            GLOBAL.print(line1)
            GLOBAL.print(string.format(
                "[Desbloquear QPS - Diagnóstico] world_progs=%d (active_str=%.2f) | Busy=%.2fms (World=%.2fms Post=%.2fms GpuDrain=%.2fms) | VRAM=%.0fMB (Peak=%.0fMB / Budget=%.0fMB)",
                progs or 0, mStr or 0,
                bMs or 0, wMs or 0, pMs or 0, gMs or 0, vCur or 0, vPk or 0, vBud or 0))
            return
        end
    end
    GLOBAL.print(line1 .. " (no dinput8.dll bridge)")
end

rawset(GLOBAL, "c_hsvisual", PrintVisualReport)

local OPT_ALIASES = {
    af16 = "af16", af = "af16",
    lightmap = "full_lm", lm = "full_lm", full_lm = "full_lm",
    cas = "cas", sharpen = "cas",
    ao = "ao", contact_ao = "ao",
    env = "env", calm_env = "env",
    bloom = "soft_bloom", soft_bloom = "soft_bloom",
    tone = "tone", storybook = "tone",
}

rawset(GLOBAL, "c_hsopt", function(key, val)
    if type(key) ~= "string" then
        GLOBAL.print("[Desbloquear QPS] Uso: c_hsopt('af16'|'lightmap'|'cas'|'ao'|'env'|'bloom'|'tone'|'off', true|false)")
        PrintVisualReport()
        return
    end
    local k = key:lower()
    if k == "off" or k == "vanilla" or k == "reset" then
        current_visual_preset = 0
        visual_bench_timer = 12.0
        SyncToNativePlugin(true)
        hud_dirty_now = true
        PrintVisualReport()
        return
    end
    local field = OPT_ALIASES[k]
    if not field then
        GLOBAL.print("[Desbloquear QPS] Opção desconhecida '" .. tostring(key) .. "'. Opções: af16, lightmap, cas, ao, env, bloom, tone, off")
        return
    end
    -- Snapshot current effective flags into custom_vis_flags before flipping the chosen single switch!
    local cur = GetActiveVisualFlags()
    if current_visual_preset ~= 3 then
        custom_vis_flags.af16       = cur.af16
        custom_vis_flags.full_lm    = cur.full_lm
        custom_vis_flags.cas        = cur.cas
        custom_vis_flags.ao         = cur.ao
        custom_vis_flags.env        = cur.env
        custom_vis_flags.soft_bloom = cur.soft_bloom
        custom_vis_flags.tone       = cur.tone
    end
    if val == nil then
        custom_vis_flags[field] = not custom_vis_flags[field]
    else
        custom_vis_flags[field] = (val == true or val == 1)
    end
    if EncodeCustomVisMask(custom_vis_flags) == 0 then
        current_visual_preset = 0
    else
        current_visual_preset = 3
    end
    visual_bench_timer = 12.0
    SyncToNativePlugin(true)
    hud_dirty_now = true
    PrintVisualReport()
end)

rawset(GLOBAL, "c_hsbench", function(on)
    if on == nil then
        visual_bench_pinned = not visual_bench_pinned
    else
        visual_bench_pinned = on and true or false
    end
    hud_dirty_now = true
    GLOBAL.print("[Desbloquear QPS] HUD GPU/VRAM benchmark strip -> " .. (visual_bench_pinned and "PINNED ON" or "AUTO"))
end)

--------------------------------------------------------------------------------
-- 1. Fast Mod Scan: cache parsed modinfo for disabled mods so switching menus
--    doesn't re-read & re-compile 70+ unused modinfo.lua files from disk.
--    v2.2.1: preserves savedata.known_mods[modname].modinfo write-back and
--    bypasses cache on ServerCreationScreen / game_modes mods (100% DSA safe).
--------------------------------------------------------------------------------
-- QPS Workshop compatibility: use the original ModIndex.LoadModInfo.

--------------------------------------------------------------------------------
-- 2. Skip Top Popular Mods Steam Query ("Getting top mod details...", 3-13s)
--------------------------------------------------------------------------------
if SKIP_TOP_MODS_QUERY and TheSim and getmetatable then
    pcall(function()
        local mt = getmetatable(TheSim)
        local idx = mt and mt.__index
        if type(idx) == "table" and type(idx.QueryTopMods) == "function" then
            idx.QueryTopMods = function(_, cb)
                if type(cb) == "function" then
                    pcall(cb, {}, false, 0)
                end
            end
        end
    end)
end

--------------------------------------------------------------------------------
-- 3. Pure-Client Zero-Reload Cave <-> Surface Acceleration (Cross-SimReset!)
--    v2.4.1 FIX: Hook SimReset() to persist _hakimi_kept_worlds AND
--    _hakimi_kept_chars inside instanceparameters across TheSim:Reset()!
--    Keeps vanilla "forest"/"cave" AND active character prefabs hot in client
--    RAM across BACKEND shard migrations; cleanly unloads ALL on FRONTEND.
--------------------------------------------------------------------------------
if KEEP_SHARD_ASSETS and TheSim and getmetatable then
    pcall(function()
        local mt = getmetatable(TheSim)
        local idx = mt and mt.__index
        if type(idx) ~= "table" or type(idx.LoadPrefabs) ~= "function" or type(idx.UnloadPrefabs) ~= "function" then
            return
        end

        local VANILLA_WORLDS = { forest = true, cave = true }
        local Settings = GLOBAL.Settings
        if Settings then
            if type(Settings._hakimi_kept_worlds) ~= "table" then Settings._hakimi_kept_worlds = {} end
            if type(Settings._hakimi_kept_chars)  ~= "table" then Settings._hakimi_kept_chars  = {} end
        end

        -- CRITICAL: Forward kept asset maps through SimReset(instanceparameters) so
        -- TheSim:Reset() VM rebuild NEVER wipes them!
        local orig_SimReset = rawget(GLOBAL, "SimReset")
        if type(orig_SimReset) == "function" then
            rawset(GLOBAL, "SimReset", function(instanceparameters, ...)
                if instanceparameters == nil then
                    instanceparameters = {}
                end
                local s = GLOBAL.Settings
                if s and s.current_asset_set ~= "FORCERESET" then
                    if type(s._hakimi_kept_worlds) == "table" then
                        instanceparameters._hakimi_kept_worlds = s._hakimi_kept_worlds
                    end
                    if type(s._hakimi_kept_chars) == "table" then
                        instanceparameters._hakimi_kept_chars = s._hakimi_kept_chars
                    end
                end
                return orig_SimReset(instanceparameters, ...)
            end)
        end

        local old_LoadPrefabs = idx.LoadPrefabs
        local old_UnloadPrefabs = idx.UnloadPrefabs

        local function IsPureMultiplayerClient(s)
            if not s or s.one_player_mode then
                return false
            end
            local net = GLOBAL.TheNet
            if net and net.GetIsServer and net:GetIsServer() then
                return false
            end
            return true
        end

        local function UnloadKeptChars(sim, s, exclude_list)
            if type(s._hakimi_kept_chars) ~= "table" then return end
            local seen = {}
            if type(exclude_list) == "table" then
                for i = 1, #exclude_list do seen[exclude_list[i]] = true end
            end
            local extras = {}
            for kc in pairs(s._hakimi_kept_chars) do
                if not seen[kc] then
                    seen[kc] = true
                    extras[#extras + 1] = kc
                end
            end
            s._hakimi_kept_chars = {}
            if #extras > 0 then
                pcall(old_UnloadPrefabs, sim, extras)
            end
        end

        local function UnloadAllKeptWorldsAndChars(sim, s, exclude_world)
            local extras = {}
            local seen = {}
            if exclude_world then seen[exclude_world] = true end
            if type(s._hakimi_kept_worlds) == "table" then
                for kw in pairs(s._hakimi_kept_worlds) do
                    if not seen[kw] then
                        seen[kw] = true
                        extras[#extras + 1] = kw
                    end
                end
                s._hakimi_kept_worlds = {}
            end
            if type(s._hakimi_kept_chars) == "table" then
                for kc in pairs(s._hakimi_kept_chars) do
                    if not seen[kc] then
                        seen[kc] = true
                        extras[#extras + 1] = kc
                    end
                end
                s._hakimi_kept_chars = {}
            end
            if #extras > 0 then
                pcall(old_UnloadPrefabs, sim, extras)
            end
        end

        idx.LoadPrefabs = function(sim, prefabs, ...)
            local s = GLOBAL.Settings
            if IsPureMultiplayerClient(s) and s.current_asset_set == "BACKEND" and type(prefabs) == "table" then
                -- 1) World layer (forest / cave): skip completely if already hot in RAM!
                if #prefabs == 1 and VANILLA_WORLDS[prefabs[1]] then
                    local w = prefabs[1]
                    s._hakimi_kept_worlds = (type(s._hakimi_kept_worlds) == "table") and s._hakimi_kept_worlds or {}
                    if s._hakimi_kept_worlds[w] then
                        return
                    end
                    s._hakimi_kept_worlds[w] = true
                    return old_LoadPrefabs(sim, prefabs, ...)
                end
                -- 2) Active character prefabs (gamelogic.lua:L426): filter out already-kept chars!
                if type(s._hakimi_kept_chars) == "table" and next(s._hakimi_kept_chars) ~= nil and #prefabs > 0 then
                    local any_kept = false
                    for i = 1, #prefabs do
                        if s._hakimi_kept_chars[prefabs[i]] then
                            any_kept = true
                            break
                        end
                    end
                    if any_kept then
                        local remaining = {}
                        for i = 1, #prefabs do
                            local p = prefabs[i]
                            if not s._hakimi_kept_chars[p] then
                                remaining[#remaining + 1] = p
                            end
                        end
                        if #remaining == 0 then
                            return
                        end
                        local ret = old_LoadPrefabs(sim, remaining, ...)
                        if type(s.loaded_characters) == "table" then
                            local is_char = {}
                            for i = 1, #s.loaded_characters do is_char[s.loaded_characters[i]] = true end
                            for i = 1, #remaining do
                                if is_char[remaining[i]] then
                                    s._hakimi_kept_chars[remaining[i]] = true
                                end
                            end
                        end
                        return ret
                    end
                end
            end
            return old_LoadPrefabs(sim, prefabs, ...)
        end

        idx.UnloadPrefabs = function(sim, prefabs, ...)
            local s = GLOBAL.Settings
            if s and type(prefabs) == "table" then
                -- A) Returning to FRONTEND / FORCERESET: cleanly unload all kept worlds & chars (zero double-unload!)
                if s.current_asset_set == "FRONTEND" or s.current_asset_set == "FORCERESET" then
                    local excl = (#prefabs == 1 and VANILLA_WORLDS[prefabs[1]]) and prefabs[1] or nil
                    local ret = old_UnloadPrefabs(sim, prefabs, ...)
                    if excl then
                        UnloadAllKeptWorldsAndChars(sim, s, excl)
                    elseif s.loaded_characters ~= nil and prefabs == s.loaded_characters then
                        UnloadKeptChars(sim, s, prefabs)
                    end
                    return ret
                end
                -- B) BACKEND -> BACKEND shard migration (Forest <-> Caves):
                if IsPureMultiplayerClient(s) and s.current_asset_set == "BACKEND" and s.last_asset_set == "BACKEND" then
                    if #prefabs == 1 and VANILLA_WORLDS[prefabs[1]] then
                        s._hakimi_kept_worlds = (type(s._hakimi_kept_worlds) == "table") and s._hakimi_kept_worlds or {}
                        s._hakimi_kept_worlds[prefabs[1]] = true
                        return
                    end
                    if s.loaded_characters ~= nil and prefabs == s.loaded_characters then
                        s._hakimi_kept_chars = (type(s._hakimi_kept_chars) == "table") and s._hakimi_kept_chars or {}
                        for i = 1, #prefabs do
                            s._hakimi_kept_chars[prefabs[i]] = true
                        end
                        return
                    end
                end
            end
            return old_UnloadPrefabs(sim, prefabs, ...)
        end
    end)
end

--------------------------------------------------------------------------------
-- 4. Skip Blocking MOTD Network Wait: mark MOTD ready from local cache immediately.
--    Does NOT affect Steam/Klei online login, skins, or multiplayer.
--------------------------------------------------------------------------------
if SKIP_MOTD_DELAY then
    AddClassPostConstruct("motdmanager", function(self)
        local old_DownloadMotdInfo = self.DownloadMotdInfo
        if old_DownloadMotdInfo then
            self.DownloadMotdInfo = function(mgr, remaining_retries)
                if mgr.LoadCachedImages then
                    pcall(mgr.LoadCachedImages, mgr)
                end
                if mgr.SetLoadingDone and not mgr.is_loading_done then
                    pcall(mgr.SetLoadingDone, mgr)
                end
                return
            end
        end
    end)
end

--------------------------------------------------------------------------------
-- 5. Frame-Rate-Independent Exponential Damping for FollowCamera
--    Calibrated to 60Hz reference so 120/144/240Hz have identical feel + 4x smoothness.
--    Wraps original FollowCamera:Update without replacing it (100% mod-compatible).
--------------------------------------------------------------------------------
if SMOOTH_CAMERA then
    local REF_FPS = 60.0
    local REF_DT = 1.0 / REF_FPS

    local function EffectiveGain(gain, dt)
        if gain == nil or gain <= 0 or dt <= 0 then
            return gain
        end
        local alpha60 = gain * REF_DT
        if alpha60 >= 0.995 then
            return gain
        end
        local alpha_dt = 1.0 - math.pow(1.0 - alpha60, dt * REF_FPS)
        return alpha_dt / dt
    end

    AddClassPostConstruct("cameras/followcamera", function(self)
        local old_Update = self.Update
        if not old_Update then
            return
        end

        self.Update = function(cam, dt, dontupdatepos)
            if dt == nil or dt <= 0 or dt > 0.25 or cam.paused then
                return old_Update(cam, dt, dontupdatepos)
            end

            local orig_pan = cam.pangain
            local orig_heading = cam.headinggain
            local orig_dist = cam.distancegain
            local orig_cdist = cam.continuousdistancegain

            cam.pangain = EffectiveGain(orig_pan, dt)
            cam.headinggain = EffectiveGain(orig_heading, dt)
            cam.distancegain = EffectiveGain(orig_dist, dt)
            cam.continuousdistancegain = EffectiveGain(orig_cdist, dt)

            old_Update(cam, dt, dontupdatepos)

            cam.pangain = orig_pan
            cam.headinggain = orig_heading
            cam.distancegain = orig_dist
            cam.continuousdistancegain = orig_cdist
        end
    end)
end

--------------------------------------------------------------------------------
-- 6. High-Refresh-Rate (120~360Hz) Vanilla DST Bug Fixes:
--    a) TrueScrollList & ChatScrollList: replace hardcoded 0.25 Lerp (4x too fast @ 240Hz)
--       with exact 60Hz-calibrated exponential damping (silky smooth crafting/mods/chat scroll).
--    b) MapScreen: fix hardcoded 1/60 zoom step (4x too fast @ 240Hz).
--    c) DeployHelper: fix frame-counted delay=2 decay (eliminates placement ring flicker @ 240Hz).
--------------------------------------------------------------------------------
if SMOOTH_UI_240HZ then
    local function WrapSmoothScrollList(self)
        local old_OnUpdate = self.OnUpdate
        if not old_OnUpdate then
            return
        end
        self.OnUpdate = function(list, dt)
            if dt and dt > 0 and dt < 0.05 and list.current_scroll_pos and list.target_scroll_pos then
                local diff = list.target_scroll_pos - list.current_scroll_pos
                if math.abs(diff) > 0.01 then
                    local alpha_dt = 1.0 - math.pow(0.75, dt * 60.0)
                    local scale = alpha_dt * 4.0 -- alpha_dt / 0.25
                    if scale < 0.98 then
                        local orig_target = list.target_scroll_pos
                        local fake_target = list.current_scroll_pos + diff * scale
                        if math.abs(fake_target - list.current_scroll_pos) > 0.011 then
                            list.target_scroll_pos = fake_target
                            old_OnUpdate(list, dt)
                            local delta = list.target_scroll_pos - fake_target
                            list.target_scroll_pos = orig_target + delta
                            return
                        end
                    end
                end
            end
            return old_OnUpdate(list, dt)
        end
    end

    AddClassPostConstruct("widgets/truescrolllist", WrapSmoothScrollList)
    AddClassPostConstruct("widgets/redux/chatscrolllist", WrapSmoothScrollList)

    AddClassPostConstruct("screens/mapscreen", function(self)
        local old_OnUpdate = self.OnUpdate
        if not old_OnUpdate then
            return
        end
        self.OnUpdate = function(scr, dt)
            local orig_sens = scr.zoomsensitivity
            if orig_sens and dt and dt > 0 and dt < 0.25 then
                scr.zoomsensitivity = orig_sens * (dt * 60.0)
                old_OnUpdate(scr, dt)
                scr.zoomsensitivity = orig_sens
            else
                old_OnUpdate(scr, dt)
            end
        end
    end)

    local _dbg_getinfo = (type(GLOBAL.debug) == "table" and type(GLOBAL.debug.getinfo) == "function") and GLOBAL.debug.getinfo or nil
    local function IsVanillaComponentFn(fn, file_pat)
        if fn == nil or _dbg_getinfo == nil then
            return true
        end
        local info = _dbg_getinfo(fn, "S")
        local src = info ~= nil and info.source or nil
        if type(src) ~= "string" then
            return true
        end
        return src:find(file_pat) ~= nil
    end

    AddComponentPostInit("deployhelper", function(self)
        if not IsVanillaComponentFn(self.OnWallUpdate, "components[/\\]deployhelper%.lua") then
            -- Preserve third-party mod custom deployhelper:OnWallUpdate untouched
            return
        end
        self.OnWallUpdate = function(cmp, dt)
            local step = (dt and dt > 0 and dt < 0.25) and (dt * 60.0) or 1.0
            if cmp.delay ~= nil and cmp.delay > step then
                cmp.delay = cmp.delay - step
            else
                cmp:StopHelper()
            end
        end
    end)
end

--------------------------------------------------------------------------------
-- 7. 240Hz Zero-Churn CPU & GC Optimizations:
--    a) DistanceFade: inline scalar dot product (eliminates 240 Vector3 allocs/sec per tree/canopy).
--    b) Input:OnUpdate: lossless stationary hit-test cache (0ms latency on mouse/camera move
--       or UI screens; skips ~75% redundant 240Hz C++ GetEntitiesAtScreenPoint scans).
--    (v2.2.1+: removed HoverText SetString wrapper for 100% ShowMe / Insight RPC compatibility.)
--------------------------------------------------------------------------------
if REDUCE_240HZ_CHURN then
    local _dbg_getinfo_df = (type(GLOBAL.debug) == "table" and type(GLOBAL.debug.getinfo) == "function") and GLOBAL.debug.getinfo or nil
    AddComponentPostInit("distancefade", function(self)
        if self.OnWallUpdate ~= nil and _dbg_getinfo_df ~= nil then
            local info = _dbg_getinfo_df(self.OnWallUpdate, "S")
            local src = info ~= nil and info.source or nil
            if type(src) == "string" and src:find("components[/\\]distancefade%.lua") == nil then
                -- Preserve third-party mod custom distancefade:OnWallUpdate untouched
                return
            end
        end
        self.OnWallUpdate = function(cmp, dt)
            local player = GLOBAL.ThePlayer
            if not player then
                cmp.inst.AnimState:OverrideMultColour(1, 1, 1, 1)
                return
            end
            local cam = GLOBAL.TheCamera
            local camx, camy, camz = cam.currentpos:Get()
            local x, y, z = cmp.inst.Transform:GetWorldPosition()
            local down = cam:GetDownVec()
            local mody = (x - camx) * down.x + (y - camy) * down.y + (z - camz) * down.z
            local extrapercent = cmp.extrafn and cmp.extrafn(cmp.inst, dt) or 1
            if mody > cmp.range then
                mody = mody - cmp.range
                mody = math.min(mody, cmp.fadedist) * 1.7
                local percent = (1 - (mody / cmp.fadedist)) * extrapercent
                cmp.inst.AnimState:OverrideMultColour(1, 1, 1, percent)
            else
                cmp.inst.AnimState:OverrideMultColour(1, 1, 1, extrapercent)
            end
        end
    end)

    if TheInput and TheInput.OnUpdate then
        local old_InputOnUpdate = TheInput.OnUpdate
        local last_mx, last_my = nil, nil
        local last_tick = -1
        local last_cx, last_cy, last_cz = nil, nil, nil
        local last_heading, last_dist = nil, nil
        local last_scan_t = 0
        local GetTick = GLOBAL.GetTick
        local GetTimeRealSeconds = GLOBAL.GetTimeRealSeconds

        TheInput.OnUpdate = function(inp)
            if not inp.mouse_enabled then
                return old_InputOnUpdate(inp)
            end
            local fe = GLOBAL.TheFrontEnd
            local screen = fe and fe:GetActiveScreen()
            local world = GLOBAL.TheWorld
            local cam = GLOBAL.TheCamera
            if world and cam and cam.currentpos and screen and screen.name == "HUD" and GetTick and GetTimeRealSeconds then
                local mx, my = TheSim:GetPosition()
                local tick = GetTick()
                local cx, cy, cz = cam.currentpos:Get()
                local hd = cam.heading
                local ds = cam.distance
                local now = GetTimeRealSeconds()
                local hov = inp.hoverinst
                local hov_ok = (hov == nil) or (hov.IsValid and hov:IsValid())
                if hov_ok
                    and inp.entitiesundermouse ~= nil
                    and mx == last_mx and my == last_my
                    and tick == last_tick
                    and cx == last_cx and cy == last_cy and cz == last_cz
                    and hd == last_heading and ds == last_dist
                    and (now - last_scan_t) < 0.016 then
                    return
                end
                last_mx, last_my = mx, my
                last_tick = tick
                last_cx, last_cy, last_cz = cx, cy, cz
                last_heading, last_dist = hd, ds
                last_scan_t = now
            else
                last_mx = nil
            end
            return old_InputOnUpdate(inp)
        end
    end
end

--------------------------------------------------------------------------------
-- 8. Native ESC -> Settings -> Graphics Integration (v2.3.0)
--    Reativa a opção original "Taxa de atualização" do jogo
--    in BOTH Windowed and Fullscreen modes (ZERO duplicate FPS UI!), safely maps
--    Fullscreen hardware display Hz, fixes Klei's IsGraphicsDirty() refreshrate bug,
--    and adds only the 2 truly new visual toggles (Skeletal 240fps + FPS HUD)
--    into the empty right-column rows 6 & 7 below Dynamic Tree Shadows.
--------------------------------------------------------------------------------
AddClassPostConstruct("screens/redux/optionsscreen", function(self)
    if not self or not self.refreshRateSpinner or not self.options or not self.working then
        return
    end

    local opt_str = GLOBAL.STRINGS and GLOBAL.STRINGS.UI and GLOBAL.STRINGS.UI.OPTIONS
    local jogo_habilitado = (opt_str and opt_str.ENABLED) or "Enabled"
    local enabled_str = "Ativado"
    local disabled_str = "Desativado"
    local is_zh = (jogo_habilitado ~= "Enabled")
    local unlimited_label = is_zh and "Ilimitado" or "Ilimitado"
    local has_dll = HasNativePlugin()

    -- Helper: read real hardware monitor refresh rates for current display/resolution
    local function GetHardwareRefreshRates(scr)
        local rates = {}
        local fe = GLOBAL.TheFrontEnd
        local gOpts = fe and fe:GetGraphicsOptions()
        if not gOpts then return rates end
        local disp = scr.working.display or 0
        local mode_idx = scr.working.mode_idx or 0
        local ok, w, h = pcall(gOpts.GetDisplayMode, gOpts, disp, mode_idx)
        if not ok or not w or not h then return rates end
        local ok_n, num = pcall(gOpts.GetNumRefreshRates, gOpts, disp, w, h)
        if not ok_n or not num then return rates end
        local seen = {}
        for i = 0, num - 1 do
            local ok_r, hz = pcall(gOpts.GetRefreshRate, gOpts, disp, w, h, i)
            if ok_r and hz and hz > 0 and not seen[hz] then
                seen[hz] = true
                rates[#rates + 1] = hz
            end
        end
        table.sort(rates)
        return rates
    end

    -- Helper: map logical target FPS (including 0=Unlimited or >panel Hz) to a guaranteed valid
    -- Windows hardware display Hz so ChangeGraphicsMode NEVER falls back to 640x480 mode 0!
    local function PickSafeHardwareHz(scr, target_fps)
        local hw = GetHardwareRefreshRates(scr)
        if #hw == 0 then
            return scr._hc_hw_refreshrate or 60
        end
        if not target_fps or target_fps <= 0 then
            return hw[#hw] -- Unlimited -> highest native monitor refresh rate
        end
        for _, hz in ipairs(hw) do
            if hz == target_fps then return hz end
        end
        for _, hz in ipairs(hw) do
            if hz >= target_fps then return hz end
        end
        return hw[#hw]
    end

    -- Helper: build unified refresh/FPS option list (real monitor Hz + standard presets + Unlimited)
    local function BuildMergedRefreshOptions(scr, active_fps)
        local set = {}
        local nums = {}
        local function add_num(v)
            if type(v) == "number" and v > 0 and not set[v] then
                set[v] = true
                nums[#nums + 1] = v
            end
        end
        for _, hz in ipairs(GetHardwareRefreshRates(scr)) do add_num(hz) end
        for _, p in ipairs({ 60, 120, 144, 165, 240, 360 }) do add_num(p) end
        if type(active_fps) == "number" and active_fps > 0 then add_num(active_fps) end
        table.sort(nums)

        local opts = {}
        for _, v in ipairs(nums) do
            opts[#opts + 1] = { text = string.format("%d", v), data = v }
        end
        opts[#opts + 1] = { text = unlimited_label, data = 0 }
        return opts
    end

    self._hc_hw_refreshrate = self.options.refreshrate or 60
    self.options.refreshrate = current_target_fps
    self.working.refreshrate = current_target_fps
    self.options.hc_skeletal = current_skeletal_tween
    self.working.hc_skeletal = current_skeletal_tween
    self.options.hc_show_hud = current_show_fps_hud
    self.working.hc_show_hud = current_show_fps_hud
    self.options.hc_visual = current_visual_preset
    self.working.hc_visual = current_visual_preset

    -- Update official Refresh Rate tooltip to reflect live HyperSmooth v2.4.0 RTSS control
    if self.refreshRateSpinner.parent then
        if is_zh then
            self.refreshRateSpinner.parent.tooltip_text = has_dll
                and "Controlado pelo Desbloquear QPS: até 1000 FPS ou ilimitado, em janela ou tela cheia, com estabilização do 1% Low."
                or "Instale bin64/dinput8.dll para superar 60 FPS e ativar a estabilização de quadros (sem a DLL, controla apenas o modo de exibição)."
        else
            self.refreshRateSpinner.parent.tooltip_text = has_dll
                and "Controlado pelo Desbloquear QPS: até 1000 FPS ou ilimitado, em janela ou tela cheia, com estabilização do 1% Low."
                or "Instale bin64/dinput8.dll para superar 60 FPS e ativar a estabilização de quadros (sem a DLL, controla apenas o modo de exibição)."
        end
    end

    -- 1. Keep official refreshRateSpinner ALWAYS enabled (even in Windowed / Borderless mode!)
    local orig_UpdateResolutionsSpinner = self.UpdateResolutionsSpinner
    self.UpdateResolutionsSpinner = function(scr, ...)
        local r = orig_UpdateResolutionsSpinner(scr, ...)
        if scr.refreshRateSpinner then
            scr.refreshRateSpinner:Enable()
        end
        return r
    end

    -- 2. Populate official refreshRateSpinner with merged monitor Hz + high-FPS presets + Unlimited
    self.UpdateRefreshRatesSpinner = function(scr)
        local target = scr.working.refreshrate
        if target == nil then target = current_target_fps end
        local opts = BuildMergedRefreshOptions(scr, target)
        scr.refreshRateSpinner:SetOptions(opts)
        local selected = 1
        for idx, item in ipairs(opts) do
            if item.data == target then
                selected = idx
                break
            end
        end
        scr.refreshRateSpinner:SetSelectedIndex(selected)
        scr.working.refreshrate = opts[selected].data
    end

    -- 3. Fix Klei's IsGraphicsDirty() refreshrate bug while avoiding monitor flicker in Windowed mode
    local orig_IsGraphicsDirty = self.IsGraphicsDirty
    self.IsGraphicsDirty = function(scr, ...)
        if orig_IsGraphicsDirty(scr, ...) then
            return true
        end
        if scr.working.fullscreen then
            return PickSafeHardwareHz(scr, scr.working.refreshrate) ~= PickSafeHardwareHz(scr, scr.options.refreshrate)
        end
        return false
    end

    -- 4. Guard ChangeGraphicsMode() so 0 (Unlimited) or >panel Hz safely selects highest valid monitor Hz
    local orig_ChangeGraphicsMode = self.ChangeGraphicsMode
    self.ChangeGraphicsMode = function(scr, ...)
        local saved_fps = scr.working.refreshrate
        scr.working.refreshrate = PickSafeHardwareHz(scr, saved_fps)
        local r = orig_ChangeGraphicsMode(scr, ...)
        scr.working.refreshrate = saved_fps
        return r
    end

    -- 5. Add only the 2 truly new visual toggles into right-column empty rows 6 & 7 (below Dynamic Tree Shadows)
    local function CreateNativeGraphicsSpinner(labeltext, spinnerdata, tooltip_text)
        local w = TEMPLATES.LabelSpinner(labeltext, spinnerdata, 200, 220, 36, 5, nil, nil, -50, nil, nil, tooltip_text)
        w.bg = w:AddChild(TEMPLATES.ListItemBackground(200 + 220 + 5 + 15, 36 + 5))
        w.bg:SetPosition(-40, 0)
        w.bg:MoveToBack()
        return w.spinner
    end

    local function FindGraphicsTooltipWidgets(scr)
        local root = scr.grid_graphics and scr.grid_graphics.parent
        if not root or not root.children then return nil, nil end
        local tip_txt, tip_div = nil, nil
        for child in pairs(root.children) do
            if child ~= scr.grid_graphics then
                if child.SetString and child.EnableWordWrap then
                    tip_txt = child
                elseif child.SetTexture then
                    tip_div = child
                end
            end
        end
        return tip_txt, tip_div
    end

    local function AttachTooltip(widget, tooltip, divider)
        if not widget or not tooltip then return end
        local function ongain()
            if widget.tooltip_text ~= nil then
                tooltip:SetString(widget.tooltip_text)
                if divider then divider:Show() end
            end
        end
        local function onlose()
            if widget.parent and not widget.parent.focus then
                tooltip:SetString("")
                if divider then divider:Hide() end
            end
        end
        if widget.bg then
            widget.bg.ongainfocus = ongain
            widget.bg.onlosefocus = onlose
        end
        if widget.spinner then
            widget.spinner.ongainfocusfn = ongain
            widget.spinner.onlosefocusfn = onlose
        end
    end

    local function BindPendingHighlight(spinner)
        if not spinner or not spinner.GetSelectedIndex then return end
        spinner.default_index = spinner:GetSelectedIndex()
        spinner:EnablePendingModificationBackground()
        local orig_cb = spinner.OnChanged
        spinner.OnChanged = function(sp, data)
            if orig_cb then orig_cb(sp, data) end
            spinner:SetHasModification(spinner:GetSelectedIndex() ~= spinner.default_index)
        end
    end

    -- Real Klei Grid uses `.rows` (not `.num_rows`, which only FillGrid sets!).
    -- Right column has 5 stock items + 3 HyperSmooth spinners = exact 8 rows (zero overflow!).
    local grid = self.grid_graphics
    local grid_rows = grid and (grid.rows or grid.num_rows) or 0
    if grid and self.right_spinners_graphics and grid_rows > 0
        and (#self.right_spinners_graphics + 2) <= grid_rows then
        local toggle_opts = {
            { text = disabled_str, data = false },
            { text = enabled_str, data = true },
        }
        local tip_txt, tip_div = FindGraphicsTooltipWidgets(self)

        local skel_label = is_zh and "Interpolação 240 FPS" or "Interpolação 240 FPS"
        local skel_tip = is_zh
            and (has_dll and "Ativa a interpolação de animações 2D do mundo, efeitos e interface (dinput8.dll detectada; aplicação em tempo real)."
                         or "Requer o complemento nativo bin64/dinput8.dll.")
            or (has_dll and "Ativa a interpolação de animações 2D do mundo, efeitos e interface (dinput8.dll detectada; aplicação em tempo real)."
                        or "Requer o complemento nativo bin64/dinput8.dll.")
        self.hcSkeletalSpinner = CreateNativeGraphicsSpinner(skel_label, toggle_opts, skel_tip)
        self.hcSkeletalSpinner.OnChanged = function(_, data)
            self.working.hc_skeletal = data
            self:UpdateMenu()
        end

        local hud_label = is_zh and "Exibição de FPS" or "Exibição de FPS"
        local hud_tip = is_zh
            and "Mostra FPS e tempo por quadro (ms) no canto superior direito."
            or "Mostra FPS e tempo por quadro (ms) no canto superior direito."
        self.hcHudSpinner = CreateNativeGraphicsSpinner(hud_label, toggle_opts, hud_tip)
        self.hcHudSpinner.OnChanged = function(_, data)
            self.working.hc_show_hud = data
            self:UpdateMenu()
        end

        local r1 = #self.right_spinners_graphics + 1
        table.insert(self.right_spinners_graphics, self.hcSkeletalSpinner)
        grid:AddItem(self.hcSkeletalSpinner.parent, 2, r1)
        AttachTooltip(self.hcSkeletalSpinner.parent, tip_txt, tip_div)

        local r2 = #self.right_spinners_graphics + 1
        table.insert(self.right_spinners_graphics, self.hcHudSpinner)
        grid:AddItem(self.hcHudSpinner.parent, 2, r2)
        AttachTooltip(self.hcHudSpinner.parent, tip_txt, tip_div)

        self.hcSkeletalSpinner:SetSelectedIndex(self.working.hc_skeletal and 2 or 1)
        self.hcHudSpinner:SetSelectedIndex(self.working.hc_show_hud and 2 or 1)
        BindPendingHighlight(self.hcSkeletalSpinner)
        BindPendingHighlight(self.hcHudSpinner)

        -- Right-column row 8: Player-First Visual Fidelity Preset (Default: Vanilla Pure)
        if (#self.right_spinners_graphics + 1) <= grid_rows then
            local vis_opts = is_zh and {
                { text = "Original", data = 0 },
                { text = "HD confortável", data = 1 },
                { text = "Ilustração suave", data = 2 },
            } or {
                { text = "Original", data = 0 },
                { text = "HD confortável", data = 1 },
                { text = "Ilustração suave", data = 2 },
            }
            if EncodeCustomVisMask(custom_vis_flags) > 0 or self.working.hc_visual == 3 then
                vis_opts[#vis_opts + 1] = is_zh and { text = "Personalizado", data = 3 } or { text = "Personalizado", data = 3 }
            end
            local vis_label = is_zh and "Qualidade visual" or "Qualidade visual"
            local vis_tip = is_zh
                and (has_dll and "Visual original por padrão. HD confortável oferece AF 16x, iluminação 1.0x, nitidez suave e sombras de contato. Personalize no mod ou via c_hsopt()."
                             or "Visual original por padrão. Ativar oferece nitidez suave e redução de faixas escuras. Instale a DLL para AF 16x, iluminação completa e sombras.")
                or (has_dll and "Visual original por padrão. HD confortável oferece AF 16x, iluminação 1.0x, nitidez suave e sombras de contato. Personalize no mod ou via c_hsopt()."
                            or "Visual original por padrão. Ativar oferece nitidez suave e redução de faixas escuras. Instale a DLL para AF 16x, iluminação completa e sombras.")
            self.hcVisualSpinner = CreateNativeGraphicsSpinner(vis_label, vis_opts, vis_tip)
            self.hcVisualSpinner.OnChanged = function(_, data)
                self.working.hc_visual = data
                self:UpdateMenu()
            end
            local r3 = #self.right_spinners_graphics + 1
            table.insert(self.right_spinners_graphics, self.hcVisualSpinner)
            grid:AddItem(self.hcVisualSpinner.parent, 2, r3)
            AttachTooltip(self.hcVisualSpinner.parent, tip_txt, tip_div)
            local vidx = (self.working.hc_visual or 0) + 1
            if vidx < 1 or vidx > #vis_opts then vidx = 1 end
            self.hcVisualSpinner:SetSelectedIndex(vidx)
            BindPendingHighlight(self.hcVisualSpinner)
        end
    end

    -- 6. Sync on InitializeSpinners (handles RevertChanges cleanly)
    local orig_InitializeSpinners = self.InitializeSpinners
    self.InitializeSpinners = function(scr, first, ...)
        local r = orig_InitializeSpinners(scr, first, ...)
        if scr.refreshRateSpinner then
            scr.refreshRateSpinner:SetHasModification(false)
        end
        if scr.hcSkeletalSpinner then
            scr.hcSkeletalSpinner:SetSelectedIndex(scr.working.hc_skeletal and 2 or 1)
            scr.hcSkeletalSpinner:SetHasModification(false)
        end
        if scr.hcHudSpinner then
            scr.hcHudSpinner:SetSelectedIndex(scr.working.hc_show_hud and 2 or 1)
            scr.hcHudSpinner:SetHasModification(false)
        end
        if scr.hcVisualSpinner then
            local opts = scr.hcVisualSpinner.options
            local max_i = (type(opts) == "table" and #opts) or 3
            local vidx = (scr.working.hc_visual or 0) + 1
            if vidx < 1 or vidx > max_i then vidx = 1 end
            scr.hcVisualSpinner:SetSelectedIndex(vidx)
            scr.hcVisualSpinner:SetHasModification(false)
        end
        return r
    end

    -- 7. Sync live engine & persist on Apply / Save
    local orig_Apply = self.Apply
    self.Apply = function(scr, ...)
        local r = orig_Apply(scr, ...)
        if scr.working.refreshrate ~= nil then
            current_target_fps = scr.working.refreshrate
        end
        if scr.working.hc_skeletal ~= nil then
            current_skeletal_tween = scr.working.hc_skeletal and true or false
        end
        if scr.working.hc_show_hud ~= nil then
            current_show_fps_hud = scr.working.hc_show_hud and true or false
        end
        if scr.working.hc_visual ~= nil then
            if scr.working.hc_visual ~= current_visual_preset then
                visual_bench_timer = 15.0
            end
            current_visual_preset = scr.working.hc_visual
        end
        SyncToNativePlugin(true)
        return r
    end

    local orig_Save = self.Save
    self.Save = function(scr, cb, ...)
        return orig_Save(scr, function(...)
            if scr.refreshRateSpinner then
                scr.refreshRateSpinner.default_index = scr.refreshRateSpinner:GetSelectedIndex()
                scr.refreshRateSpinner:SetHasModification(false)
            end
            if scr.hcSkeletalSpinner then
                scr.hcSkeletalSpinner.default_index = scr.hcSkeletalSpinner:GetSelectedIndex()
                scr.hcSkeletalSpinner:SetHasModification(false)
            end
            if scr.hcHudSpinner then
                scr.hcHudSpinner.default_index = scr.hcHudSpinner:GetSelectedIndex()
                scr.hcHudSpinner:SetHasModification(false)
            end
            if scr.hcVisualSpinner then
                scr.hcVisualSpinner.default_index = scr.hcVisualSpinner:GetSelectedIndex()
                scr.hcVisualSpinner:SetHasModification(false)
            end
            if cb then cb(...) end
        end, ...)
    end

    -- Initialize official Refresh Rate spinner state right now (no false yellow highlight on open!)
    self:UpdateResolutionsSpinner()
    self:UpdateRefreshRatesSpinner()
    self.refreshRateSpinner.default_index = self.refreshRateSpinner:GetSelectedIndex()
    self.refreshRateSpinner:SetHasModification(false)
    self:UpdateMenu()
end)

--------------------------------------------------------------------------------
-- 9. Route B: Auto-Negotiated Opt-In 60Hz SimTick Handshake (v2.4.0)
--    100% passive on ALL vanilla/public servers (dinput8.dll unconditionally
--    resets Client SimTick to 30Hz on every VM/menu/server transition!).
--    Activates 60Hz ONLY when connected to a DST HyperCore Server v1.2.0+
--    with opt_sim_60hz enabled AND user has auto_60hz_sim = true.
--------------------------------------------------------------------------------
local toast_timer = 0
local toast_msg = nil
local active_sim_tick_hz = 30

local function TryActivate60HzSim(source_label)
    if not AUTO_60HZ_SIM or active_sim_tick_hz == 60 then
        return
    end
    local fnSetSim = rawget(GLOBAL, "HyperSmooth_SetSimTickRate")
    if type(fnSetSim) ~= "function" then
        return
    end
    local ok, applied = pcall(fnSetSim, 60)
    if ok and applied then
        active_sim_tick_hz = 60
        -- Override GetTime / GetStaticTime dynamically so Lua never reads stale 1/30 upvalues
        rawset(GLOBAL, "GetTime", function()
            return TheSim:GetTick() * TheSim:GetTickTime()
        end)
        rawset(GLOBAL, "GetStaticTime", function()
            return TheSim:GetStaticTick() * TheSim:GetTickTime()
        end)
        toast_msg = "Simulação HyperCore a 60 Hz ativa"
        toast_timer = 4.0
        hud_dirty_now = true
        if GLOBAL.print then
            GLOBAL.print(string.format("[Desbloquear QPS] Auto-negotiated 60Hz SimTick via %s (GetTickTime=%.6f)",
                tostring(source_label), TheSim:GetTickTime()))
        end
    end
end

-- Channel 1: ClientModRPC("HyperCoreProto", "SimTickRate") without duplicating slot id if co-loaded
local function OnSimTickRateRpc(hz)
    if hz == 60 then
        TryActivate60HzSim("ClientModRPC")
    end
end
if type(AddClientModRPCHandler) == "function" then
    -- NOTE: Klei's GetClientModRPC(ns, name) does NOT nil-check CLIENT_MOD_RPC[ns]!
    -- Always inspect GLOBAL.CLIENT_MOD_RPC directly before registering.
    local rpc_tbl = rawget(GLOBAL, "CLIENT_MOD_RPC")
    local rpc_ns = type(rpc_tbl) == "table" and rpc_tbl["HyperCoreProto"] or nil
    local existing_rpc = type(rpc_ns) == "table" and rpc_ns["SimTickRate"] or nil
    if existing_rpc == nil then
        AddClientModRPCHandler("HyperCoreProto", "SimTickRate", OnSimTickRateRpc)
    else
        local handlers_tbl = rawget(GLOBAL, "CLIENT_MOD_RPC_HANDLERS")
        local handlers_ns = type(handlers_tbl) == "table" and handlers_tbl["HyperCoreProto"] or nil
        if type(handlers_ns) == "table" and existing_rpc.id ~= nil then
            local prev_fn = handlers_ns[existing_rpc.id]
            handlers_ns[existing_rpc.id] = function(hz, ...)
                if type(prev_fn) == "function" then pcall(prev_fn, hz, ...) end
                OnSimTickRateRpc(hz)
            end
        end
    end
end

-- Channel 2: Replicated "hypercore_sim60" tag on world_network prefabs (zero RPC dependency!)
for _, net_prefab in ipairs({ "forest_network", "cave_network", "lavaarena_network", "quagmire_network" }) do
    AddPrefabPostInit(net_prefab, function(inst)
        if not AUTO_60HZ_SIM then return end
        if inst and inst.HasTag and inst:HasTag("hypercore_sim60") then
            TryActivate60HzSim("WorldNetTag")
        elseif inst and inst.DoTaskInTime then
            inst:DoTaskInTime(0.25, function(net_inst)
                if net_inst and net_inst:IsValid() and net_inst:HasTag("hypercore_sim60") then
                    TryActivate60HzSim("WorldNetTag")
                end
            end)
        end
    end)
end

AddSimPostInit(function()
    if not AUTO_60HZ_SIM then return end
    local w = GLOBAL.TheWorld
    if w ~= nil then
        if (w.HasTag and w:HasTag("hypercore_sim60")) or (w.net and w.net.HasTag and w.net:HasTag("hypercore_sim60")) then
            TryActivate60HzSim("SimPostInit")
        end
    end
end)

--------------------------------------------------------------------------------
-- 9b. 240Hz Immediate WASD RPC Dispatch (Lag Compensation OFF Zero-Wait Input)
--     Vanilla PlayerController:DoDirectWalking only polls WASD inside OnUpdate
--     (once per SimTick: 0-33.3ms stall on 30Hz servers, 0-16.7ms on 60Hz).
--     When Lag Comp is OFF (self.locomotor == nil on remote client), dispatching
--     RemoteDirectWalking / RemoteStopWalking directly on the 240Hz OnControl
--     edge cuts 8-33ms of input wait with ZERO duplicate RPCs (self.remote_vector
--     deduplicates) and 100% vanilla-server compatibility.
--------------------------------------------------------------------------------
if type(AddComponentPostInit) == "function" then
    AddComponentPostInit("playercontroller", function(pc)
        if type(pc) ~= "table" or type(pc.OnControl) ~= "function" then
            return
        end
        local MOVE_UP    = rawget(GLOBAL, "CONTROL_MOVE_UP")
        local MOVE_DOWN  = rawget(GLOBAL, "CONTROL_MOVE_DOWN")
        local MOVE_LEFT  = rawget(GLOBAL, "CONTROL_MOVE_LEFT")
        local MOVE_RIGHT = rawget(GLOBAL, "CONTROL_MOVE_RIGHT")
        local CTRL_ATK   = rawget(GLOBAL, "CONTROL_CONTROLLER_ATTACK")
        if not (MOVE_UP and MOVE_DOWN and MOVE_LEFT and MOVE_RIGHT) then
            return
        end

        local orig_OnControl = pc.OnControl
        pc.OnControl = function(self, control, down, analog, ...)
            local ret = orig_OnControl(self, control, down, analog, ...)
            if ret == true then
                return ret
            end
            if control ~= MOVE_UP and control ~= MOVE_DOWN and control ~= MOVE_LEFT and control ~= MOVE_RIGHT then
                return ret
            end
            -- Strictly remote client with Lag Compensation OFF (locomotor == nil)
            if self.ismastersim or self.locomotor ~= nil then
                return ret
            end
            if (GLOBAL.IsPaused and GLOBAL.IsPaused()) or self.handler == nil then
                return ret
            end
            local inst = self.inst
            if inst == nil or inst ~= GLOBAL.ThePlayer or (inst.IsValid and not inst:IsValid()) then
                return ret
            end
            -- Preserve full analog stick precision for gamepads (handled natively in OnUpdate)
            if TheInput.ControllerAttached and TheInput:ControllerAttached() then
                return ret
            end
            local isenabled, ishudblocking = false, false
            if self.IsEnabled then
                isenabled, ishudblocking = self:IsEnabled()
            end
            if not isenabled and not ishudblocking then
                return ret
            end
            if self.dragwalking or self.draggingonground then
                return ret
            end
            if self.IsLocalOrRemoteHopping and self:IsLocalOrRemoteHopping() then
                return ret
            end
            if self.recent_bufferedaction ~= nil and self.recent_bufferedaction.act ~= nil then
                return ret
            end
            local bcu = inst.components and inst.components.boatcannonuser or nil
            if (bcu ~= nil and bcu.GetCannon and bcu:GetCannon() ~= nil)
                or (inst.HasTag and (inst:HasTag("steeringboat") or inst:HasTag("rotatingboat"))) then
                return ret
            end

            local trigVal = (type(analog) == "number" and analog) or (down and 1 or 0)
            local vR = (control == MOVE_RIGHT) and trigVal or (TheInput:GetAnalogControlValue(MOVE_RIGHT) or 0)
            local vL = (control == MOVE_LEFT)  and trigVal or (TheInput:GetAnalogControlValue(MOVE_LEFT) or 0)
            local vU = (control == MOVE_UP)    and trigVal or (TheInput:GetAnalogControlValue(MOVE_UP) or 0)
            local vD = (control == MOVE_DOWN)  and trigVal or (TheInput:GetAnalogControlValue(MOVE_DOWN) or 0)
            local xdir = vR - vL
            local ydir = vU - vD
            local deadzone = (GLOBAL.TUNING and GLOBAL.TUNING.CONTROLLER_DEADZONE_RADIUS) or 0.3

            if math.abs(xdir) >= deadzone or math.abs(ydir) >= deadzone then
                if self.IsBusy and self:IsBusy() then
                    return ret
                end
                if self.controller_attack_override ~= nil then
                    return ret
                end
                if CTRL_ATK and inst.sg ~= nil and inst.sg:HasStateTag("attack") and self:IsControlPressed(CTRL_ATK) then
                    return ret
                end
                local cam = GLOBAL.TheCamera
                if cam and cam.GetRightVec and cam.GetDownVec and type(self.RemoteDirectWalking) == "function" then
                    local dir = (cam:GetRightVec() * xdir - cam:GetDownVec() * ydir):GetNormalized()
                    if dir.x == dir.x and dir.z == dir.z then
                        if inst.ClearBufferedAction then inst:ClearBufferedAction() end
                        if self.CooldownRemoteController then self:CooldownRemoteController() end
                        if not self.directwalking then
                            self.time_direct_walking = 0
                            self.directwalking = true
                            self.dragwalking = false
                            self.predictwalking = false
                        end
                        self:RemoteDirectWalking(dir.x, dir.z)
                    end
                end
            elseif self.directwalking and type(self.RemoteStopWalking) == "function" then
                self.directwalking = false
                self.dragwalking = false
                self.predictwalking = false
                if self.CooldownRemoteController then self:CooldownRemoteController() end
                self:RemoteStopWalking()
            end
            return ret
        end
    end)
end

--------------------------------------------------------------------------------
-- 10. Lightweight Zero-Churn FPS + 1% Low + P99 HUD & Optional Custom Hotkeys
--------------------------------------------------------------------------------
local function FormatTargetLabel(fps)
    if fps == 0 then
        return "SEM LIMITE"
    end
    return tostring(fps) .. " FPS"
end

local function CanTriggerInGameHotkey()
    local player = GLOBAL.ThePlayer
    local fe = GLOBAL.TheFrontEnd
    if not player or not fe then
        return false
    end
    local screen = fe:GetActiveScreen()
    if not screen or (screen.name ~= "HUD" and screen.name ~= "MapScreen") then
        return false
    end
    local hud = player.HUD
    if hud then
        if hud.IsChatInputScreenOpen and hud:IsChatInputScreenOpen() then return false end
        if hud.IsConsoleScreenOpen and hud:IsConsoleScreenOpen() then return false end
    end
    return true
end

AddClassPostConstruct("screens/playerhud", function(self)
    -- Re-sync on entering world so any session reload matches active config immediately
    SyncToNativePlugin(false)

    local txt = self:AddChild(Text(GLOBAL.NUMBERFONT, 22, ""))
    txt:SetHAnchor(GLOBAL.ANCHOR_RIGHT)
    txt:SetVAnchor(GLOBAL.ANCHOR_TOP)
    txt:SetRegionSize(1160, 30)
    txt:SetHAlign(GLOBAL.ANCHOR_RIGHT)
    txt:SetPosition(-735, -18, 0) -- right edge @ -155px: completely clear of the Day Clock!
    txt:SetColour(0.55, 1.0, 0.65, 0.92)
    txt:SetClickable(false)
    if not current_show_fps_hud then
        txt:Hide()
    end
    fps_hud_text = txt

    local accum_time = 0
    local accum_frames = 0
    local hd2d_accum = 0
    local last_real_fps = 0
    local last_ms = 0
    local old_OnUpdate = self.OnUpdate

    self.OnUpdate = function(hud, dt)
        if old_OnUpdate then
            old_OnUpdate(hud, dt)
        end
        if dt and dt > 0 and dt < 1.0 then
            hd2d_accum = hd2d_accum + dt
            if hd2d_accum >= 0.10 then
                PushHd2dEnvToNative(hd2d_accum)
                hd2d_accum = 0
            end
        end
        if not (fps_hud_text and fps_hud_text.inst and fps_hud_text.inst:IsValid()) then
            return
        end
        if dt and dt > 0 and dt < 1.0 and (current_show_fps_hud or toast_timer > 0) then
            accum_time = accum_time + dt
            accum_frames = accum_frames + 1
        end
        if toast_timer > 0 then
            toast_timer = toast_timer - (dt or 0)
            if toast_timer <= 0 and not current_show_fps_hud then
                fps_hud_text:Hide()
            end
        end
        if visual_bench_timer > 0 then
            visual_bench_timer = visual_bench_timer - (dt or 0)
        end
        -- Hidden HUD: do not poll native telemetry, format strings or allocate
        -- temporary tables. Drop old samples so toggling HUD back on starts fresh.
        if not current_show_fps_hud and toast_timer <= 0 then
            accum_time = 0
            accum_frames = 0
            hud_dirty_now = false
        elseif hud_dirty_now or accum_time >= 0.25 then
            if accum_time > 0 and accum_frames > 0 then
                last_real_fps = accum_frames / accum_time
                last_ms = (accum_time / accum_frames) * 1000.0
                accum_time = 0
                accum_frames = 0
            end
            hud_dirty_now = false

            -- Prefer zero-allocation C++ 512-frame RTSS ring telemetry when available
            local fnStats = rawget(GLOBAL, "HyperSmooth_GetFrameStats")
            local disp_fps = last_real_fps
            local metric_str = nil
            local color_metric = last_real_fps

            if SHOW_1PCT_LOW and type(fnStats) == "function" then
                local ok, avg, low1, p99, _, _, simhz = pcall(fnStats)
                if ok and type(avg) == "number" and avg > 1.0 and type(low1) == "number" and low1 > 1.0 then
                    disp_fps = avg
                    color_metric = low1
                    local badge = (simhz == 60) and " [60Hz]" or ""
                    metric_str = string.format("%.0f FPS | 1%%L %.0f (%.1fms)%s", avg, low1, p99 or last_ms, badge)
                end
            end
            if not metric_str then
                local badge = (active_sim_tick_hz == 60) and " [60Hz]" or ""
                metric_str = string.format("%.0f FPS (%.1fms)%s", disp_fps, last_ms, badge)
            end

            -- Append compact GPU/Busy/VRAM telemetry for 12s after visual switch or when pinned via c_hsbench()
            if visual_bench_timer > 0 or visual_bench_pinned then
                local fnPerf = rawget(GLOBAL, "HyperSmooth_GetVisualPerf")
                if type(fnPerf) == "function" then
                    local okP, _, _, _, wMs, _, bMs, _, vCur = pcall(fnPerf)
                    if okP then
                        local tag = VISUAL_HUD_MODE_TAGS[current_visual_preset] or "Original"
                        local vram_part = (type(vCur) == "number" and vCur > 0.5)
                            and string.format(" %.0fMB", vCur) or ""
                        metric_str = metric_str .. string.format(
                            " | %s %.1fms (W%.1f)%s",
                            tag, bMs or 0, wMs or 0, vram_part)
                    end
                end
            end

            if toast_timer > 0 and toast_msg then
                if not current_show_fps_hud then
                    fps_hud_text:Show()
                    fps_hud_text:SetString(toast_msg)
                else
                    fps_hud_text:SetString(metric_str .. " | " .. toast_msg)
                end
            elseif current_show_fps_hud then
                fps_hud_text:Show()
                fps_hud_text:SetString(metric_str)
            end

            if color_metric >= 95 or (disp_fps >= 110 and color_metric >= disp_fps * 0.72) then
                fps_hud_text:SetColour(0.45, 1.0, 0.65, 0.92)
            elseif color_metric >= 52 then
                fps_hud_text:SetColour(1.0, 0.92, 0.45, 0.92)
            else
                fps_hud_text:SetColour(1.0, 0.45, 0.45, 0.92)
            end
        end
    end
end)

-- Live Any-Key & Mouse-Button Rebind Engine (wired by keybind.lua in Mod Config & ESC->Settings->Controls)
local HOTKEY_ACTIONS = {
    hotkey_cycle = function()
        current_target_fps = NextFpsPreset(current_target_fps)
        SyncToNativePlugin(true)
        if HasNativePlugin() then
            toast_msg = "FPS alvo: " .. FormatTargetLabel(current_target_fps)
        else
            toast_msg = "FPS alvo: " .. FormatTargetLabel(current_target_fps) .. " (requer bin64/dinput8.dll)"
        end
        toast_timer = 3.0
        hud_dirty_now = true
    end,
    hotkey_skeletal = function()
        current_skeletal_tween = not current_skeletal_tween
        SyncToNativePlugin(true)
        if HasNativePlugin() then
            toast_msg = "Interpolação 240 FPS: " .. (current_skeletal_tween and "Ativado" or "Desativado")
        else
            toast_msg = "Interpolação 240 FPS: " .. (current_skeletal_tween and "Ativado" or "Desativado") .. " (requer bin64/dinput8.dll)"
        end
        toast_timer = 3.0
        hud_dirty_now = true
    end,
    hotkey_hud = function()
        current_show_fps_hud = not current_show_fps_hud
        SyncToNativePlugin(true)
        toast_msg = "HUD de FPS: " .. (current_show_fps_hud and "Ativado" or "Desativado")
        toast_timer = 2.0
        hud_dirty_now = true
    end,
    hotkey_visual = function()
        local has_custom = EncodeCustomVisMask(custom_vis_flags) > 0
        local cycle_n = has_custom and 4 or 3
        current_visual_preset = (current_visual_preset + 1) % cycle_n
        visual_bench_timer = 12.0
        SyncToNativePlugin(true)
        local labels = {
            [0] = "Visual: Original (desativado)",
            [1] = "Visual: HD confortável",
            [2] = "Visual: Ilustração suave",
            [3] = "Visual: Personalizado",
        }
        toast_msg = labels[current_visual_preset] or ("Visual: " .. tostring(current_visual_preset))
        toast_timer = 2.5
        hud_dirty_now = true
    end,
}

local active_key_handlers = {}

function HS_ApplyKeyBind(action_name, keycode)
    local prev = active_key_handlers[action_name]
    if prev and prev.Remove then
        prev:Remove()
    end
    active_key_handlers[action_name] = nil

    local action_fn = HOTKEY_ACTIONS[action_name]
    if type(action_fn) ~= "function" or type(keycode) ~= "number" or not TheInput then
        return
    end
    if keycode >= 1000 then
        if TheInput.AddMouseButtonHandler then
            active_key_handlers[action_name] = TheInput:AddMouseButtonHandler(function(btn, down)
                if btn == keycode and down and CanTriggerInGameHotkey() then
                    action_fn()
                end
            end)
        end
    else
        if TheInput.AddKeyUpHandler then
            active_key_handlers[action_name] = TheInput:AddKeyUpHandler(keycode, function()
                if CanTriggerInGameHotkey() then
                    action_fn()
                end
            end)
        end
    end
end

if type(modimport) == "function" then
    pcall(modimport, "keybind")
end

-- QPS_TERRAIN_BEGIN
-- Experimental: only passive tile markers from Geometric Placement 3.2.0.
-- The active cursor, snapping, validation and network actions remain upstream.
do
    if GetModConfigData("terrain_grid_pool") == true then
        local debuglib = rawget(GLOBAL, "debug")
        local index = GLOBAL.KnownModIndex
        local function FromGP(fn)
            if type(fn) ~= "function" or type(debuglib) ~= "table"
                or type(debuglib.getinfo) ~= "function" then return false end
            local ok, info = pcall(debuglib.getinfo, fn, "S")
            local src = ok and info and info.source
            if type(src) ~= "string" then return false end
            src = src:gsub("\\", "/")
            return src:find("workshop-351325790/modmain.lua", 1, true) ~= nil
                or src:find("/322330/351325790/modmain.lua", 1, true) ~= nil
        end

        local LIMIT, TTL, BATCH = 121, 5, 8
        local pool, owner, cleanup = {}, nil, nil
        local function ClearWorld()
            if cleanup then cleanup:Cancel(); cleanup = nil end
            pool, owner = {}, nil
        end
        local function World()
            local w = GLOBAL.TheWorld
            if not w or not w:IsValid() then return nil end
            if w ~= owner then
                ClearWorld()
                owner = w
                w:ListenForEvent("onremove", function()
                    if owner == w then ClearWorld() end
                end)
            end
            return w
        end
        local function Drain()
            cleanup = nil
            for _ = 1, BATCH do
                local ent = table.remove(pool)
                if not ent then break end
                if ent:IsValid() then ent:Remove() end
            end
            if #pool > 0 and owner and owner:IsValid() then
                cleanup = owner:DoTaskInTime(0.1, Drain)
            end
        end
        local function Eligible(self)
            return self.inst and self.inst.prefab == "gridplacer"
                and self.snap_to_tile == true and self.placertype == "gridplacer"
                and self.placeTestFn == nil and self.override_testfn == nil
                and not self.axisalignedplacement and not self.snap_to_boat_edge
        end
        local function Passive(ent, self)
            local c = ent and ent.components and ent.components.placer
            return ent and ent ~= self.inst and ent ~= self.gridinst
                and ent ~= self.tileinst and ent:IsValid()
                and ent.prefab == "gridplacer" and ent.persists == false
                and ent._geo_replaced_anim == true and ent:HasTag("NOCLICK")
                and c and c.builder == nil and c.snap_to_tile == true
        end
        AddPrefabPostInit("gridplacer", function(inst)
            local self = inst.components and inst.components.placer
            if not self or self._qps_terrain_pool then return end
            local oldbuild, oldremove = self.BuildGridPoint, self.RemoveBuildGrid
            if not FromGP(oldbuild) or not FromGP(oldremove)
                or not FromGP(self.OnUpdate) or not FromGP(self.RefreshGridPoint)
                or not index or type(index.GetModInfo) ~= "function" then return end
            local ok, info = pcall(index.GetModInfo, index, "workshop-351325790")
            if not ok or type(info) ~= "table" or info.version ~= "3.2.0" then return end
            self._qps_terrain_pool = true
            self.BuildGridPoint = function(cmp, x, z, pt, ent)
                if ent == nil and Eligible(cmp) and World() then
                    while #pool > 0 and ent == nil do
                        local candidate = table.remove(pool)
                        if Passive(candidate, cmp) then
                            ent = candidate
                            ent.Transform:SetRotation(cmp.geometry.gridplacer_rotation)
                        elseif candidate:IsValid() then candidate:Remove() end
                    end
                end
                return oldbuild(cmp, x, z, pt, ent)
            end
            self.RemoveBuildGrid = function(cmp, ...)
                if Eligible(cmp) and cmp.build_grid and cmp.build_grid_positions
                    and World() then
                    for x, row in pairs(cmp.build_grid) do
                        for z, ent in pairs(row) do
                            if #pool < LIMIT and Passive(ent, cmp) then
                                ent:Hide()
                                pool[#pool + 1] = ent
                                row[z] = nil
                                cmp.build_grid_positions[x][z] = nil
                            end
                        end
                    end
                    if #pool > 0 and not cleanup then
                        cleanup = owner:DoTaskInTime(TTL, Drain)
                    end
                end
                return oldremove(cmp, ...)
            end
        end)
    end
end
-- QPS_TERRAIN_END
