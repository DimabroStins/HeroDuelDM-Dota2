-- === addon_game_mode.lua — аккуратный загрузчик каркаса ===
if HDDM == nil then HDDM = {} end
local function dbg(m) print("[HDDM][DBG] " .. tostring(m)) end

-- Даем require видеть подпапки:
--  - scripts/vscripts/?.lua           → require("hddm.init") ищет hddm/init.lua
--  - scripts/vscripts/?/init.lua      → require("hddm")      тоже найдет hddm/init.lua
package.path = package.path .. ";scripts/vscripts/?.lua;scripts/vscripts/?/init.lua"

-- Пробуем подключить наш каркас
local ok, err = pcall(function() return require("hddm") end)
if ok then
  dbg("require OK: hddm/init.lua loaded")
else
  dbg("require FAILED: " .. tostring(err))
end

function Precache(_) end

function Activate()
  dbg("Activate()")
  if type(HDDM) == "table" and type(HDDM.Game) == "function" then
    GameRules.HDDM = HDDM.Game()
    GameRules.HDDM:Init()
    return
  end

  -- Фолбэк, чтобы видеть жизнь VM, если каркас не загрузился
  dbg("HDDM.Game not found — fallback pulse mode")
  GameRules:GetGameModeEntity():SetThink(function()
    dbg(("pulse @ %.1f"):format(GameRules:GetGameTime()))
    return 5.0
  end, "HDDM_FallbackPulse", 0.1)
end