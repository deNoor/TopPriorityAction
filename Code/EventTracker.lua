local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@alias EventHandler fun(event:string, ...)

---@class EventTracker
---@field FrameHandlers table<string, EventHandler>
---@field CustomHandlers table<string, EventHandler>
---@field EventTimestamp number
---@field private RegisterEvents fun(self:EventTracker):EventTracker
---@field UnRegisterEvent fun(self:EventTracker, event:string):EventTracker
---@field Dispose fun(self:EventTracker)

---@type EventTracker
local EventTracker = {
    EventTimestamp = 0
}
local EventRegistry, C_EventUtils = EventRegistry, C_EventUtils

local addonCallbackRegistry = CreateFromMixins(CallbackRegistryMixin)
addonCallbackRegistry:OnLoad()
addonCallbackRegistry:SetUndefinedEventsAllowed(true)

function EventTracker:RegisterEvents()
    local getTime = GetTime
    for event, handler in pairs(self.FrameHandlers) do
        if (C_EventUtils.IsEventValid(event)) then
            EventRegistry:RegisterFrameEventAndCallback(event, function(ownerId, ...)
                self.EventTimestamp = getTime()
                handler(event, ...)
            end, self)
        else
            addon.Helper.Print("Invalid frame event", event)
        end
    end
    for event, handler in pairs(self.CustomHandlers) do
        if (not C_EventUtils.IsEventValid(event)) then
            EventRegistry:RegisterCallback(event, function(ownerId, ...)
                self.EventTimestamp = getTime()
                handler(event, ...)
            end, self)
        else
            addon.Helper.Print("This event must be registered as frame event", event)
        end
    end
    return self
end

function EventTracker:UnRegisterEvent(event)
    if (self.FrameHandlers[event]) then
        EventRegistry:UnregisterFrameEventAndCallback(event, self)
    elseif (self.CustomHandlers[event]) then
        EventRegistry:UnregisterCallback(event, self)
    else
        addon.Helper.Print("Attempt to unregister unknown event", event)
    end
    return self
end

function EventTracker:Dispose()
    for event, _ in pairs(self.FrameHandlers) do
        EventRegistry:UnregisterFrameEventAndCallback(event, self)
    end
    for event, _ in pairs(self.CustomHandlers) do
        EventRegistry:UnregisterCallback(event, self)
    end
end

local function NewEventTracker(frameHandlers, customHandlers)
    local eventTracker = {
        FrameHandlers = frameHandlers or {},
        CustomHandlers = customHandlers or {},
        EventTimestamp = 0,
    }
    addon.Helper.AddVirtualMethods(eventTracker, EventTracker)
    eventTracker:RegisterEvents()
    return eventTracker
end

-- addon global handlers
local frameHandlers = {}

---loads saved setting
function frameHandlers.ADDON_LOADED(event, ...)
    local name = ...
    if name == addonName then
        addon.EventTracker:UnRegisterEvent(event)
        addon.SavedSettings:Load()
        addon.Convenience:EnableAutoConfirmDelete()
        addon.Convenience:EnableHiddenPendingTicket()
        addon.Convenience:DisableActionBarGlow()
    end
end

function frameHandlers.PLAYER_ENTERING_WORLD(event, ...)
    local initialLogin, reloadingUi = ... -- if not (initialLogin or reloadingUi) then entering an instance
    if (initialLogin or reloadingUi) then
        addon.Initializer.NewPlayer()
    end
    addon:DetectRotation()
end

function frameHandlers.PLAYER_SPECIALIZATION_CHANGED(event, ...)
    addon:DetectRotation()
end

function frameHandlers.PLAYER_EQUIPMENT_CHANGED(event, ...)
    addon:UpdateEquipment()
end

-- fired after spec change, talent change, spellbook change
function frameHandlers.SPELLS_CHANGED(event, ...)
    addon:UpdateKnownSpells()
end

function frameHandlers.UNIT_DISPLAYPOWER(event, ...)
    local unitId = ...
    if (unitId == "player") then
        addon:UpdateRotationResource()
    end
end

function frameHandlers.MODIFIER_STATE_CHANGED(event, ...)
    local key, isPressed = ...
    if (key == "RCTRL") then
        local rotation = addon.Rotation
        if (isPressed == 1) then
            rotation.IsPauseKeyDown = true
            rotation.PauseTimestamp = EventTracker.EventTimestamp + rotation.AddedPauseOnKey
        elseif (isPressed == 0) then
            rotation.IsPauseKeyDown = false
        end
    end
end

local GetUnitName, C_ChallengeMode, GetInstanceInfo, SendChatMessage, C_Timer, IsInGroup = GetUnitName, C_ChallengeMode, GetInstanceInfo, SendChatMessage, C_Timer, IsInGroup
local encounterEndProcessing = false
function frameHandlers.ENCOUNTER_LOOT_RECEIVED(event, ...)
    local encounterID, itemID, itemLink, quantity, playerName, className = ...
    if (not encounterEndProcessing) then
        encounterEndProcessing = true
        C_Timer.After(10 * 60, function() encounterEndProcessing = false end)
        local name, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceID, instanceGroupSize, LfgDungeonID = GetInstanceInfo()
        if (difficultyID and difficultyID == 8) then -- Mythic Keystone
            local mapID, level, time, onTime, keystoneUpgradeLevels, practiceRun, oldDungeonScore, newDungeonScore, isAffixRecord, isMapRecord, primaryAffix, isEligibleForScore, upgradeMembers = C_ChallengeMode.GetCompletionInfo()
            if (level and level > 0 and not practiceRun) then
                if (level > 16 and onTime and IsInGroup()) then
                    C_Timer.After(1, function() SendChatMessage("<(^-^)>", "PARTY") end)
                end
                addon.Convenience:ThanksBye(2)
            end
        end
    end
end

local customHandlers = {}

-- attach to addon
addon.Initializer.NewEventTracker = NewEventTracker
addon.EventTracker = NewEventTracker(frameHandlers, customHandlers)
