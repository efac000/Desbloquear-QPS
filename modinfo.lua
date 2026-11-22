name = "Desbloquear QPS"
description = [[
Desbloquear QPS — FPS livre e carregamento rápido.
Interpolação, câmera e menus fluidos; otimizações de desempenho.
Para liberar FPS acima de 60, instale a DLL incluída em bin64.
Mod de cliente, sem exigir o HyperSmooth antigo ou instalação no servidor.
]]
author = "café"
version = "1.0.0"

api_version = 10
dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false

client_only_mod = true
all_clients_require_mod = false

icon_atlas = "modicon.xml"
icon = "modicon.tex"

-- NOTE: Klei executes modinfo.lua in a bare sandbox (no ipairs/pairs/string/table globals).
-- Use pure numeric `for i = 1, #t` loops and literal tables only!
keys_placeholder = {
    {
        description = "Ative e aplique",
        hover = "Ative e aplique o mod. Depois, clique no atalho para escolher a tecla.",
        data = "KEY_DISABLED",
    },
}

local keyboard_rows = {
    { "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12", "Print", "ScrolLock", "Pause" },
    { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" },
    { "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M" },
    { "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z" },
    { "Tab", "CapsLock", "LShift", "LCtrl", "LAlt", "Space", "RAlt", "RCtrl", "RShift", "Enter", "Backspace" },
    { "BackQuote", "Minus", "Equals", "LeftBracket", "RightBracket", "Backslash", "Semicolon", "Quote", "Period", "Slash" },
    { "Up", "Down", "Left", "Right", "Insert", "Delete", "Home", "End", "PageUp", "PageDown" },
}
local numpad_keys = { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "Period", "Divide", "Multiply", "Minus", "Plus" }
local mouse_keys = { "\238\132\130", "\238\132\131", "\238\132\132" } -- Botão central do mouse, botões laterais 4 e 5
local key_disabled = { description = "Desativado", data = "KEY_DISABLED" }
-- Só o texto exibido muda: os códigos das teclas continuam os do DST.
local key_labels_ptbr = {
    Print = "Imprimir tela", ScrolLock = "Bloq. rolagem", Pause = "Pausar",
    Tab = "Tab", CapsLock = "Bloq. maiúsculas",
    LShift = "Shift esquerdo", RShift = "Shift direito",
    LCtrl = "Ctrl esquerdo", RCtrl = "Ctrl direito",
    LAlt = "Alt esquerdo", RAlt = "Alt direito",
    Space = "Espaço", Enter = "Enter", Backspace = "Apagar",
    BackQuote = "Crase", Minus = "Menos", Equals = "Igual",
    LeftBracket = "Colchete esquerdo", RightBracket = "Colchete direito",
    Backslash = "Barra invertida", Semicolon = "Ponto e vírgula",
    Quote = "Apóstrofo", Period = "Ponto", Slash = "Barra",
    Up = "Seta acima", Down = "Seta abaixo",
    Left = "Seta esquerda", Right = "Seta direita",
    Insert = "Inserir", Delete = "Excluir",
    Home = "Início", End = "Fim",
    PageUp = "Página acima", PageDown = "Página abaixo",
}
local numpad_labels_ptbr = {
    Period = "ponto", Divide = "divisão", Multiply = "multiplicação",
    Minus = "menos", Plus = "mais",
}

keys = { key_disabled }
for i = 1, #mouse_keys do
    keys[#keys + 1] = { description = mouse_keys[i], data = mouse_keys[i] }
end
for i = 1, #keyboard_rows do
    local row = keyboard_rows[i]
    for j = 1, #row do
        local k = row[j]
        keys[#keys + 1] = { description = key_labels_ptbr[k] or k, data = "KEY_" .. k:upper() }
    end
end
for i = 1, #numpad_keys do
    local k = numpad_keys[i]
    keys[#keys + 1] = { description = "Teclado numérico " .. (numpad_labels_ptbr[k] or k), data = "KEY_KP_" .. k:upper() }
end

configuration_options = {
    {
        name = "target_fps",
        label = "Limite de FPS",
        hover = "Requer dinput8.dll para passar de 60 FPS. Altere também em Vídeo.",
        options = {
            { description = "60 FPS", data = 60 },
            { description = "120 FPS", data = 120 },
            { description = "144 FPS", data = 144 },
            { description = "165 FPS", data = 165 },
            { description = "240 FPS", data = 240 },
            { description = "360 FPS", data = 360 },
            { description = "Sem limite", data = 0 },
        },
        default = 240,
    },
    {
        name = "visual_preset",
        label = "Perfil visual",
        hover = "Original por padrão. Outros perfis aplicam efeitos opcionais.",
        options = {
            { description = "Original", data = 0 },
            { description = "HD confortável", data = 1 },
            { description = "Ilustração suave", data = 2 },
            { description = "Personalizado", data = 3 },
        },
        default = 0,
    },
    {
        name = "visual_af16",
        label = "Filtro 16x",
        hover = "Requer DLL. Deixa pisos e objetos inclinados mais nítidos.",
        options = {
            { description = "Desativado", data = false },
            { description = "16x AF", data = true },
        },
        default = false,
    },
    {
        name = "visual_full_lightmap",
        label = "Iluminação",
        hover = "Requer DLL. Melhora a definição dos efeitos de iluminação.",
        options = {
            { description = "Desativado", data = false },
            { description = "Ativado", data = true },
        },
        default = false,
    },
    {
        name = "visual_cas",
        label = "Nitidez",
        hover = "Aplica nitidez leve e reduz faixas de cor em cenas escuras.",
        options = {
            { description = "Desativado", data = false },
            { description = "Ativado", data = true },
        },
        default = false,
    },
    {
        name = "visual_contact_ao",
        label = "Sombras suaves",
        hover = "Requer DLL. Sombras suaves no chão e menos brilho excessivo.",
        options = {
            { description = "Desativado", data = false },
            { description = "Ativado", data = true },
        },
        default = false,
    },
    {
        name = "visual_calm_env",
        label = "Litoral e chuva",
        hover = "Requer DLL. Suaviza o litoral e o aspecto do solo molhado.",
        options = {
            { description = "Desativado", data = false },
            { description = "Ativado", data = true },
        },
        default = false,
    },
    {
        name = "visual_soft_bloom",
        label = "Bloom suave",
        hover = "Suaviza o brilho. Só atua se o Bloom do jogo estiver ligado.",
        options = {
            { description = "Desativado", data = false },
            { description = "Ativado", data = true },
        },
        default = false,
    },
    {
        name = "visual_storybook_tone",
        label = "Tons e vinheta",
        hover = "Ajusta levemente os tons médios e as bordas da imagem.",
        options = {
            { description = "Desativado", data = false },
            { description = "Ativado", data = true },
        },
        default = false,
    },
    {
        name = "skeletal_tween",
        label = "Interpolação",
        hover = "Requer DLL. Suaviza animações 2D do mundo e da interface.",
        options = {
            { description = "Ativado", data = true },
            { description = "Desativado", data = false },
        },
        default = true,
    },
    {
        name = "smooth_camera",
        label = "Câmera suave",
        hover = "Corrige a suavização da câmera acima de 60 FPS.",
        options = {
            { description = "Ativado", data = true },
            { description = "Desativado", data = false },
        },
        default = true,
    },
    {
        name = "smooth_ui_240hz",
        label = "Menus e minimapa",
        hover = "Corrige rolagem, zoom e círculos de posicionamento.",
        options = {
            { description = "Ativado", data = true },
            { description = "Desativado", data = false },
        },
        default = true,
    },
    {
        name = "reduce_240hz_churn",
        label = "CPU e memória",
        hover = "Reduz alocações e verificações repetidas a cada quadro.",
        options = {
            { description = "Ativado", data = true },
            { description = "Desativado", data = false },
        },
        default = true,
    },
    {
        name = "keep_shard_assets",
        label = "Carregar cavernas",
        hover = "Reaproveita recursos já carregados. Requer 8 GB de RAM.",
        options = {
            { description = "Ativado", data = true },
            { description = "Desativado", data = false },
        },
        default = true,
    },
    {
        name = "fast_mod_scan",
        label = "Cache de mods",
        hover = "Evita reler informações de mods desativados a cada tela.",
        options = {
            { description = "Ativado", data = true },
            { description = "Desativado", data = false },
        },
        default = true,
    },
    {
        name = "skip_top_mods_query",
        label = "Mods populares",
        hover = "Evita consultas demoradas à lista de mods populares.",
        options = {
            { description = "Ativado", data = true },
            { description = "Desativado", data = false },
        },
        default = true,
    },
    {
        name = "skip_motd_delay",
        label = "Pular anúncios",
        hover = "Usa o cache local dos avisos para evitar esperas.",
        options = {
            { description = "Ativado", data = true },
            { description = "Desativado", data = false },
        },
        default = true,
    },
    {
        name = "show_fps_hud",
        label = "Mostrar FPS",
        hover = "Mostra FPS e tempo por quadro no canto superior direito.",
        options = {
            { description = "Exibir", data = true },
            { description = "Ocultar", data = false },
        },
        default = true,
    },
    {
        name = "show_1pct_low",
        label = "Mostrar 1% Low",
        hover = "Requer DLL. Exibe 1% Low e tempo P99 no HUD.",
        options = {
            { description = "Exibir", data = true },
            { description = "Só FPS", data = false },
        },
        default = true,
    },
    {
        name = "auto_60hz_sim",
        label = "Servidor: 60 Hz",
        hover = "Usa 60 Hz só com HyperCore compatível; outros ficam em 30 Hz.",
        options = {
            { description = "Automático", data = true },
            { description = "30 Hz fixos", data = false },
        },
        default = true,
    },
    {
        name = "hotkey_cycle",
        label = "Tecla: FPS",
        hover = "Grave uma tecla para alternar o limite de FPS.",
        options = keys_placeholder,
        default = "KEY_DISABLED",
    },
    {
        name = "hotkey_skeletal",
        label = "Tecla: interpolação",
        hover = "Grave uma tecla para ligar ou desligar a interpolação.",
        options = keys_placeholder,
        default = "KEY_DISABLED",
    },
    {
        name = "hotkey_hud",
        label = "Tecla: HUD",
        hover = "Grave uma tecla para mostrar ou ocultar o HUD.",
        options = keys_placeholder,
        default = "KEY_DISABLED",
    },
    {
        name = "hotkey_visual",
        label = "Tecla: visual",
        hover = "Grave uma tecla para alternar o perfil gráfico.",
        options = keys_placeholder,
        default = "KEY_DISABLED",
    },
}
