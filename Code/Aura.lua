local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class Aura
---@field Remains number
---@field Stacks integer

---@class AuraCollection
---@field Refresh fun(self:AuraCollection, timestamp?:number)
---@field Find fun(self:AuraCollection, spellId:integer):Aura

local getTime = GetTime
local emptyAura = {
    Remains = 0,
    Stacks = 0,
}

local function UpdateAuras(table, unit, filter, timestamp)
    AuraUtil.ForEachAura(unit, filter, nil, function(name, _, stacks, dispelType, duration, expirationTimestamp, unitCaster, canStealOrPurge, _, spellId, canApplyAura, isBossDebuff, castByPlayer, ...)
        local now = timestamp or getTime()
        local entry = table[spellId] or {
            Remains = nil,
            Stacks = nil,
        }
        entry.Remains = expirationTimestamp - now
        entry.Stacks = stacks
    end)
end

---@param unit string
---@param filter string
---@return AuraCollection
local function NewAuraCollection(unit, filter)
    local newCollection = {
        Auras = {},
        Refresh = function(collection, timestamp)
            local auras = collection.Auras
            for spellId, aura in pairs(auras) do
                aura.Remains = 0
            end
            UpdateAuras(auras, unit, filter, timestamp)
        end,
        Find = function(collection, spellId)
            return collection.Auras[spellId] or emptyAura
        end
    }
    return newCollection
end

addon.Initializer.NewAuraCollection = NewAuraCollection
