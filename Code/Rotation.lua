local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class Rotation
---@field Name string
---@field Spells table<string, Spell>
---@field Items table<string, Item>
---@field Settings Settings @updated by framework on rotation load.
---@field WaitForResource boolean @set by custom rotation
---@field PauseTimestamp number @updated by eventTracker outside rotation.
---@field IsPauseKeyDown boolean @updated by eventTracker outside rotation, MODIFIER_STATE_CHANGED, IsRightControlKeyDown
---@field AddedPauseOnKey integer @constant from defaults
---@field RangeChecker Spell @must be configured by custom rotation
---@field GcdReadyIn number
---@field VerifyAbstractsOverriden fun(self:Rotation, class:string, spec:integer):Rotation @keep unchanged
---@field SetDefaults fun(self:Rotation):Rotation @keep unchanged
---@field AddSpells fun(self:Rotation, class:string, spec:integer):Rotation @keep unchanged
---@field AddItems fun(self:Rotation, class:string, spec:integer):Rotation @keep unchanged
---@field RunPriorityList fun(self:Rotation, priorityList:(fun():Action)[]):Rotation @framework implements
---@field Pulse fun(self:Rotation):PlayerAction @framework implements and exposes to addon, do not call in custom rotation
---@field SelectAction fun(self:Rotation) @abstract, custom rotation must override
---@field Activate fun(self:Rotation) @virtual, custom rotation may override
---@field Dispose fun(self:Rotation) @virtual, custom rotation may override

local abstractMethods = { "SelectAction", }

local pairs, ipairs = pairs, ipairs

local emptyAction = addon.Initializer.Empty.Action
local emptyRotation = addon.Initializer.Empty.Rotation

---@type Rotation
local Rotation = {
    SelectedAction = nil, ---@type Spell|Item|Action|PlayerAction|EquipItem
    Activate = function(_)
    end,
    Dispose = function(_)
    end,
}

