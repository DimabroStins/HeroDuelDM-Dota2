if HDDM == nil then HDDM = {} end
HDDM.Dev = HDDM.Dev or {}

function HDDM.Dev:OnChat(keys)
  local pid  = keys.playerid
  local txt  = tostring(keys.text or ""):lower()
  local hero = PlayerResource:GetSelectedHeroEntity(pid)

  -- показать свой счёт
  if txt == "-score" then
    local s = (HDDM and HDDM.Score and HDDM.Score:Get(pid)) or 0
    Say(nil, string.format("Your score: %d", s), false); return true
  end

  -- базовые утилиты
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

  -- раскрыть карту (геймплейный FoW)
  if txt == "-fow on"  then GameRules:SetFogOfWarDisabled(true);  Say(nil,"FoW: OFF (full vision)",false); return true end
  if txt == "-fow off" then GameRules:SetFogOfWarDisabled(false); Say(nil,"FoW: ON",false);              return true end

  -- старое «reveal» (мягкое, можно оставить)
  if txt == "-reveal on" then
    AddFOWViewer(DOTA_TEAM_GOODGUYS, Vector(0,0,0), 99999, 99999, true)
    AddFOWViewer(DOTA_TEAM_BADGUYS,  Vector(0,0,0), 99999, 99999, true)
    Say(nil, "Reveal: ON", false); return true
  end
  if txt == "-reveal off" then
    Say(nil, "Reveal: OFF (сбросится после перезапуска карты)", false); return true
  end

  -- управление спавном
  if txt == "-spawn on"  then if HDDM and HDDM.Spawn then HDDM.Spawn.enabled = true  end; Say(nil,"Spawn: ON",false);  return true end
  if txt == "-spawn off" then if HDDM and HDDM.Spawn then HDDM.Spawn.enabled = false end; Say(nil,"Spawn: OFF",false); return true end
  if string.sub(txt,1,11) == "-spawn rate" then
    local n = tonumber(string.match(txt, "%-spawn rate%s+(%S+)") or "")
    if HDDM and HDDM.Spawn and n and n>0 then HDDM.Spawn.interval = n; Say(nil,"Spawn: interval="..n,false) end
    return true
  end
  if string.sub(txt,1,13) == "-spawn count" then
    local n = tonumber(string.match(txt, "%-spawn count%s+(%S+)") or "")
    if HDDM and HDDM.Spawn and n and n>0 then HDDM.Spawn.count_per_wave = math.floor(n); Say(nil,"Spawn: count="..n,false) end
    return true
  end
  if txt == "-spawn once" then
    if HDDM and HDDM.Spawn then
      local old = HDDM.Spawn.enabled; HDDM.Spawn.enabled = true
      HDDM.Spawn:_do_wave()
      HDDM.Spawn.enabled = old
    end
    return true
  end

  -- allowed boxes: прямоугольники «где можно»
  if txt == "-setmin" and hero then if HDDM and HDDM.Spawn then HDDM.Spawn:SetMinFromHero(hero) end; return true end
  if txt == "-setmax" and hero then if HDDM and HDDM.Spawn then HDDM.Spawn:SetMaxFromHero(hero) end; return true end
  if txt == "-box add"   then if HDDM and HDDM.Spawn then HDDM.Spawn:AddPendingBox()  end; return true end
  if txt == "-box clear" then if HDDM and HDDM.Spawn then HDDM.Spawn:ClearBoxes()     end; return true end

  -- forbidden circles: «где НЕЛЬЗЯ» (шоп/дуэль)
  if string.sub(txt,1,4) == "-ban" and hero then
    local r = tonumber(string.match(txt, "%-ban%s+(%S+)") or "")
    if r and r>0 and HDDM and HDDM.Spawn then HDDM.Spawn:AddBanCircle(hero:GetAbsOrigin(), r) end
    return true
  end
  if txt == "-ban clear" then if HDDM and HDDM.Spawn then HDDM.Spawn:ClearBans() end; return true end
  -- диагностика спавна
  if txt == "-spawn dbg" then
    local b = HDDM and HDDM.Spawn
    if b then
      Say(nil, string.format("Spawn: enabled=%s interval=%.1f count=%d boxes=%d bans=%d",
        tostring(b.enabled), b.interval, b.count_per_wave,
        #(b.allowed_boxes or {}), #(b.forbidden_circles or {})), false)
    else
      Say(nil, "Spawn: NOT LOADED", false)
    end
    return true
  end

  -- === управление спавном ===
  if txt == "-spawn on"  then
    if HDDM and HDDM.Spawn then HDDM.Spawn.enabled = true end
    Say(nil,"Spawn: ON",false); return true
  end

  if txt == "-spawn off" then
    if HDDM and HDDM.Spawn then HDDM.Spawn.enabled = false end
    Say(nil,"Spawn: OFF",false); return true
  end

  if string.sub(txt,1,11) == "-spawn rate" then
    local n = tonumber(string.match(txt, "%-spawn rate%s+(%S+)") or "")
    if HDDM and HDDM.Spawn and n and n>0 then
      HDDM.Spawn.interval = n
      Say(nil,"Spawn: interval="..n,false)
    else
      Say(nil,"Usage: -spawn rate <seconds>",false)
    end
    return true
  end

  if string.sub(txt,1,13) == "-spawn count" then
    local n = tonumber(string.match(txt, "%-spawn count%s+(%S+)") or "")
    if HDDM and HDDM.Spawn and n and n>=0 then
      HDDM.Spawn.count_per_wave = math.floor(n)
      Say(nil,"Spawn: count="..HDDM.Spawn.count_per_wave,false)
    else
      Say(nil,"Usage: -spawn count <int>",false)
    end
    return true
  end

  if txt == "-spawn once" then
    if HDDM and HDDM.Spawn then
      local old = HDDM.Spawn.enabled
      HDDM.Spawn.enabled = true
      HDDM.Spawn:_do_wave()
      HDDM.Spawn.enabled = old
    end
    return true
  end

  if txt == "-spawn dbg" then
    if HDDM and HDDM.Spawn then HDDM.Spawn:Dbg() end
    return true
  end

  -- === allowed boxes ===
  if txt == "-setmin" and hero then if HDDM and HDDM.Spawn then HDDM.Spawn:SetMinFromHero(hero) end; return true end
  if txt == "-setmax" and hero then if HDDM and HDDM.Spawn then HDDM.Spawn:SetMaxFromHero(hero) end; return true end
  if txt == "-box add" then if HDDM and HDDM.Spawn then HDDM.Spawn:AddPendingBox() end; return true end
  if txt == "-box clear" then if HDDM and HDDM.Spawn then HDDM.Spawn:ClearBoxes() end; return true end
  if txt == "-box list" then if HDDM and HDDM.Spawn then HDDM.Spawn:ListBoxes() end; return true end

  -- === forbidden circles ===
  if string.sub(txt,1,4) == "-ban" and hero then
    local r = tonumber(string.match(txt, "%-ban%s+(%S+)") or "")
    if r and r>0 and HDDM and HDDM.Spawn then HDDM.Spawn:AddBanCircle(hero:GetAbsOrigin(), r) end
    return true
  end
  if txt == "-ban clear" then if HDDM and HDDM.Spawn then HDDM.Spawn:ClearBans() end; return true 
  end

  return false
end