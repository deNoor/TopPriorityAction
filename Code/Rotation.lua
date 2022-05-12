local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class Rotation
---@field Timestamp number
---@field Pulse fun(self:Rotation):Spell
---@field EmptySpell Spell
---@field Pause number

---@type Rotation
local emptySpell = { Id = -1, Key = "", }
local emptyRotation = {
    Pulse = function(rotation)
        return rotation.EmptySpell
    end,
    EmptySpell = emptySpell,
    Pause = 0,
}
function addon:DetectRotation()
    local class = UnitClassBase("player")
    local specIndex = GetSpecialization()
    local knownClass = addon.WowClass[class]
    local knownRotation = knownClass[specIndex] ---@type Rotation
    if (not knownRotation) then
        addon.Helper:Print({ "unknown spec", class, specIndex, })
    end
    local rotation = knownRotation or emptyRotation
    rotation.EmptySpell = emptySpell
    rotation.Pause = 0
    addon.Rotation = rotation
end

addon.Rotation = emptyRotation
