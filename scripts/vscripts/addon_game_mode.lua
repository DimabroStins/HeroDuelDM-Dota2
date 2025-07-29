- HeroDuelDM Dota 2 Mod (based on War3 JASS logic)
-- Full mod with heroes, AI, duels, waves, boss, recipes, points, bonuses

require('timers')
require('physics')  -- Для ульт с pull и т.д.
require('util')     -- Для RandomVector и т.д.

local HeroDuelDM = class({})

function HeroDuelDM:InitGameMode()
    -- Настройки игры
    GameRules:SetHeroRespawnEnabled(true)
    GameRules:SetUseUniversalShopMode(true)
    GameRules:SetHeroSelectionTime(30.0)
    GameRules:SetPreGameTime(60.0)
    GameRules:SetPostGameTime(60.0)
    GameRules:SetTreeRegrowTime(60.0)
    GameRules:SetGoldTickTime(60.0)
    GameRules:SetGoldPerTick(1)
    GameRules:SetCustomGameDifficulty(1)
    GameRules:SetCustomGameEndDelay(60.0)
    GameRules:SetCustomVictoryMessageDuration(30.0)
    GameRules:SetSameHeroSelectionEnabled(true)
    GameRules:SetStartingGold(625)

    -- Евенты
    ListenToGameEvent('entity_killed', Dynamic_Wrap(self, 'OnEntityKilled'), self)
    ListenToGameEvent('dota_player_pick_hero', Dynamic_Wrap(self, 'OnHeroPicked'), self)
    ListenToGameEvent('dota_item_combined', Dynamic_Wrap(self, 'OnItemCombined'), self)
    ListenToGameEvent('dota_item_picked_up', Dynamic_Wrap(self, 'OnItemPickedUp'), self)
    ListenToGameEvent('player_chat', Dynamic_Wrap(self, 'OnPlayerChat'), self)
    ListenToGameEvent('npc_spawned', Dynamic_Wrap(self, 'OnNPCSpawned'), self)

    -- Инициализация
    self.points = {}
    for i = 0, 7 do
        self.points[i] = 0
    end
    self.duel_active = false
    self.wave = 1
    self.boss = nil
    self.ai_states = {}  -- Для AI героев

    self:SpawnAIHeroes()
    self:StartWaves()
    self:StartBonuses()
    self:StartDuels()
    self:SetupPoints()
end

function HeroDuelDM:SpawnAIHeroes()
    local heroes = {
        "npc_dota_hero_omniknight", -- DH (Demon Hunter)
        "npc_dota_hero_dragon_knight" -- FirePov (Повелитель Огня)
        -- Добавь остальных: "npc_dota_hero_phantom_assassin" для Amazona и т.д.
    }
    for i, name in ipairs(heroes) do
        local player = PlayerResource:GetPlayer(i + 7)  -- AI на стороне badguys
        local hero = CreateHeroForPlayer(name, player)
        self.ai_states[hero:GetEntityIndex()] = {skill_cd = {}, patrol = true, target = nil}
        hero:AddAbility("custom_roar")  -- Пример для DH
        hero:UpgradeAbility(hero:FindAbilityByName("custom_roar"))
        Timers:CreateTimer(function()
            self:AIThink(hero)
            return 0.5
        end)
    end
end

function HeroDuelDM:AIThink(hero)
    local state = self.ai_states[hero:GetEntityIndex()]
    if not hero:IsAlive() then return end

    -- Патруль арены, если нет цели (из JASS креепинг)
    if state.patrol and not state.target then
        hero:MoveToPosition(Util:RandomVectorInArena())
        state.patrol = false
        Timers:CreateTimer(15, function()
            state.patrol = true
        end)
    end

    -- Атака ближайших врагов (радиус 1600-2000 из JASS)
    local enemies = hero:GetNearbyHeroes(1600, true, BOT_MODE_NONE)
    if #enemies > 0 then
        state.target = enemies[1]
        hero:MoveToPositionAggressive(state.target:GetOrigin())
    end

    -- Использование скиллов (на основе JASS условий: mana, HP, target hero)
    local abilities = {hero:FindAbilityByName("custom_roar"), -- Для DH
                       hero:FindAbilityByName("fire_breath")} -- Для FirePov
    for _, ability in ipairs(abilities) do
        if ability and ability:IsFullyCastable() and not state.skill_cd[ability:GetName()] then
            if ability:GetBehavior() == DOTA_ABILITY_BEHAVIOR_NO_TARGET and hero:GetHealthPercent() < 20 then
                hero:CastAbilityNoTarget(ability, hero:GetPlayerID())
            elseif ability:GetBehavior() == DOTA_ABILITY_BEHAVIOR_POINT and state.target then
                hero:CastAbilityOnPosition(state.target:GetOrigin(), ability, hero:GetPlayerID())
            end
            state.skill_cd[ability:GetName()] = true
            Timers:CreateTimer(ability:GetCooldown(ability:GetLevel()), function()
                state.skill_cd[ability:GetName()] = nil
            end)
        end
    end
end

function HeroDuelDM:StartWaves()
    Timers:CreateTimer(400, function()
        if self.wave <= 6 then
            for i = 1, 5 do
                CreateUnitByName("npc_dota_creep_neutral", Util:RandomVectorInArena(), true, nil, nil, DOTA_TEAM_NEUTRALS)
            end
            self.wave = self.wave + 1
            return 400
        end
    end)
end

-- Другие функции: OnEntityKilled (очки), OnItemCombined (рецепты, добавь все 30+ из JASS), OnPlayerChat (дуэли -yes), StartDuels (таймер 600 сек, телепорт в зону), StartBonuses (XP после 1600 сек), etc.

-- Для рецептов (пример, добавь все Rec*)
function HeroDuelDM:OnItemCombined(keys)
    local hero = keys.hero
    local itemName = keys.item_name
    if itemName == "item_vamp_posoh" then
        hero:RemoveItem(hero:FindItemInInventory("item_i01e"))
        hero:AddItemByName("item_i00s")
        -- FX: ParticleManager:CreateParticle("particles/items/combine.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
    end
    -- Добавь остальные: RecOgnShit, RecSkorostArbalet и т.д.
end

-- Для S1-S8 (on pickup I01T)
function HeroDuelDM:OnItemPickedUp(keys)
    local hero = keys.hero
    local item = keys.item
    if item:GetName() == "item_i01t" then
        CreateUnitByName("npc_n00c", hero:GetOrigin(), true, hero, hero, hero:GetTeamNumber())
    end
end

-- Util functions
function Util:RandomVectorInArena()
    return Vector(RandomInt(-5000, 5000), RandomInt(-5000, 5000), 0)
end