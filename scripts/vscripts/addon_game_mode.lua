- addon_game_mode.lua for Heroduel DM port from WC3

-- Globals from WC3
local players = {} -- udg_Players
local player_count = 0 -- udg_KolichestvoIgrokov
local modes = {standard = 0, ffl = 0, _3vs3 = 0, _4vs4 = 0} -- udg_Mod*
local points_to_win = 2000 -- udg_POINTS_TO_WIN
local hero_pool = { -- udg_DuelNomerHero pool from WC3 heroes
  "npc_dota_hero_axe", "npc_dota_hero_lina", "npc_dota_hero_pudge" -- add 20 from w3h, custom
}
local rh_vikl = {} for i=1, #hero_pool do rh_vikl[i] = 0 end -- udg_RHvikl for random check
local duels = {} -- for -duel challenge
local kill_table = {} -- udg_Table_HeroKill etc for kills

-- Init like Trig_Initialization
function InitGameMode()
  print("Heroduel DM: Start - modes, random heroes, duels from WC3!")
  -- Players from WC3 udg_Players
  for team = DOTA_TEAM_GOODGUYS, DOTA_TEAM_BADGUYS do
    for i = 1, 5 do
      local player_id = PlayerResource:GetNthPlayerIDOnTeam(team, i)
      if player_id ~= -1 then
        table.insert(players, player_id)
        player_count = player_count + 1
      end
    end
  end

  -- Modes dialog for host (Player 0 - red)
  ListenToGameEvent('player_chat', Dynamic_Wrap(self, 'OnPlayerChat'), self) -- for -duel, -ar, -points X

  -- Hero respawn false, custom teams like WC3 mods
  GameRules:SetHeroRespawnEnabled(false)
  GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_GOODGUYS, 4)
  GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_BADGUYS, 4)

  -- Events like WC3 trigs
  ListenToGameEvent('game_rules_state_change', Dynamic_Wrap(self, 'OnGameRulesStateChange'), self)
  ListenToGameEvent('entity_killed', Dynamic_Wrap(self, 'OnEntityKilled'), self)
end

-- On chat for commands like WC3
function OnPlayerChat(keys)
  local player_id = keys.playerid
  local text = keys.text
  if text == "-ar" and player_id == 0 then -- AllRandom like Trig_AllRandom
    for _, pid in ipairs(players) do
      SpawnRandomHero(pid)
    end
  elseif string.find(text, "-points ") and player_id = 0 then -- POINTS_TO_WIN
    local points = tonumber(string.sub(text, 9))
    points_to_win = points_to_win + points
    print("Points to win: " .. points_to_win)
  elseif text == "-duel" then -- Duel challenge like Trig_VizovNowii1
    -- Add logic for dialog/challenge, timer udg_Duel_Timer
    print("Duel challenge!")
  end
end

-- Start game, random heroes like OnGameStart
function OnGameRulesStateChange(keys)
  if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
    for _, pid in ipairs(players) do
      SpawnRandomHero(pid)
    end
  end
end

-- Random hero spawn like Trig_RandomHero2
function SpawnRandomHero(player_id)
  local hero_name
  repeat
    local index = math.random(1, #hero_pool)
    if rh_vikl[index] == 0 then
      rh_vikl[index] = 1
      hero_name = hero_pool[index]
    end
  until hero_name
  local player = PlayerResource:GetPlayer(player_id)
  local hero = CreateHeroForPlayer(hero_name, player)
  hero:SetLevel(1) -- WC3 level up
  FindClearSpaceForUnit(hero, Vector(0,0,0), true) -- Center arena teleport
  print("Spawned " .. hero_name)
end

-- On death, respawn new hero like Trig_OnHeroKilled
function OnEntityKilled(keys)
  local killed = EntIndexToHScript(keys.entindex_killed)
  if killed:IsRealHero() then
    local player_id = killed:GetPlayerID()
    Timers:CreateTimer(5, function()
      SpawnRandomHero(player_id)
    end)
  end
end