local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class Rotation
---@field Name string
---@field Spells table<string, Spell>
---@field Items table<string, Item>
---@field Timestamp number @updated by framework before Pulse call.
---@field Settings Settings @updated by framework on rotation load.
---@field WaitForResource boolean @set by custom rotation
---@field GCDSpell Spell @updated by framework on init.
---@field PauseTimestamp number @updated by eventTracker outside rotation.
---@field IsPauseKeyDown boolean @updated by eventTracker outside rotation, MODIFIER_STATE_CHANGED, IsRightControlKeyDown
---@field AddedPauseOnKey integer @constant from defaults
---@field RangeChecker Spell @must be configured by custom rotation
---@field RunPriorityList fun(self:Rotation, priorityList:(fun():Action)[]):Rotation @framework implements
---@field Pulse fun(self:Rotation):Action @framework implements and exposes to addon, do not call in custom rotation
---@field SelectAction fun(self:Rotation):Rotation @abstract, custom rotation must override
---@field Activate fun(self:Rotation) @virtual, custom rotation may override
---@field Dispose fun(self:Rotation) @virtual, custom rotation may override

local abstractMethods = { "SelectAction", }

local pairs, ipairs = pairs, ipairs

local emptyAction = addon.Initializer.Empty.Action
local emptyRotation = addon.Initializer.Empty.Rotation

---@type Rotation
local Rotation = {
    SelectedAction = nil, ---@type Action
    Activate = function(_) end,
    Dispose = function(_) end,
}


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

---comment
---@param priorityList (fun():Action)[]
---@return Rotation
function Rotation:RunPriorityList(priorityList)
    if (self.SelectedAction) then
        return self
    end
    for i, func in ipairs(priorityList) do
        local action = func()
        if (action) then
            if (action:IsAvailable()) then
                local usable, noMana = action:IsUsableNow()
                if (self.WaitForResource) then
                    if (usable or noMana) then
                        self.SelectedAction = noMana and emptyAction or action
                        return self
                    end
                else
                    if (usable) then
                        self.SelectedAction = action
                        return self
                    end
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

local actionTypeSwitches = {} -- class level
function Rotation:WaitForOpportunity()
    local switch = actionTypeSwitches[self] -- instance level
    if (not switch) then
        actionTypeSwitches[self] = {
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
        switch = actionTypeSwitches[self]
    end
    local action = self.SelectedAction
    if (action) then
        local case = switch[action.Type]
        if (case) then
            case()
        else
            addon.Helper.Print({ "Undefined swith label", action.Type, })
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
    addon.Helper.AddVirtualMethods(rotation, Rotation)
    rotation:VerifyAbstractsOverriden():SetDefaults():AddSpells(class, spec):AddItems(class, spec)
    if (not self.WowClass[class]) then
        self.WowClass[class] = {}
    end
    if (self.WowClass[class][spec]) then
        addon.Helper.Throw({ "Attempt to overwrite rotation for", class, spec, })
    end
    self.WowClass[class][spec] = rotation
end

local lastSpec = nil
local IsPauseKeyDown = IsRightControlKeyDown
function addon:DetectRotation()
    local specIndex = GetSpecialization()
    if (specIndex and specIndex == lastSpec) then
        return
    end
    local class = UnitClassBase("player")
    local knownClass = addon.WowClass[class]
    local knownRotation = knownClass and knownClass[specIndex] or nil ---@type Rotation

    local currentRotation = addon.Rotation or emptyRotation
    addon.Rotation = emptyRotation
    addon.Shared.RangeCheckSpell = emptyAction
    currentRotation:Dispose()

    if (not knownRotation) then
        addon.Helper.Print({ "unknown spec", class, specIndex, })
    else
        addon:UpdateKnownSpells()
        addon:UpdateTalents()
        addon:UpdateEquipment()
        knownRotation:Activate()
        addon.Shared.RangeCheckSpell = knownRotation.RangeChecker or emptyAction
        knownRotation.IsPauseKeyDown = IsPauseKeyDown()
        knownRotation.Settings = addon.SavedSettings.Instance
        addon.Rotation = knownRotation
    end
    lastSpec = specIndex
end

function Test()
    return addon.Rotation
end

-- attach to addon
addon.Rotation = emptyRotation
