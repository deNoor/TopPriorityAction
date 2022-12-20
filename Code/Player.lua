local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class Player
---@field Talents table<integer,boolean>
---@field Equipment Equipment
---@field Buffs AuraCollection
---@field Debuffs AuraCollection
---@field Target Target
---@field Mouseover Mouseover
---@field FullGCDTime fun(self:Player): number
---@field GCDReadyIn fun(self:Player): number
---@field CastingEndsIn fun(self:Player):number
---@field NowCasting fun(self:Player):integer,number @spellId, endsInSec
---@field Resource fun(self:Player, index:integer):number,number @current, deficit
---@field ResourcePercent fun(self:Player, index:integer):number,number @current, deficit
---@field Health fun(self:Player):number,number @current, deficit
---@field HealthPercent fun(self:Player):number,number @current, deficit
---@field HealAbsorb fun(self:Player):number
---@field InInstance fun(self:Player):boolean
---@field InCombatWithTarget fun(self:Player):boolean
---@field CanAttackTarget fun(self:Player):boolean
---@field CanDotTarget fun(self:Player):boolean

---@class Target
---@field Buffs AuraCollection
---@field Debuffs AuraCollection
---@field IsTotem fun(self:Target):boolean

---@class Mouseover
---@field Buffs AuraCollection
---@field Debuffs AuraCollection
---@field IsTotem fun(self:Target):boolean

---@type Player
local Player = {
    Equipment = {},
    Talents = {},
    Buffs = nil,
    Debuffs = nil,
    Target = {
        Buffs = nil,
        Debuffs = nil,
        IsTotem = nil,
    },
    Mouseover = {
        Buffs = nil,
        Debuffs = nil,
        IsTotem = nil,
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
function Player:NowCasting()
    local name, text, texture, startTimeMS, endTimeMS, _, _, notInterruptible, spellId = UnitCastingInfo("player")
    if (not name) then
        name, text, texture, startTimeMS, endTimeMS, _, notInterruptible, spellId = UnitChannelInfo("player")
    end
    if (spellId) then
        return spellId, SecFromNow(endTimeMS)
    else
        return 0, 0
    end
end

function Player:CastingEndsIn()
    local spellId, endsInSec = self:NowCasting()
    return endsInSec
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

---@param index number
---@return number current
---@return number deficit
function Player:ResourcePercent(index)
    local total = UnitPowerMax("player", index)
    local current = UnitPower("player", index)
    local currentPercent = current * 100 / total
    return currentPercent, 100 - currentPercent
end

local UnitHealth, UnitHealthMax = UnitHealth, UnitHealthMax
function Player:HealthPercent()
    local total = UnitHealthMax("player")
    local current = UnitHealth("player")
    local currentPercent = current * 100 / total
    return currentPercent, 100 - currentPercent
end

function Player:Health()
    local total = UnitHealthMax("player")
    local current = UnitHealth("player")
    return current, total - current
end

local UnitGetTotalHealAbsorbs = UnitGetTotalHealAbsorbs
function Player:HealAbsorb()
    return UnitGetTotalHealAbsorbs("player")
end

local select, GetInstanceInfo = select, GetInstanceInfo
local instanceTypes = addon.Helper.ToHashSet({ "raid", "party", "pvp", "arena", })
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

local UnitClassification, UnitCreatureType = UnitClassification, UnitCreatureType
local goodUnitClassifications = addon.Helper.ToHashSet({ "worldboss", "rareelite", "elite", "rare", "normal", })
local badCreatureTypes = addon.Helper.ToHashSet({ "Totem", }) -- "Not specified",
function Player.Target:IsTotem()
    return badCreatureTypes[UnitCreatureType("target")] ~= nil
end

function Player.Mouseover:IsTotem()
    return badCreatureTypes[UnitCreatureType("target")] ~= nil
end

function Player:CanDotTarget()
    return goodUnitClassifications[UnitClassification("target")] ~= nil and not self.Target:IsTotem()
end

-- attach to addon
addon.Player = Player
