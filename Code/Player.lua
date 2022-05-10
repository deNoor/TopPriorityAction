local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class Player
---@field Rotation Rotation
---@field DetectRotation fun():Player

---@type Player
local Player = {
    Rotation = nil,
}

---@type Rotation
local empryRotation = {
    Pulse = function()
        return { Id = -1, Key = "", }
    end
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

---@class Rotation
---@field Timestamp number
---@field Pulse fun():Spell
