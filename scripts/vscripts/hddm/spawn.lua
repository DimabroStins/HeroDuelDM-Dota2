if HDDM == nil then HDDM = {} end

HDDM.Spawn = {
  enabled = false,
  interval = 8.0,
  count_per_wave = 6,

  -- Разрешённые зоны (список прямоугольников). ПУСТО по умолчанию.
  -- Пока список пустой — НЕ спавним вообще (чтобы не «везде»).
  allowed_boxes = {
    -- заполняем командами -setmin / -setmax / -box add
  },

  -- Запретные круги (например, магазины/дуэль-зоны)
  forbidden_circles = {
    -- { pos = Vector(0,0,0), r = 1000 }
  },

  -- буфер для -setmin/-setmax
  _pending_min = nil,
  _pending_max = nil,

  _think_tag = "HDDM_SpawnThink",
}

local function rand_between(a, b) return a + RandomFloat(0,1)*(b-a) end

local function in_box(pos, box)
  local mn = Vector(math.min(box.min.x, box.max.x), math.min(box.min.y, box.max.y), 0)
  local mx = Vector(math.max(box.min.x, box.max.x), math.max(box.min.y, box.max.y), 0)
  return (pos.x >= mn.x and pos.x <= mx.x) and (pos.y >= mn.y and pos.y <= mx.y)
end

local function in_forbidden(pos, forb)
  for _,f in ipairs(forb) do
    if (pos - f.pos):Length2D() <= f.r then return true end
  end
  return false
end

local function random_in_box(box)
  local mn = Vector(math.min(box.min.x, box.max.x), math.min(box.min.y, box.max.y), 0)
  local mx = Vector(math.max(box.min.x, box.max.x), math.max(box.min.y, box.max.y), 0)
  return Vector(
    rand_between(mn.x, mx.x),
    rand_between(mn.y, mx.y),
    0
  )
end

local function make_idle(u)
  if not u or u:IsNull() then return end
  u:SetIdleAcquire(false)
  u:SetAcquisitionRange(0)
  u:Hold()
  u:SetForwardVector(RandomVector(1))
end

-- выбираем случайную точку в одном из разрешённых прямоугольников, избегая запретных кругов
function HDDM.Spawn:_random_pos()
  if not self.allowed_boxes or #self.allowed_boxes == 0 then
    return nil -- нет зон → нет спавна
  end
  local tries = 100
  while tries > 0 do
    tries = tries - 1
    local box = self.allowed_boxes[RandomInt(1, #self.allowed_boxes)]
    local pos = random_in_box(box)
    if not in_forbidden(pos, self.forbidden_circles) then
      return pos
    end
  end
  return nil
end

function HDDM.Spawn:_do_wave()
  if not self.enabled then return self.interval end

  if not self.allowed_boxes or #self.allowed_boxes == 0 then
    Say(nil, "[Spawn] нет разрешённых зон (используй -setmin/-setmax/-box add)", false)
    return self.interval
  end

  local spawned = 0
  for i=1, math.max(0, self.count_per_wave) do
    local pos = self:_random_pos()
    if pos then
      local u = CreateUnitByName("npc_dota_creep_badguys_melee", pos, true, nil, nil, DOTA_TEAM_NEUTRALS)
      if u then
        make_idle(u)
        spawned = spawned + 1
      end
    end
  end

  Say(nil, ("[Spawn] wave: +%d (count=%d, boxes=%d, rate=%.1fs)")
      :format(spawned, self.count_per_wave, #self.allowed_boxes, self.interval), false)
  return self.interval
end

function HDDM.Spawn:Init()
  print("[HDDM][Spawn] init")
  local gme = GameRules:GetGameModeEntity()
  gme:SetThink(function() return self:_do_wave() end, self._think_tag, self.interval)
end

-- === Дев-утилиты для зон ===
function HDDM.Spawn:SetMinFromHero(hero)
  if hero then
    self._pending_min = hero:GetAbsOrigin()
    Say(nil, ("Box min set: (%.0f, %.0f)"):format(self._pending_min.x, self._pending_min.y), false)
  end
end

function HDDM.Spawn:SetMaxFromHero(hero)
  if hero then
    self._pending_max = hero:GetAbsOrigin()
    Say(nil, ("Box max set: (%.0f, %.0f)"):format(self._pending_max.x, self._pending_max.y), false)
  end
end

function HDDM.Spawn:AddPendingBox()
  if self._pending_min and self._pending_max then
    table.insert(self.allowed_boxes, {min=self._pending_min, max=self._pending_max})
    Say(nil, ("Box added (allowed now: %d)"):format(#self.allowed_boxes), false)
    self._pending_min, self._pending_max = nil, nil
  else
    Say(nil, "Box add failed: сначала -setmin и -setmax", false)
  end
end

function HDDM.Spawn:ClearBoxes()
  self.allowed_boxes = {}
  Say(nil, "Allowed boxes cleared (спавна не будет, пока не добавишь хотя бы один)", false)
end

function HDDM.Spawn:ListBoxes()
  if #self.allowed_boxes == 0 then
    Say(nil, "Allowed boxes: <пусто>", false)
    return
  end
  Say(nil, ("Allowed boxes (%d):"):format(#self.allowed_boxes), false)
  for i,b in ipairs(self.allowed_boxes) do
    Say(nil, ("  #%d: min(%.0f,%.0f) max(%.0f,%.0f)"):format(i, b.min.x, b.min.y, b.max.x, b.max.y), false)
  end
end

function HDDM.Spawn:AddBanCircle(pos, r)
  table.insert(self.forbidden_circles, {pos=pos, r=r})
  Say(nil, ("Ban circle added r=%.0f (bans=%d)"):format(r, #self.forbidden_circles), false)
end

function HDDM.Spawn:ClearBans()
  self.forbidden_circles = {}
  Say(nil, "Ban circles cleared", false)
end

function HDDM.Spawn:Dbg()
  Say(nil, ("[Spawn] enabled=%s, interval=%.1f, count=%d, boxes=%d, bans=%d")
      :format(tostring(self.enabled), self.interval, self.count_per_wave,
              #self.allowed_boxes, #self.forbidden_circles), false)
end
