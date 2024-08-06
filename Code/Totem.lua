local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class Totem
---@field IconId integer
---@field Name string
---@field Remains number
---@field SpawnTime number
---@field FullDuration number

---@class TotemCollection
---@field Refresh fun(self:TotemCollection, timestamp?:number)
---@field Active fun(self:TotemCollection, icon:integer):boolean
---@field Find fun(self:TotemCollection, icon:integer):Totem
---@field Remains fun(self:TotemCollection, icon:integer):number

local GetTime, pairs, ipairs = GetTime, pairs, ipairs
local MAX_TOTEMS, GetTotemInfo = MAX_TOTEMS, GetTotemInfo
local emptyTotem = {
    IconId = 0,
    Name = "",
    Remains = -1,
    SpawnTime = 0,
    FullDuration = 0,
}

local totemCache = {}
local function UpdateTotems(totems, timestamp)
    for i = 1, MAX_TOTEMS do
        local haveTotem, totemName, startTime, duration, iconId = GetTotemInfo(i)
        if (haveTotem) then
            local now = timestamp or GetTime()
            local totem = totems[iconId]
            if (not totem) then
                totem = totemCache[iconId]
                if (not totem) then
                    totem = {
                        IconId = iconId,
                        Name = nil,
                        Remains = nil,
                        SpawnTime = nil,
                        FullDuration = nil,
                    }
                    totemCache[iconId] = totem
                end
                totems[iconId] = totem
            end
            totem.Name = totemName
            totem.SpawnTime = startTime
            totem.FullDuration = duration
            totem.Remains = startTime + duration - now
        end
    end
end

local lagOffset = 0.15
---@return TotemCollection
local function NewTotemCollection()
    local newCollection = {
        Totems = {},
        Refresh = function(collection, timestamp)
            local totems = collection.Totems
            for iconId, totem in pairs(totems) do
                totems[iconId] = nil
            end
            if (UnitExists("player")) then
                UpdateTotems(totems, timestamp)
            end
        end,
        Find = function(collection, iconId)
            return collection.Totems[iconId]
        end,
        Active = function(collection, iconId)
            local totem = collection.Totems[iconId] or emptyTotem
            return totem.Remains > (addon.SavedSettings.Instance.ActionAdvanceWindow + lagOffset)
        end,
        Remains = function(collection, iconId)
            local totem = collection.Totems[iconId] or emptyTotem
            return totem.Remains - (addon.SavedSettings.Instance.ActionAdvanceWindow + lagOffset)
        end,
    }
    return newCollection
end

-- attach to addon
addon.Initializer.NewTotemCollection = NewTotemCollection
