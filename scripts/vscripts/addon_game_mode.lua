if HDDM == nil then HDDM = {} end
-- дать Lua увидеть подпапку hddm
package.path = package.path .. ";scripts/vscripts/?.lua;scripts/vscripts/?/init.lua"

require("hddm")  -- загрузит scripts/vscripts/hddm/init.lua

function Precache(_) end
function Activate()
  GameRules.HDDM = HDDM.Game()
  GameRules.HDDM:Init()
end