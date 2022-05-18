local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class Player
---@field Buffs AuraCollection
---@field Debuffs AuraCollection
---@field Target Target
---@field FullGCDTime fun(self:Player): number
---@field GCDReadyIn fun(self:Player): number
---@field CastingEndsIn fun(self:Player):number
---@field Resource fun(self:Player, index:integer):number,number
---@field HealthPercent fun(self:Player):number,number
---@field InInstance fun(self:Player):boolean
---@field InCombatWithTarget fun(self:Player):boolean
---@field CanAttackTarget fun(self:Player):boolean
---@field CanDotTarget fun(self:Player):boolean

---@class Target
---@field Buffs AuraCollection
---@field Debuffs AuraCollection

---@type Player
local Player = {
    Rotation = nil,
    Buffs = nil,
    Debuffs = nil,
    Target = {
        Buffs = nil,
        Debuffs = nil,
    },
}

function Player:GCDReadyIn()
    return addon.Rotation.GCDSpell:ReadyIn()
end

local UnitPowerType, max, GetHaste = UnitPowerType, max, GetHaste
function Player:FullGCDTime()
    return (UnitPowerType("player") == 3 and 1 or max(0.75, 1.5 * 100 / (100 + GetHaste())))
end

local function SecFromNow(endTimeMS)
    return endTimeMS / 1000 - addon.Rotation.Timestamp;
end

local UnitCastingInfo, UnitChannelInfo = UnitCastingInfo, UnitChannelInfo
function Player:CastingEndsIn()
    local name, text, texture, startTimeMS, endTimeMS, _, _, notInterruptible, spellId = UnitCastingInfo("player")
    if (not name) then
        name, text, texture, startTimeMS, endTimeMS, _, notInterruptible, spellId = UnitChannelInfo("player")
    end
    return name and SecFromNow(endTimeMS) or 0
end

local UnitPower, UnitPowerMax = UnitPower, UnitPowerMax
---@param index number
---@return number current
---@return number deficit
function Player:Resource(index)
    local total = UnitPowerMax("player", index)
    local current = UnitPower("player", index)
    return current, total - current
end

local UnitHealth, UnitHealthMax = UnitHealth, UnitHealthMax
function Player:HealthPercent()
    local total = UnitHealthMax("player")
    local current = UnitHealth("player")
    local currentPercent = current * 100 / total
    return currentPercent, 100 - currentPercent
end

local select, GetInstanceInfo = select, GetInstanceInfo
local instanceTypes = addon.Helper:ToHashSet({ "raid", "party", "pvp", "arena", })
function Player:InInstance()
    return instanceTypes[(select(2, GetInstanceInfo()))] ~= nil
end

local UnitAffectingCombat = UnitAffectingCombat
function Player:InCombatWithTarget()
    return UnitAffectingCombat("player") or UnitAffectingCombat("target")
end

local UnitCanAttack, UnitIsDead = UnitCanAttack, UnitIsDead
function Player:CanAttackTarget()
    return UnitCanAttack("player", "target") and not UnitIsDead("target")
end

local goodUnitClassifications = addon.Helper:ToHashSet({ "worldboss", "rareelite", "elite", "rare", "normal", })
function Player:CanDotTarget()
    return goodUnitClassifications[UnitClassification("target")] ~= nil
end

addon.Player = Player
