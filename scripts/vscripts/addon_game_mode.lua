if GameMode == nil then GameMode = class({}) end

print("[HDDM] FILE LOADED")

DoIncludeScript("hddm/dev",   _G)
DoIncludeScript("hddm/score", _G)
DoIncludeScript("hddm/spawn", _G)
DoIncludeScript("timers", _G)

function Precache(_) end
function Activate() GameRules.GameMode = GameMode(); GameRules.GameMode:Init() end

function GameMode:Init()
  print("[HDDM] Init() reached")

  local gme = GameRules:GetGameModeEntity()
gme:SetCustomGameForceHero("npc_dota_hero_axe")

  GameRules:SetHeroSelectionTime(0.0)
  GameRules:SetStrategyTime(0.0)
  GameRules:SetShowcaseTime(0.0)
  GameRules:SetPreGameTime(3.0)

  -- НЕ трогаем FoW прямо тут (это крашило VM на твоём билде)
  -- Включать туман/снимать его будем командами из dev.lua: -fow on / -fow off

  -- Если хочешь авто-выключать туман — делаем это отложенно, когда всё точно инициализировалось:
  local gme = GameRules:GetGameModeEntity()
  gme:SetThink(function()
    if GameRules and GameRules.SetFogOfWarDisabled then
      GameRules:SetFogOfWarDisabled(true)
      print("[HDDM] FoW disabled (delayed)")
    else
      print("[HDDM] FoW API not available yet, skipping")
    end
    return nil -- однократно
  end, "HDDM_FoWOnce", 0.5)

  -- пульс
  gme:SetThink("OnThink", self, 0.1)

  -- спавнер
  if HDDM and HDDM.Spawn and HDDM.Spawn.Init then
    HDDM.Spawn:Init()
  end

  -- события
  ListenToGameEvent("player_chat",  Dynamic_Wrap(GameMode, "OnChat"), self)
  ListenToGameEvent("entity_killed", function(keys)
  ListenToGameEvent("npc_spawned", Dynamic_Wrap(GameMode, "OnNPCSpawned"), self)
    local killed   = EntIndexToHScript(keys.entindex_killed or -1)
    local attacker = EntIndexToHScript(keys.entindex_attacker or -1)
    local kname = (killed   and killed.GetUnitName   and killed:GetUnitName())   or "<nil>"
    local aname = (attacker and attacker.GetUnitName and attacker:GetUnitName()) or "<nil>"
    print(("[HDDM][EK] killed=%s attacker=%s"):format(kname, aname))
    if HDDM and HDDM.Score and HDDM.Score.OnEntityKilled then
      HDDM.Score:OnEntityKilled(keys)
    end
  end, nil)

  -- консольная проверка
  Convars:RegisterCommand("hddm_ping", function()
    print("[HDDM] ping ok"); Say(nil, "HDDM: ping ok", false)
  end, "ping", 0)

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
  local txt = tostring(keys.text or ""):lower()
  if HDDM and HDDM.Dev and HDDM.Dev.OnChat then
    if HDDM.Dev:OnChat(keys) then return end
  end
  if txt == "-hello" then
    print("[HDDM] chat hello"); Say(nil, "HDDM: hello", false); return
  end
  function GameMode:OnNPCSpawned(keys)
  local unit = EntIndexToHScript(keys.entindex or -1)
  if not unit or unit:IsNull() then return end
  if not unit:IsRealHero() then return end
  if unit._hddm_setup_done then return end

  unit._hddm_setup_done = true

  -- сносим стандартные абилки героя
  for i = 0, 23 do
    local ab = unit:GetAbilityByIndex(i)
    if ab then
      local name = ab:GetAbilityName()
      if name ~= "generic_hidden"
        and name ~= "special_bonus_attributes"
        and not string.find(name, "special_bonus") then
        unit:RemoveAbility(name)
      end
    end
  end

  -- даём нашу
  unit:AddAbility("meteor_wave")

  local meteor = unit:FindAbilityByName("meteor_wave")
  if meteor then
    meteor:SetLevel(1)
  end
end
end
