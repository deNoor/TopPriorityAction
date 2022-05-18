local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class Aura
---@field Remains number
---@field Stacks integer
---@field DispelType string?
---@field CanPurge boolean

---@class AuraCollection
---@field Refresh fun(self:AuraCollection, timestamp?:number)
---@field Find fun(self:AuraCollection, spellId:integer):Aura
---@field Applied fun(self:AuraCollection, spellId:integer):boolean
---@field Remains fun(self:AuraCollection, spellId:integer):number
---@field HasPurgeable fun(self:AuraCollection):boolean
---@field HasDispelable fun(self:AuraCollection, dispelTypes:table<string,any>):boolean

local getTime = GetTime
local emptyAura = {
    Remains = -1,
    Stacks = 0,
    FullDuration = 0,
    DispelType = nil,
    CanPurge = false,
}

local function UpdateAuras(auras, unit, filter, timestamp)
    AuraUtil.ForEachAura(unit, filter, nil, function(name, _, stacks, dispelType, duration, expirationTimestamp, unitCaster, canStealOrPurge, _, spellId, canApplyAura, isBossDebuff, castByPlayer, ...)
        local now = timestamp or getTime()
        local entry = auras[spellId] or {
            Remains = nil,
            Stacks = nil,
            FullDuration = nil,
            DispelType = nil,
            CanPurge = nil,
        }
        entry.Remains = expirationTimestamp > 0 and expirationTimestamp - now or 999999 -- exp is zero for endless aura
        entry.Stacks = stacks
        entry.FullDuration = duration
        entry.DispelType = dispelType -- ["Magic", "Disease", "Poison", "Curse", ""] and nil
        entry.CanPurge = canStealOrPurge
        auras[spellId] = entry
    end)
end

---@param unit string
---@param filter string
---@return AuraCollection
local function NewAuraCollection(unit, filter)
    local UnitExists = UnitExists
    local newCollection = {
        Auras = {},
        Refresh = function(collection, timestamp)
            local auras = collection.Auras
            for spellId, aura in pairs(auras) do
                auras[spellId] = nil
            end
            if (UnitExists(unit)) then
                UpdateAuras(auras, unit, filter, timestamp)
            end
        end,
        Find = function(collection, spellId)
            return collection.Auras[spellId]
        end,
        Applied = function(collection, spellId)
            return collection.Auras[spellId] ~= nil
        end,
        Remains = function(collection, spellId)
            local aura = collection.Auras[spellId] or emptyAura
            return aura.Remains
        end,
        HasPurgeable = function(collection)
            local auras = collection.Auras
            for spellId, aura in pairs(auras) do
                if (aura.CanPurge) then
                    return true
                end
            end
            return false
        end,
        HasDispelable = function(collection, dispelTypes)
            local auras = collection.Auras
            for spellId, aura in pairs(auras) do
                if (dispelTypes[aura.DispelType]) then
                    return true
                end
            end
            return false
        end,
    }
    return newCollection
end

addon.Initializer.NewAuraCollection = NewAuraCollection
