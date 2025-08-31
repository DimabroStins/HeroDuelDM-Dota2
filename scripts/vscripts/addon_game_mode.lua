-- ======== addon_game_mode.lua (минимально полезный пульс) ========
if GameMode == nil then GameMode = class({}) end

function Precache(ctx) end

function Activate()
  GameRules.GameMode = GameMode()
  GameRules.GameMode:Init()
end

function GameMode:Init()
  -- ДОЛЖНО появиться в консоли при старте Playtest
  print("[HDDM] Init() reached")

  -- Периодический пульс в консоль раз в 5 сек (видно, что VM жива)
  GameRules:GetGameModeEntity():SetThink("OnThink", self, 0.1)

  -- Чат-команды (-hello, -tp0, -blink, -dummy, -killme, -time)
  ListenToGameEvent("player_chat", Dynamic_Wrap(GameMode, "OnChat"), self)

  -- Консольная команда (не зависит от чата/игроков)
  Convars:RegisterCommand("hddm_hello", function()
    print("[HDDM] console hello OK")
    Say(nil, "HDDM: console hello OK", false)
  end, "HDDM hello test", 0)

  -- Простой хук на смерти (для проверки событий)
  ListenToGameEvent("entity_killed", function(keys)
    local killed = EntIndexToHScript(keys.entindex_killed or -1)
    if killed and killed.GetUnitName and killed:GetUnitName() then
      print("[HDDM] entity_killed:", killed:GetUnitName())
    else
      print("[HDDM] entity_killed: <unknown>")
    end
  end, nil)

  -- Отключим стандартный респаун, чтобы видеть эффекты команд
  GameRules:SetHeroRespawnEnabled(false)
end

function GameMode:OnThink()
  if not self._nextPulse or GameRules:GetGameTime() >= self._nextPulse then
    print(string.format("[HDDM] pulse @ %.1f", GameRules:GetGameTime()))
    self._nextPulse = GameRules:GetGameTime() + 5.0
  end
  return 0.5
end

function GameMode:OnChat(keys)
  local pid  = keys.playerid
  local text = tostring(keys.text or ""):lower()

  if text == "-hello" then
    print("[HDDM] chat hello OK")
    Say(nil, "HDDM: chat hello OK", false)

  elseif text == "-tp0" then
    local h = PlayerResource:GetSelectedHeroEntity(pid)
    if h then
      FindClearSpaceForUnit(h, Vector(0,0,0), true)
      h:Stop()
      Say(nil, "HDDM: TP to (0,0,0)", false)
    end

  elseif text == "-blink" then
    local h = PlayerResource:GetSelectedHeroEntity(pid)
    if h then
      local fwd = h:GetForwardVector() * 600
      local pos = h:GetAbsOrigin() + Vector(fwd.x, fwd.y, 0)
      FindClearSpaceForUnit(h, pos, true)
      h:Stop()
      Say(nil, "HDDM: blink 600", false)
    end

  elseif text == "-dummy" then
    local h = PlayerResource:GetSelectedHeroEntity(pid)
    if h then
      local pos = h:GetAbsOrigin() + h:GetForwardVector()*200
      -- спавним стандартного крипа (точно существует в билде)
      local u = CreateUnitByName("npc_dota_creep_badguys_melee", pos, true, nil, nil, DOTA_TEAM_BADGUYS)
      if u then
        u:SetControllableByPlayer(pid, false)
        print("[HDDM] spawned dummy:", u:GetUnitName())
        Say(nil, "HDDM: dummy spawned", false)
      else
        Say(nil, "HDDM: dummy FAILED", false)
      end
    end

  elseif text == "-killme" then
    local h = PlayerResource:GetSelectedHeroEntity(pid)
    if h then
      h:ForceKill(false)
      Say(nil, "HDDM: you are dead (no respawn)", false)
    end

  elseif text == "-time" then
    Say(nil, string.format("HDDM: time = %.1f", GameRules:GetGameTime()), false)
  end
end