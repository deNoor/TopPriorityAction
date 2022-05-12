local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class Player
---@field Rotation Rotation
---@field DetectRotation fun():Player
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

---@class Rotation
---@field Timestamp number
---@field Pulse fun():Spell
---@field EmptySpell Spell

---@type Rotation
local emptySpell = { Id = -1, Key = "", }
local empryRotation = {
    Pulse = function()
        return { Id = -1, Key = "", }
    end,
    EmptySpell = emptySpell,
}
function Player:DetectRotation()
    local class = UnitClassBase("player")
    local specIndex = GetSpecialization()
    local knownClass = addon.WowClass[class]
    local knownRotation = knownClass[specIndex] ---@type Rotation
    if (not knownRotation) then
        addon.Helper:Print({ "unknown spec", class, specIndex, })
        return
    end
    self.Rotation = knownRotation or empryRotation
    return self
end

addon.Player = Player