---@param class string
---@param spec integer
function Rotation:VerifyAbstractsOverriden(class, spec)
    local notOverriden = {}
    for index, methodName in ipairs(abstractMethods) do
        if (not self[methodName]) then
            tinsert(notOverriden, methodName)
        end
    end
    if (#notOverriden > 0) then
        addon.Helper.Throw(class, spec, "forgot to override", table.concat(notOverriden, " "))
    end
    return self
end

function Rotation:SetDefaults()
    self.PauseTimestamp = 0
    self.IsPauseKeyDown = false
    self.AddedPauseOnKey = 1
    self.GcdReadyIn = 0
    return self
end

---@return boolean
local
SpellIsTargeting, GetCursorInfo, IsMounted, UnitIsDeadOrGhost, UnitIsPossessed, UnitOnTaxi, HasVehicleActionBar, HasOverrideActionBar =
    SpellIsTargeting, GetCursorInfo, IsMounted, UnitIsDeadOrGhost, UnitIsPossessed, UnitOnTaxi, HasVehicleActionBar, HasOverrideActionBar
function Rotation:ShouldNotRun()
    return not self.Settings.Enabled
        or self.IsPauseKeyDown
        or self.PauseTimestamp - addon.Timestamp > 0
        or UnitIsDeadOrGhost("player")
        or UnitIsPossessed("player")
        or SpellIsTargeting()
        or GetCursorInfo()
        or IsMounted()
        or HasVehicleActionBar()
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
                local usable, insufficientPower = action:IsUsableNow()
                if (self.WaitForResource and action.Type == "Spell") then
                    if (usable or insufficientPower) then
                        self.SelectedAction = insufficientPower and emptyAction or action
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

local castRules = {}
castRules.InterruptUndesirable = addon.Helper.ToHashSet({
    323764, -- ConvokeTheSpirits
    382135, -- Grieftorch trinket channel
})
castRules.NonBlockingCast = addon.Helper.ToHashSet({

})
castRules.NoWaitCasting = addon.Helper.ToHashSet({
    108853, -- FireBlast talented
    108839, -- IceFloes
})
function Rotation:ActionQueueAwailable()
    if (castRules.NoWaitCasting[self.SelectedAction.Id]) then
        return true
    end
    local spellId, endsInSec, elapsedSec, channeling = addon.Player:NowCasting()
    if (spellId > 0) then
        return castRules.NonBlockingCast[spellId] or (not channeling and endsInSec <= self.Settings.ActionAdvanceWindow)
    end
    return true
end

local buggedCurrentSpellCastDetection = { [330325] = "Condemn", }
---@param action Action
---@return boolean
local function ForcedSpam(action)
    return action.Type == "Spell" and buggedCurrentSpellCastDetection[action.Id] ~= nil
end

function Rotation:ReduceActionSpam()
    local action = self.SelectedAction
    local nowCasting = addon.Player:NowCasting()
    if (action and nowCasting ~= action.Id and (action:IsQueued() or ForcedSpam(action))) then
        self.SelectedAction = emptyAction
    end
    return self
end

local actionTypeSwitches = {}               -- class level
function Rotation:WaitForOpportunity()
    local switch = actionTypeSwitches[self] -- instance level
    if (not switch) then
        actionTypeSwitches[self] = {
            Empty = function()
            end,
            Spell = function()
                local spell = self.SelectedAction ---@type Spell
                if (not self:ActionQueueAwailable() or spell:ReadyIn() > self.Settings.ActionAdvanceWindow) then
                    self.SelectedAction = emptyAction
                end
            end,
            EquipItem = function()
                local item = self.SelectedAction ---@type EquipItem
                if (addon.Player:CastingEndsIn() > 0 or item:ReadyIn() > self.Settings.ActionAdvanceWindow) then
                    self.SelectedAction = emptyAction
                end
            end,
            Item = function()
                local item = self.SelectedAction ---@type Item
                if (addon.Player:CastingEndsIn() > 0 or item:ReadyIn() > self.Settings.ActionAdvanceWindow) then
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
            addon.Helper.Print("Undefined swith label", action.Type)
        end
    end
    return self
end

local currentInRange = false
function Rotation:Pulse()
    addon.Shared:InRangeSet(self.RangeChecker:IsInRange())
    if self:ShouldNotRun() then
        return emptyAction
    end
    self.SelectedAction = nil
    self.GcdReadyIn = addon.Player:GCDReadyIn()
    self:SelectAction()
    self:WaitForOpportunity():ReduceActionSpam()
    local action = self.SelectedAction or emptyAction
    if action ~= emptyAction then
        if (not action.Key) then
            addon.Helper.Print(action.Name, "has no key")
        end
    end
    return action
end

function Rotation:AddSpells(class, spec)
    local spells = self.Spells or addon.Helper.Throw("attempt to add nil spells for", class, spec)
    if (spells ~= addon.Common.Spells) then
        for key, spell in pairs(addon.Common.Spells) do
            spells[key] = spell
        end
    end
    for key, spell in pairs(spells) do
        addon.Initializer.NewSpell(spell)
    end
    return self
end

function Rotation:AddItems(class, spec)
    local items = self.Items or addon.Helper.Throw("attempt to add nil items for", class, spec)
    if (items ~= addon.Common.Items) then
        for key, item in pairs(addon.Common.Items) do
            items[key] = item
        end
    end
    for key, item in pairs(items) do
        addon.Initializer.NewItem(item)
    end
    return self
end

local UnitPowerType = UnitPowerType
local powersWithAutoRegen = addon.Helper.ToHashSet({ Enum.PowerType.Energy, })
function addon:UpdateRotationResource()
    local rotation = addon.Rotation
    if (rotation) then
        rotation.WaitForResource = powersWithAutoRegen[(UnitPowerType("player"))] ~= nil
    end
end

function addon:AddRotation(class, spec, rotation)
    rotation = rotation or addon.Helper.Throw("attempt to add nil rotation for", class, spec)
    addon.Helper.AddVirtualMethods(rotation, Rotation)
    rotation:VerifyAbstractsOverriden(class, spec):SetDefaults():AddSpells(class, spec):AddItems(class, spec)
    if (not self.WowClass[class]) then
        self.WowClass[class] = {}
    end
    if (self.WowClass[class][spec]) then
        addon.Helper.Throw("Attempt to overwrite rotation for", class, spec)
    end
    self.WowClass[class][spec] = rotation
end

local lastSpec = -1
local IsPauseKeyDown = IsRightControlKeyDown
function addon:DetectRotation()
    local specIndex = GetSpecialization()
    if (specIndex and specIndex == lastSpec) then
        return
    end
    local class = UnitClassBase("player")
    local knownClass = addon.WowClass[class]
    local knownRotation = knownClass and knownClass[specIndex] or nil ---@type Rotation?

    local currentRotation = addon.Rotation or emptyRotation
    addon.Rotation = emptyRotation
    addon.Shared:InRangeSet(false)
    currentRotation:Dispose()

    if (not knownRotation) then
        addon.Helper.Print("unknown spec", class, specIndex)
    else
        if (not knownRotation.RangeChecker or knownRotation.RangeChecker.Id < 1) then
            addon.Helper.Print("RangeChecker not defined for rotation ", knownRotation.Name)
        else
            addon.Rotation = knownRotation
            addon:UpdateKnownSpells()
            addon:UpdateEquipment()
            addon:UpdateKnownItems()
            addon:UpdateRotationResource()
            knownRotation.IsPauseKeyDown = IsPauseKeyDown()
            knownRotation.Settings = addon.SavedSettings.Instance
            knownRotation:Activate()
        end
    end
    lastSpec = specIndex
end

-- attach to addon
addon.Rotation = emptyRotation
