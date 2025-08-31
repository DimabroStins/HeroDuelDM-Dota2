-- ======== addon_game_mode.lua (чистая база) ========
if GameMode == nil then GameMode = class({}) end

DoIncludeScript("hddm/dev", _G)
DoIncludeScript("hddm/score", _G)

function Precache(_) end

function Activate()
  GameRules.GameMode = GameMode()
  GameRules.GameMode:Init()
end

function GameMode:Init()
  print("[HDDM] Init() reached")
  GameRules:GetGameModeEntity():SetThink("OnThink", self, 0.1)

  -- события
  ListenToGameEvent("player_chat", Dynamic_Wrap(GameMode, "OnChat"), self)
  -- KILL EVENT → диагностика + проксируем в модуль очков
ListenToGameEvent("entity_killed", function(keys)
  local killed   = EntIndexToHScript(keys.entindex_killed or -1)
  local attacker = EntIndexToHScript(keys.entindex_attacker or -1)
  local kname = (killed   and killed.GetUnitName   and killed:GetUnitName())   or "<nil>"
  local aname = (attacker and attacker.GetUnitName and attacker:GetUnitName()) or "<nil>"
  print(("[HDDM][EK] killed=%s attacker=%s"):format(kname, aname))

  if HDDM and HDDM.Score and HDDM.Score.OnEntityKilled then
    HDDM.Score:OnEntityKilled(keys)
  end
end, nil)

  -- консольная команда для быстрой проверки
  Convars:RegisterCommand("hddm_ping", function()
    print("[HDDM] ping ok"); Say(nil, "HDDM: ping ok", false)
  end, "ping", 0)

  -- без респауна, чтобы видеть эффект -killme (позже настроим)
  GameRules:SetHeroRespawnEnabled(true)
end

function GameMode:OnThink()
  if not self._t or GameRules:GetGameTime() >= self._t then
    print(string.format("[HDDM] pulse @ %.1f", GameRules:GetGameTime()))
    self._t = GameRules:GetGameTime() + 5.0
  end
  return 0.5
end

function GameMode:OnChat(keys)
  local pid  = keys.playerid
  local txt  = tostring(keys.text or ""):lower()

if HDDM and HDDM.Dev and HDDM.Dev.OnChat then
  if HDDM.Dev:OnChat(keys) then return end
end

  if txt == "-hello" then
    print("[HDDM] chat hello"); Say(nil, "HDDM: hello", false); return
  end

  
end