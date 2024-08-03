local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class Aura
---@field Remains number
---@field Stacks integer
---@field FullDuration number
---@field DispelType string?
---@field CanPurge boolean
---@field Amount number

---@class AuraCollection
---@field Refresh fun(self:AuraCollection, timestamp?:number)
---@field Find fun(self:AuraCollection, spellId:integer):Aura
---@field Applied fun(self:AuraCollection, spellId:integer):boolean
---@field Remains fun(self:AuraCollection, spellId:integer):number
---@field Stacks fun(self:AuraCollection, spellId:integer):integer
---@field HasPurgeable fun(self:AuraCollection):boolean
---@field HasDispelable fun(self:AuraCollection, dispelTypes:table<string,any>):boolean

local GetTime, pairs, ipairs = GetTime, pairs, ipairs
local AuraUtil = AuraUtil
local emptyAura = {
    Remains = -1,
    Stacks = 0,
    FullDuration = 0,
    DispelType = nil,
    CanPurge = false,
}

local auraCache = {}
local function UpdateAuras(auras, unit, filter, timestamp)
    AuraUtil.ForEachAura(unit, filter, nil, function(name, icon, stacks, dispelType, duration, expirationTimestamp, unitCaster, canStealOrPurge, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer, nameplateShowAll, timeMod, ...)
        local now = timestamp or GetTime()
        local aura = auras[spellId]
        if (not aura) then
            aura = auraCache[spellId]
            if (not aura) then
                aura = {
                    Remains = nil,
                    Stacks = nil,
                    FullDuration = nil,
                    DispelType = nil,
                    CanPurge = nil,
                }
                auraCache[spellId] = aura
            end
            auras[spellId] = aura
        end
        aura.Remains = expirationTimestamp > 0 and expirationTimestamp - now or 999999 -- exp is zero for endless aura
        aura.Stacks = stacks
        aura.FullDuration = duration
        aura.DispelType = dispelType -- ["Magic", "Disease", "Poison", "Curse", ""] and nil
        aura.CanPurge = canStealOrPurge
        aura.Amount = ...
    end)
end

local lagOffset = 0.15
---@param unitId UnitId
---@param filter string
---@return AuraCollection
local function NewAuraCollection(unitId, filter)
    local UnitExists = UnitExists
    local newCollection = {
        Auras = {},
        Refresh = function(collection, timestamp)
            local auras = collection.Auras
            for spellId, aura in pairs(auras) do
                auras[spellId] = nil
            end
            if (UnitExists(unitId)) then
                UpdateAuras(auras, unitId, filter, timestamp)
            end
        end,
        Find = function(collection, spellId)
            return collection.Auras[spellId]
        end,
        Applied = function(collection, spellId)
            local aura = collection.Auras[spellId] or emptyAura
            return aura.Remains > (addon.SavedSettings.Instance.ActionAdvanceWindow + lagOffset)
        end,
        Remains = function(collection, spellId)
            local aura = collection.Auras[spellId] or emptyAura
            return aura.Remains - (addon.SavedSettings.Instance.ActionAdvanceWindow + lagOffset)
        end,
        Stacks = function(collection, spellId)
            local aura = collection.Auras[spellId] or emptyAura
            return (aura.Remains > (addon.SavedSettings.Instance.ActionAdvanceWindow + lagOffset)) and aura.Stacks or 0
        end,
        HasPurgeable = function(collection)
            local auras = collection.Auras
            for spellId, aura in pairs(auras) do
                if (aura.Remains > 1 and aura.CanPurge) then
                    return true
                end
            end
            return false
        end,
        HasDispelable = function(collection, dispelTypes)
            local auras = collection.Auras
            for spellId, aura in pairs(auras) do
                if (aura.Remains > 1 and dispelTypes[aura.DispelType]) then
                    return true
                end
            end
            return false
        end,
    }
    return newCollection
end

-- attach to addon
addon.Initializer.NewAuraCollection = NewAuraCollection
