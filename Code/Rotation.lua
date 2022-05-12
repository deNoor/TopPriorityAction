local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class Rotation
---@field Timestamp number
---@field Pulse fun():Spell
---@field EmptySpell Spell

---@type Rotation
local emptySpell = { Id = -1, Key = "", }
local emptyRotation = {
    Pulse = function()
        return emptySpell
    end,
    EmptySpell = emptySpell,
}
function addon:DetectRotation()
    local class = UnitClassBase("player")
    local specIndex = GetSpecialization()
    local knownClass = addon.WowClass[class]
    local knownRotation = knownClass[specIndex] ---@type Rotation
    if (not knownRotation) then
        addon.Helper:Print({ "unknown spec", class, specIndex, })
        return
    end
    local rotation = knownRotation or emptyRotation
    rotation.EmptySpell = emptySpell
    addon.Rotation = rotation
end

addon.Rotation = emptyRotation
