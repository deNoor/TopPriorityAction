local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class Rotation
---@field Spells table<string, Spell>
---@field Items table<string, Item>
---@field Timestamp number @updated by framework on Pulse call.
---@field Settings Settings @updated by framework on rotation load.
---@field GCDSpell Spell @updated by framework on init.
---@field PauseTimestamp number @updated by framework on events outside rotation.
---@field IsPauseKeyDown boolean @updated by framework on events outside rotation, MODIFIER_STATE_CHANGED, IsRightControlKeyDown
---@field AddedPauseOnKey integer @constant from defaults
---@field RangeChecker Spell @must be configured by custom rotation
---@field SelectedAction Action @updated by framework
---@field CurrentPriorityList (fun():Action)[] @variable during rotation run
---@field RunPriorityList fun(self:Rotation):Rotation @framework implements
---@field Pulse fun(self:Rotation):Action @framework implements
---@field ReduceActionSpam fun(self:Rotation):Rotation @framework implements
---@field WaitForOpportunity fun(self:Rotation):Rotation @framework implements
---@field ShouldNotRun fun(self:Rotation):boolean @framework implements
---@field SelectAction fun(self:Rotation):Rotation @custom rotation overrides
---@field Activate fun(self:Rotation) @custom rotation overrides
---@field Dispose fun(self:Rotation) @custom rotation overrides

local abstractMethods = { "SelectAction", "Activate", "Dispose", }

local pairs, ipairs = pairs, ipairs

local emptyAction = addon.Initializer.Empty.Action
local emptyRotation = addon.Initializer.Empty.Rotation

---@type Rotation
local Rotation = {}


function Rotation:VerifyAbstractsOverriden(class, spec)
    local notOverriden = {}
    for index, methodName in ipairs(abstractMethods) do
        if (not self[methodName]) then
            tinsert(notOverriden, methodName)
        end
    end
    if (#notOverriden > 0) then
        addon.Helper.Throw({ class, spec, "forgot to override", table.concat(notOverriden, " "), })
    end
    return self
end

function Rotation:SetDefaults()
    self.GCDSpell = addon.Initializer.NewSpell({ Id = 61304, })
    self.Timestamp = 0
    self.PauseTimestamp = 0
    self.IsPauseKeyDown = false
    self.AddedPauseOnKey = 2
    self.CurrentPriorityList = {}
    return self
end

---@param self Rotation
---@return boolean
local
SpellIsTargeting, GetCursorInfo, IsMounted, UnitIsDeadOrGhost, UnitIsPossessed, UnitOnTaxi, HasOverrideActionBar =
SpellIsTargeting, GetCursorInfo, IsMounted, UnitIsDeadOrGhost, UnitIsPossessed, UnitOnTaxi, HasOverrideActionBar
function Rotation:ShouldNotRun()
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

function Rotation:RunPriorityList()
    if (self.SelectedAction) then
        return self
    end
    for i, func in ipairs(self.CurrentPriorityList) do
        local action = func()
        if (action) then
            if (action:IsAvailable()) then
                local usable, noMana = action:IsUsableNow()
                if (usable or noMana) then
                    self.SelectedAction = noMana and emptyAction or action
                    return self
                end
            end
        end
    end
    return self
end

function Rotation:ReduceActionSpam()
    local action = self.SelectedAction
    if (action and action:IsQueued()) then
        self.SelectedAction = emptyAction
    end
    return self
end

local actionTypeSwitch
function Rotation:WaitForOpportunity()
    actionTypeSwitch = actionTypeSwitch or {
        Empty = function() end,
        Spell = function()
            local spell = self.SelectedAction ---@type Spell
            if (not spell.NoGCD and addon.Player:GCDReadyIn() > self.Settings.ActionAdvanceWindow) then
                self.SelectedAction = emptyAction
            end
        end,
        EquipItem = function()
            local item = self.SelectedAction ---@type EquipItem
            if (addon.Player:CastingEndsIn() > 0) then
                self.SelectedAction = emptyAction
            end
        end,
        Item = function()
            local item = self.SelectedAction ---@type Item
            if (addon.Player:CastingEndsIn() > 0) then
                self.SelectedAction = emptyAction
            end
        end,
    }
    local action = self.SelectedAction
    if (action) then
        local case = actionTypeSwitch[action.Type]
        if (case) then
            case()
        else
            addon.Helper.Print({ "Indefined swith label", action.Type })
        end
    end
    return self
end

function Rotation:Pulse()
    if self:ShouldNotRun() then
        return emptyAction
    end
    self.SelectedAction = nil
    self:SelectAction()
    self:ReduceActionSpam():WaitForOpportunity()
    return self.SelectedAction or emptyAction
end

function Rotation:AddSpells(class, spec)
    local spells = self.Spells or addon.Helper.Throw({ "attempt to add nil spells for", class, spec })
    for name, spell in pairs(spells) do
        addon.Initializer.NewSpell(spell)
    end
    return self
end

function Rotation:AddItems(class, spec)
    local items = self.Items or addon.Helper.Throw({ "attempt to add nil items for", class, spec })
    for name, item in pairs(items) do
        addon.Initializer.NewItem(item)
    end
    return self
end

function addon:AddRotation(class, spec, rotation)
    rotation = rotation or addon.Helper.Throw({ "attempt to add nil rotation for", class, spec })
    addon.Helper.AddMethods(rotation, Rotation)
    rotation:VerifyAbstractsOverriden():SetDefaults():AddSpells(class, spec):AddItems(class, spec)
    self.WowClass[class] = { [spec] = rotation }
end

local IsPauseKeyDown = IsRightControlKeyDown
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
    knownRotation.IsPauseKeyDown = IsPauseKeyDown()
    knownRotation.Settings = addon.SavedSettings.Instance
    addon.Rotation = knownRotation
end

-- attach to addon
addon.Rotation = emptyRotation
