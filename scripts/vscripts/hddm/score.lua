if HDDM == nil then HDDM = {} end
HDDM.Score = HDDM.Score or { table = {}, points_to_win = 2000 }

local function add(pid, delta, reason)
  if not PlayerResource:IsValidPlayerID(pid) then return end
  local t = HDDM.Score.table
  t[pid] = (t[pid] or 0) + delta
  Say(nil, string.format("[Score] pid=%d %+d => %d (%s)", pid, delta, t[pid], reason or ""), false)
  if t[pid] >= HDDM.Score.points_to_win then
    Say(nil, string.format("[Score] Player %d reached %d! (WIN)", pid, t[pid]), false)
  end
end

function HDDM.Score:Get(pid) return (self.table[pid] or 0) end

local function killer_pid_from(attacker)
  if not attacker or attacker:IsNull() then return -1 end
  if attacker.IsRealHero and attacker:IsRealHero() then
    local p = attacker:GetPlayerOwnerID() or -1
    if p ~= -1 then return p end
  end
  if attacker.GetOwner and attacker:GetOwner() then
    local o = attacker:GetOwner()
    if o.IsRealHero and o:IsRealHero() then
      local p = o:GetPlayerOwnerID() or -1
      if p ~= -1 then return p end
    end
  end
  if attacker.GetOwnerEntity and attacker:GetOwnerEntity() then
    local o = attacker:GetOwnerEntity()
    if o.IsRealHero and o:IsRealHero() then
      local p = o:GetPlayerOwnerID() or -1
      if p ~= -1 then return p end
    end
  end
  if attacker.GetPlayerOwnerID then
    local p = attacker:GetPlayerOwnerID() or -1
    if p ~= -1 then return p end
  end
  return -1
end

local function is_boss(unit)
  if not unit or unit:IsNull() then return false end
  local name = unit.GetUnitName and (unit:GetUnitName() or "") or ""
  if name == "npc_dota_roshan" then return true end
  return string.find(name, "boss") ~= nil
end

function HDDM.Score:OnEntityKilled(keys)
  local killed   = EntIndexToHScript(keys.entindex_killed   or -1)
  local attacker = EntIndexToHScript(keys.entindex_attacker or -1)
  if not killed or killed:IsNull() then return end

  if killed.IsRealHero and killed:IsRealHero() then
    local victim = killed:GetPlayerOwnerID() or -1
    if victim ~= -1 then add(victim, -50, "death") end
  end

  local killer = killer_pid_from(attacker)
  if killer ~= -1 then
    if killed.IsRealHero and killed:IsRealHero() then
      add(killer, 50, "hero")
    elseif is_boss(killed) then
      add(killer, 300, "boss")
    else
      add(killer, 1, "creep")
    end
  end
end