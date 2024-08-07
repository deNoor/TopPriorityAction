local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class Player : Unit
---@field Talents table<integer,boolean>
---@field Equipment Equipment
---@field Target Unit
---@field Mouseover Unit
---@field Pet Unit
---@field Totems TotemCollection
---@field IsMoving boolean
---@field FullGCDTime fun(self:Player): number
---@field GCDReadyIn fun(self:Player): number
---@field InInstance fun(self:Player,types?:table<string|integer,string|integer>):boolean
---@field Jump fun(self:Player)

---@type Player
local Player = {
    Id = "player",
}

local function NewPlayer()
    local player = addon.Initializer.NewUnit(Player):WithBuffs("PLAYER|HELPFUL"):WithDebuffs("HARMFUL")
    player.Equipment = addon.Initializer.NewEquipment()
    player.Talents = {}
    player.Target = addon.Initializer.NewUnit({ Id = "target", }):WithBuffs("HELPFUL"):WithDebuffs("PLAYER|HARMFUL")
    player.Mouseover = addon.Initializer.NewUnit({ Id = "mouseover", }):WithBuffs("HELPFUL"):WithDebuffs("RAID|HARMFUL")
    player.Pet = addon.Initializer.NewUnit({ Id = "pet", }):WithBuffs("PLAYER|HELPFUL"):WithDebuffs("HARMFUL")
    player.Totems = addon.Initializer.NewTotemCollection()
    player.IsMoving = false
    addon.Player = player
    return player
end

function Player:GCDReadyIn()
    return addon.Rotation.Spells.Gcd:ReadyIn()
end

local UnitPowerType, max, GetHaste = UnitPowerType, max, GetHaste
function Player:FullGCDTime()
    return (UnitPowerType(self.Id) == Enum.PowerType.Energy and 1 or max(0.75, 1.5 * 100 / (100 + GetHaste())))
end

local select, GetInstanceInfo, GetNumGroupMembers = select, GetInstanceInfo, GetNumGroupMembers
local instanceTypes = addon.Helper.ToHashSet({ "raid", "party", "pvp", "arena", })
function Player:InInstance(types)
    types = types or instanceTypes
    return types[(select(2, GetInstanceInfo()))] ~= nil and GetNumGroupMembers() > 0
end

function Player:Jump()
    local customKeyCommand = addon.Common.Commands.CustomKey
    local jumpKey = addon.Common.PlayerActions.JumpKey
    addon.CmdBus:Add(customKeyCommand.Name, 0.5, jumpKey)
end

-- Was usefull for a dungeon with jump mechanics.
-- hooksecurefunc("JumpOrAscendStart", function(...)
--     local customKeyCommand = addon.Common.Commands.CustomKey
--     addon.CmdBus:Remove(customKeyCommand.Name)
-- end)

-- attach to addon
addon.Initializer.NewPlayer = NewPlayer
