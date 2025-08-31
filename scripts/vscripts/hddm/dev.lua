if HDDM == nil then HDDM = {} end
HDDM.VERSION = "0.1"

function HDDM.Game()
  local self = {}

  function self:Init()
    print(("[HDDM] Init v%s"):format(HDDM.VERSION))
    GameRules:GetGameModeEntity():SetThink(function() return self:OnThink() end, "HDDM_Pulse", 0.1)
    ListenToGameEvent("player_chat", function(keys) self:OnChat(keys) end, nil)

    -- консольная команда для проверки без чата
    Convars:RegisterCommand("hddm_ping", function()
      print("[HDDM] ping ok"); Say(nil, "HDDM: ping ok", false)
    end, "ping", 0)
  end

  function self:OnThink()
    if not self._t or GameRules:GetGameTime() >= self._t then
      print(string.format("[HDDM] pulse @ %.1f", GameRules:GetGameTime()))
      self._t = GameRules:GetGameTime() + 5
    end
    return 0.5
  end

  function self:OnChat(keys)
    local txt = tostring(keys.text or ""):lower()
    if txt == "-hello" then
      print("[HDDM] chat hello"); Say(nil, "HDDM: hello", false)
    end
  end

  return self
end