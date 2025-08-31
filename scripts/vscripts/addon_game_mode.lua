-- === addon_game_mode.lua (диагностический загрузчик) ===
if HDDM == nil then HDDM = {} end
local function dbg(msg) print("[HDDM][DBG] " .. tostring(msg)) end

-- Пробуем подгрузить модуль hddm/init.lua и поймать точную ошибку
local ok, mod = pcall(function() return require("hddm.init") end)
if not ok then
  dbg("require FAILED: " .. tostring(mod))
else
  dbg("require OK: hddm.init loaded")
end

function Precache(_) end

function Activate()
  dbg("Activate()")
  if type(HDDM) ~= "table" or type(HDDM.Game) ~= "function" then
    dbg("HDDM.Game not found — fallback minimal mode")
    -- Фолбэк-пульс, чтобы видеть, что VM жива
    GameRules:GetGameModeEntity():SetThink(function()
      dbg(("pulse @ %.1f"):format(GameRules:GetGameTime()))
      return 5.0
    end, "HDDM_FallbackPulse", 0.1)
    return
  end

  GameRules.HDDM = HDDM.Game()
  GameRules.HDDM:Init()
end