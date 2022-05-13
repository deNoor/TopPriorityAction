local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class Rotation
---@field Spells table<string, Spell>
---@field Timestamp number               @updated by framework on Pulse call.
---@field Settings Settings              @updated by framework on rotation load.
---@field EmptySpell Spell               @updated by framework on init.
---@field PauseTimestamp number          @updated by framework on events outside rotation.
---@field IsPauseKeyDown boolean         @updated by framework on events outside rotation, MODIFIER_STATE_CHANGED
---@field AddedPauseOnKey integer
---@field Pulse fun(self:Rotation):Spell
---@field ShouldNotRun fun(self:Rotation):boolean
---@field Activate fun(self:Rotation)
---@field Dispose fun(self:Rotation)

---@type Rotation
local emptySpell = { Id = -1, Key = "", }
local emptyRotation = {
    Pulse = function(rotation) return rotation.EmptySpell end,
    ShouldNotRun = function(_) return true end,
    Activate = function(_) end,
    Dispose = function(_) end,
    EmptySpell = emptySpell,
    Spells = {},
    Timestamp = 0,
    PauseTimestamp = 0,
    IsPauseKeyDown = false,
    AddedPauseOnKey = 0,
    Settings = nil,
}

---@param self Rotation
---@return boolean
local SpellIsTargeting, IsMounted, UnitIsDeadOrGhost = SpellIsTargeting, IsMounted, UnitIsDeadOrGhost
local function ShouldNotRun(self)
    return not self.Settings.Enabled
        or self.IsPauseKeyDown
        or self.PauseTimestamp - self.Timestamp > 0
        or UnitIsDeadOrGhost("player")
        or UnitIsPossessed("player")
        or SpellIsTargeting()
        or IsMounted()
        or ACTIVE_CHAT_EDIT_BOX
end

local IsPauseKeyDown = IsRightControlKeyDown
---@param rotation Rotation
local function SetDefaults(rotation)
    rotation.EmptySpell = emptySpell
    rotation.Timestamp = 0
    rotation.PauseTimestamp = 0
    rotation.IsPauseKeyDown = IsPauseKeyDown()
    rotation.AddedPauseOnKey = 2
    rotation.ShouldNotRun = ShouldNotRun
    rotation.Settings = addon.SavedSettings.Instance
end

function addon:DetectRotation()
    local class = UnitClassBase("player")
    local specIndex = GetSpecialization()
    local knownClass = addon.WowClass[class]
    local knownRotation = knownClass[specIndex] ---@type Rotation

    local currentRotation = addon.Rotation or emptyRotation
    if (currentRotation.Dispose) then
        currentRotation:Dispose()
    end

    if (not knownRotation) then
        addon.Helper:Print({ "unknown spec", class, specIndex, })
        addon.Rotation = emptyRotation
        return
    end

    if(addon.Rotation == knownRotation) then
        return
    end

    SetDefaults(knownRotation)
    if (knownRotation.Activate) then
        knownRotation:Activate()
    end
    addon.Rotation = knownRotation
end

addon.Rotation = emptyRotation
