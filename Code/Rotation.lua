local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class Rotation
---@field Spells table<string, Spell>
---@field Items table<string, Item>
---@field Timestamp number               @updated by framework on Pulse call.
---@field Settings Settings              @updated by framework on rotation load.
---@field GCDSpell Spell                 @updated by framework on init.
---@field PauseTimestamp number          @updated by framework on events outside rotation.
---@field IsPauseKeyDown boolean         @updated by framework on events outside rotation, MODIFIER_STATE_CHANGED
---@field AddedPauseOnKey integer
---@field RangeChecker Spell
---@field Pulse fun(self:Rotation):Action
---@field ShouldNotRun fun(self:Rotation):boolean
---@field Activate fun(self:Rotation)
---@field Dispose fun(self:Rotation)

local pairs, ipairs = pairs, ipairs

local emptyAction = addon.Initializer.Empty.Action
local emptyRotation = addon.Initializer.Empty.Rotation

---@param self Rotation
---@return boolean
local
SpellIsTargeting, GetCursorInfo, IsMounted, UnitIsDeadOrGhost, UnitIsPossessed, UnitOnTaxi, HasOverrideActionBar =
SpellIsTargeting, GetCursorInfo, IsMounted, UnitIsDeadOrGhost, UnitIsPossessed, UnitOnTaxi, HasOverrideActionBar
local function ShouldNotRun(self)
    return not self.Settings.Enabled
        or not self.RangeChecker.Name
        or self.IsPauseKeyDown
        or self.PauseTimestamp - self.Timestamp > 0
        or UnitIsDeadOrGhost("player")
        or UnitIsPossessed("player")
        or SpellIsTargeting()
        or GetCursorInfo()
        or IsMounted()
        or HasOverrideActionBar()
        or UnitOnTaxi("player")
        or ACTIVE_CHAT_EDIT_BOX
end

local IsPauseKeyDown = IsRightControlKeyDown
---@param rotation Rotation
local function SetDefaults(rotation)
    rotation.GCDSpell = addon.Initializer.NewSpell({ Id = 61304, })
    rotation.Spells = {}
    rotation.Items = {}
    rotation.Timestamp = 0
    rotation.PauseTimestamp = 0
    rotation.IsPauseKeyDown = IsPauseKeyDown()
    rotation.AddedPauseOnKey = 2
    rotation.ShouldNotRun = ShouldNotRun
end

function addon:AddRotation(class, spec, spells, items, rotation)
    rotation = rotation or addon.Helper.Throw({ "attempt to add nil rotation for", class, spec })
    SetDefaults(rotation)
    spells = spells or addon.Helper.Throw({ "attempt to add nil spells for", class, spec })
    for name, spell in pairs(spells) do
        addon.Initializer.NewSpell(spell)
    end
    rotation.Spells = spells
    items = items or addon.Helper.Throw({ "attempt to add nil items for", class, spec })
    for name, item in pairs(items) do
        addon.Initializer.NewItem(item)
    end
    rotation.Items = items
    self.WowClass[class] = { [spec] = rotation }
end

function addon:DetectRotation()
    local class = UnitClassBase("player")
    local specIndex = GetSpecialization()
    local knownClass = addon.WowClass[class]
    local knownRotation = knownClass and knownClass[specIndex] or nil ---@type Rotation

    local currentRotation = addon.Rotation or emptyRotation
    if (currentRotation.Dispose) then
        currentRotation:Dispose()
    end

    if (not knownRotation) then
        addon.Helper.Print({ "unknown spec", class, specIndex, })
        addon.Rotation = emptyRotation
        addon.Shared.RangeCheckSpell = emptyAction
        return
    end

    addon:UpdateKnownSpells()
    addon:UpdateTalents()
    addon:UpdateEquipment()
    if (knownRotation.Activate) then
        knownRotation:Activate()
    end
    addon.Shared.RangeCheckSpell = knownRotation.RangeChecker or emptyAction
    addon.Rotation = knownRotation
end

-- attach to addon
addon.Rotation = emptyRotation
