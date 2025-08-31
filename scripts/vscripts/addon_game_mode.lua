-- === addon_game_mode.lua — загрузчик через DoIncludeScript ===
if HDDM == nil then HDDM = {} end
local function dbg(m) print("[HDDM][DBG] " .. tostring(m)) end

-- Пытаемся включить каркас: scripts/vscripts/hddm/init.lua
local ok, err = pcall(function() DoIncludeScript("hddm/init", _G) end)
if ok then
  dbg("Include OK: hddm/init")
else
  dbg("Include FAILED: " .. tostring(err))
end

function Precache(_) end

function Activate()
  dbg("Activate()")
  if type(HDDM) == "table" and type(HDDM.Game) == "function" then
    GameRules.HDDM = HDDM.Game()
    GameRules.HDDM:Init()
    return
  end

  -- Фолбэк-пульс, если модуль не загрузился
  dbg("HDDM.Game not found — fallback pulse mode")
  GameRules:GetGameModeEntity():SetThink(function()
    dbg(("pulse @ %.1f"):format(GameRules:GetGameTime()))
    return 5.0
  end, "HDDM_FallbackPulse", 0.1)
end