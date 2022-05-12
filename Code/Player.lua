local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class Player
---@field Buffs AuraCollection
---@field Debuffs AuraCollection
---@field Target Target

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

addon.Player = Player
