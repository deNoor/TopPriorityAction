local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class Rotation
---@field Spells table<string, Spell>
---@field Talents integer[]
---@field Timestamp number               @updated by framework on Pulse call.
---@field Settings Settings              @updated by framework on rotation load.
---@field EmptySpell Spell               @updated by framework on init.
---@field GCDSpell Spell                 @updated by framework on init.
---@field PauseTimestamp number          @updated by framework on events outside rotation.
---@field IsPauseKeyDown boolean         @updated by framework on events outside rotation, MODIFIER_STATE_CHANGED
---@field AddedPauseOnKey integer
---@field RangeChecker Spell
---@field Pulse fun(self:Rotation):Spell
---@field ShouldNotRun fun(self:Rotation):boolean
---@field Activate fun(self:Rotation)
---@field Dispose fun(self:Rotation)

---@type Spell
local emptySpell = { Id = -1, Name = "Empty", Key = "", }
---@type Rotation
local emptyRotation = {
    Pulse = function(rotation) return rotation.EmptySpell end,
    ShouldNotRun = function(_) return true end,
    Activate = function(_) end,
    Dispose = function(_) end,
    Spells = {},
    Talents = {},
    Timestamp = 0,
    Settings = nil,
    EmptySpell = emptySpell,
    GCDSpell = nil,
    PauseTimestamp = 0,
    IsPauseKeyDown = false,
    AddedPauseOnKey = 0,
    RangeChecker = emptySpell,
}

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
    rotation.EmptySpell = emptySpell
    rotation.GCDSpell = addon.Initializer.NewSpell({ Id = 61304, })
    rotation.Spells = {}
    rotation.Talents = {}
    rotation.Timestamp = 0
    rotation.PauseTimestamp = 0
    rotation.IsPauseKeyDown = IsPauseKeyDown()
    rotation.AddedPauseOnKey = 2
    rotation.ShouldNotRun = ShouldNotRun
end

function addon:AddRotation(class, spec, spells, rotation)
    rotation = rotation or addon.Helper:Throw({ "attempt to add nil rotation for", class, spec })
    SetDefaults(rotation)
    spells = spells or addon.Helper:Throw({ "attempt to add nil spells for", class, spec })
    for name, spell in pairs(spells) do
        addon.Initializer.NewSpell(spell)
    end
    rotation.Spells = spells
    self.WowClass[class] = { [spec] = rotation }
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
        addon.Shared.RangeCheckSpell = emptySpell
        return
    end

    knownRotation.Settings = addon.SavedSettings.Instance -- runtime value, cannot be set statically
    if (knownRotation.Activate) then
        knownRotation:Activate()
    end
    addon.Rotation = knownRotation
end

local GetActiveSpecGroup, GetTalentInfo, GetAllSelectedPvpTalentIDs = GetActiveSpecGroup, GetTalentInfo, C_SpecializationInfo.GetAllSelectedPvpTalentIDs
function addon:UpdateTalents()
    local rotation = self.Rotation
    if (rotation == emptyRotation) then
        return
    end
    local talents = rotation.Talents
    wipe(talents)
    local specGroupIndex = GetActiveSpecGroup()
    for tier = 1, MAX_TALENT_TIERS do
        for column = 1, NUM_TALENT_COLUMNS do
            local talentID, name, texture, selected, available, spellID = GetTalentInfo(tier, column, specGroupIndex)
            if (selected) then
                talents[talentID] = true
            end
        end
    end
    for slotN, talentID in ipairs(GetAllSelectedPvpTalentIDs()) do
        talents[talentID] = true
    end
end

addon.Rotation = emptyRotation
