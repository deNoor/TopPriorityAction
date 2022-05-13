local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class Rotation
---@field Timestamp number               @updated by framework on Pulse call.
---@field Settings Settings              @updated by framework on rotation load.
---@field EmptySpell Spell               @updated by framework on init.
---@field PauseTimestamp number          @updated by framework on events outside rotation.
---@field Pulse fun(self:Rotation):Spell
---@field Activate fun(self:Rotation)
---@field Dispose fun(self:Rotation)

---@type Rotation
local emptySpell = { Id = -1, Key = "", }
local emptyRotation = {
    Pulse = function(rotation) return rotation.EmptySpell end,
    Activate = function(_) end,
    Dispose = function(_) end,
    EmptySpell = emptySpell,
    PauseTimestamp = 0,
}
function addon:DetectRotation()
    local class = UnitClassBase("player")
    local specIndex = GetSpecialization()
    local knownClass = addon.WowClass[class]
    local knownRotation = knownClass[specIndex] ---@type Rotation
    if (not knownRotation) then
        addon.Helper:Print({ "unknown spec", class, specIndex, })
    end
    local currentRotation = addon.Rotation or emptyRotation
    if (currentRotation.Dispose) then
        currentRotation:Dispose()
    end
    local newRotation = knownRotation or emptyRotation
    newRotation.EmptySpell = emptySpell
    newRotation.PauseTimestamp = 0
    newRotation.Settings = addon.SavedSettings.Instance
    if (newRotation.Activate) then
        newRotation:Activate()
    end
    addon.Rotation = newRotation
end

addon.Rotation = emptyRotation
