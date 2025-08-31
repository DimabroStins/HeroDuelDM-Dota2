if GameMode == nil then GameMode = class({}) end

function Precache(ctx) end

function Activate()
  GameRules.GameMode = GameMode()
  GameRules.GameMode:Init()
end

function GameMode:Init()
  print("[HDDM] LOADED: Init() reached")
  ListenToGameEvent("player_chat", Dynamic_Wrap(GameMode, "OnChat"), self)
end

function GameMode:OnChat(keys)
  local t = tostring(keys.text or "")
  if t == "-hello" then
    Say(nil, "Привет! Скрипт жив.", false)
    print("[HDDM] -hello fired")
  elseif t == "-tp0" then
    local h = PlayerResource:GetSelectedHeroEntity(keys.playerid)
    if h then FindClearSpaceForUnit(h, Vector(0,0,0), true) h:Stop() end
  end
end
