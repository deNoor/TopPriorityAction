local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@alias EventHandler fun(event:string, ...)

---@class EventTracker
---@field private Frame Frame
---@field Handlers table<string, EventHandler>
---@field EventTimestamp number
---@field private RegisterEvents fun(self:EventTracker)
---@field UnRegisterEvent fun(self:EventTracker, event:string)
---@field Dispose fun(self:EventTracker)

local EventTracker = {
    EventTimestamp = 0
}

function EventTracker:RegisterEvents()
    for event, _ in pairs(self.Handlers) do
        self.Frame:RegisterEvent(event)
    end
    local getTime = GetTime
    local handlers = self.Handlers
    self.Frame:SetScript("OnEvent", function(_, event, ...)
        self.EventTimestamp = getTime()
        local handler = handlers[event]
        if handler then
            handler(event, ...)
        end
    end)
    return self
end

function EventTracker:UnRegisterEvent(event)
    self.Frame:UnregisterEvent(event)
    return self
end

function EventTracker:Dispose()
    self.Frame:UnregisterAllEvents()
end

local function NewEventTracker(handlers)
    local eventTracker = {
        Frame = CreateFrame("Frame"),
        Handlers = handlers or {},
        Timestamp = 0,
    }
    addon.Helper.AddVirtualMethods(eventTracker, EventTracker)
    eventTracker:RegisterEvents()
    return eventTracker
end

-- addon global handlers
local handlers = {}

---loads saved setting
function handlers.ADDON_LOADED(event, ...)
    local name = ...
    if name == addonName then
        addon.SavedSettings:Load()
        addon.EventTracker:UnRegisterEvent(event)
    end
end

function handlers.PLAYER_ENTERING_WORLD(event, ...)
    local initialLogin, reloadingUi = ... -- if not (initialLogin or reloadingUi) then entering an instance
    if (initialLogin or reloadingUi) then
        addon.Initializer.NewPlayer()
    end
    addon:DetectRotation()
end

function handlers.PLAYER_SPECIALIZATION_CHANGED(event, ...)
    addon:DetectRotation()
end

function handlers.PLAYER_EQUIPMENT_CHANGED(event, ...)
    addon:UpdateEquipment()
end

-- fired after spec change, talent change, spellbook change
function handlers.SPELLS_CHANGED(event, ...)
    addon:UpdateKnownSpells()
end

-- function handlers.UNIT_DISPLAYPOWER(event, ...)
--     local unitId, arg1, arg2 = ...
--     addon.Helper.Print("unit display power", UnitPowerType(unitId), unitId, arg1, arg2)
-- end

function handlers.MODIFIER_STATE_CHANGED(event, ...)
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

-- attach to addon
addon.Initializer.NewEventTracker = NewEventTracker
addon.EventTracker = NewEventTracker(handlers)
