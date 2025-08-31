if HDDM == nil then HDDM = {} end
HDDM.Dev = HDDM.Dev or {}

function HDDM.Dev:OnChat(keys)
  local pid  = keys.playerid
  local txt  = tostring(keys.text or ""):lower()
  local hero = PlayerResource:GetSelectedHeroEntity(pid)

  if txt == "-score" then
  local s = (HDDM and HDDM.Score and HDDM.Score:Get(pid)) or 0
  Say(nil, string.format("Your score: %d", s), false); return true
end
  if txt == "-tp0" and hero then
    FindClearSpaceForUnit(hero, Vector(0,0,0), true); hero:Stop()
    Say(nil, "HDDM: TP to (0,0,0)", false); return true
  end

  if txt == "-blink" and hero then
    local f = hero:GetForwardVector()*600
    FindClearSpaceForUnit(hero, hero:GetAbsOrigin()+Vector(f.x,f.y,0), true); hero:Stop()
    Say(nil, "HDDM: blink 600", false); return true
  end

  if txt == "-dummy" and hero then
    local pos = hero:GetAbsOrigin()+hero:GetForwardVector()*200
    local u = CreateUnitByName("npc_dota_creep_badguys_melee", pos, true, nil, nil, DOTA_TEAM_BADGUYS)
    if u then Say(nil, "HDDM: dummy spawned", false) end
    return true
  end

  if txt == "-killme" and hero then
    hero:ForceKill(false); Say(nil, "HDDM: you are dead (no respawn)", false); return true
  end

  if txt == "-time" then
    Say(nil, string.format("HDDM: time = %.1f", GameRules:GetGameTime()), false); return true
  end

  return false
end