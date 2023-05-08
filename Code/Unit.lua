local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class Unit
---@field Id UnitId
---@field Buffs AuraCollection
---@field Debuffs AuraCollection
---@field WithBuffs fun(self:Unit,filter:string):Unit
---@field WithDebuffs fun(self:Unit,filter:string):Unit
---@field IsTotem fun(self:Unit):boolean
---@field CanDot fun(self:Unit):boolean @from Player perspective
---@field CanAttack fun(self:Unit):boolean @from Player perspective
---@field Exists fun(self:Unit):boolean
---@field Dead fun(self:Unit):boolean
---@field InCombatWithMe fun(self:Unit):boolean
---@field CastingEndsIn fun(self:Unit):number
---@field NowCasting fun(self:Unit):integer,number,number,boolean,boolean @spellId, leftSec, elapsedSec, channeling, kickable
---@field CanKick fun(self:Unit, advanced:boolean?):boolean
---@field Resource fun(self:Unit, index:integer):number,number @current, deficit
---@field ResourcePercent fun(self:Unit, index:integer):number,number @current, deficit
---@field Health fun(self:Unit):number,number @current, deficit
---@field HealthPercent fun(self:Unit):number,number @current, deficit
---@field Absorb fun(self:Unit):number @amount
---@field HealAbsorb fun(self:Unit):number @amount
---@field IsFriend fun(self:Unit):boolean @with player
---@field IsEnemy fun(self:Unit):boolean @with player
---@field IsWorthy fun(self:Unit):boolean

---@type Unit
local Unit = {}

---@type UnitId[]
local unitIds = { "player", "target", "mouseover", "pet", }
local knownUnits = addon.Helper.ToHashSet(unitIds)
---@param unit Unit
---@return Unit
local function NewUnit(unit)
    local unit = unit or addon.Helper.Throw("attempt to initialize nil unit")
    if (not knownUnits[unit.Id]) then
        addon.Helper.Throw("attempt to initialize unsupported unitId", unit.Id)
    end
    addon.Helper.AddVirtualMethods(unit, Unit)
    return unit
end

function Unit:WithBuffs(filter)
    self.Buffs = addon.Initializer.NewAuraCollection(self.Id, filter)
    return self
end

function Unit:WithDebuffs(filter)
    self.Debuffs = addon.Initializer.NewAuraCollection(self.Id, filter)
    return self
end

local function SecFromNow(endTimeMS)
    return endTimeMS / 1000 - addon.Rotation.Timestamp;
end

local UnitCastingInfo, UnitChannelInfo = UnitCastingInfo, UnitChannelInfo
---@param unit UnitId
---@return number @spellId
---@return number @timeLeft
---@return number @timeElapsed
---@return boolean @channelling
---@return boolean @kickable
local function NowCasting(unit)
    local channelling = false
    local name, text, texture, startTimeMS, endTimeMS, _, _, notInterruptible, spellId = UnitCastingInfo(unit)
    if (not name) then
        name, text, texture, startTimeMS, endTimeMS, _, notInterruptible, spellId = UnitChannelInfo(unit)
        channelling = true
    end
    if (spellId) then
        return spellId, SecFromNow(endTimeMS), -SecFromNow(startTimeMS), channelling, (notInterruptible == false)
    else
        return 0, 0, 0, false, false
    end
end

local function CastingEndsIn(unit)
    local spellId, endsInSec = NowCasting(unit)
    return endsInSec
end

function Unit:NowCasting()
    return NowCasting(self.Id)
end

function Unit:CastingEndsIn()
    return CastingEndsIn(self.Id)
end

function Unit:CanKick(advanced)
    local _, leftSec, elapsedSec, channeling, kickable = self:NowCasting()
    if (not kickable or leftSec < 0.06 * 2) then -- was 0.06, temp higher for TR ping
        return false
    end
    if (advanced) then
        return channeling or leftSec < 0.55
    else
        return true
    end
end

local UnitPower, UnitPowerMax = UnitPower, UnitPowerMax
---@param index number
---@return number current
---@return number deficit
function Unit:Resource(index)
    local total = UnitPowerMax(self.Id, index)
    local current = UnitPower(self.Id, index)
    return current, total - current
end

---@param index number
---@return number current
---@return number deficit
function Unit:ResourcePercent(index)
    local total = UnitPowerMax(self.Id, index)
    local current = UnitPower(self.Id, index)
    local currentPercent = current * 100 / total
    return currentPercent, 100 - currentPercent
end

local UnitHealth, UnitHealthMax = UnitHealth, UnitHealthMax
function Unit:HealthPercent()
    local total = UnitHealthMax(self.Id)
    if (total <= 0) then
        return 0, 0
    end
    local current = UnitHealth(self.Id)
    local currentPercent = current * 100 / total
    return currentPercent, 100 - currentPercent
end

local UnitExists = UnitExists
function Unit:Exists()
    return UnitExists(self.Id)
end

function Unit:Health()
    local total = UnitHealthMax(self.Id)
    local current = UnitHealth(self.Id)
    return current, total - current
end

local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
function Unit:Absorb()
    return UnitGetTotalAbsorbs(self.Id)
end

local UnitGetTotalHealAbsorbs = UnitGetTotalHealAbsorbs
function Unit:HealAbsorb()
    return UnitGetTotalHealAbsorbs(self.Id)
end

local UnitAffectingCombat = UnitAffectingCombat
function Unit:InCombatWithMe()
    return UnitAffectingCombat("player") or UnitAffectingCombat(self.Id)
end

local UnitCanAttack, UnitIsDead = UnitCanAttack, UnitIsDead
function Unit:CanAttack()
    return UnitCanAttack("player", self.Id) and not UnitIsDead(self.Id)
end

function Unit:Dead()
    return UnitIsDead(self.Id)
end

local UnitClassification, UnitCreatureType = UnitClassification, UnitCreatureType
local goodUnitClassifications = addon.Helper.ToHashSet({ "worldboss", "rareelite", "elite", "rare", "normal", })
local badCreatureTypes = addon.Helper.ToHashSet({ "Totem", "Not specified", })
function Unit:IsTotem()
    return badCreatureTypes[UnitCreatureType(self.Id)] ~= nil
end

local UnitIsBossMob = UnitIsBossMob
function Unit:IsBoss()
    return UnitIsBossMob(self.Id)
end

function Unit:CanDot()
    return (self:IsBoss() or goodUnitClassifications[UnitClassification(self.Id)] ~= nil) and not self:IsTotem()
end

local UnitIsFriend, UnitIsEnemy = UnitIsFriend, UnitIsEnemy
function Unit:IsFriend()
    return UnitIsFriend("player", self.Id)
end

function Unit:IsEnemy()
    return UnitIsEnemy("player", self.Id)
end

local max, GetNumGroupMembers = max, GetNumGroupMembers
function Unit:IsWorthy()
    local classification = UnitClassification(self.Id)
    if (goodUnitClassifications[classification]) then
        local player = addon.Player
        if (not player:InInstance()) then
            return (self:Health() + self:Absorb()) > (UnitHealthMax("player") / 4)
        end
        if (classification == "normal" or classification == "rare") then
            return false
        end
        local groupSize = max(GetNumGroupMembers() or 1, 1)
        return (self:Health() + self:Absorb()) > (UnitHealthMax("player") / 4) * groupSize
    end
    return false
end

-- attach to addon
addon.Initializer.NewUnit = NewUnit
