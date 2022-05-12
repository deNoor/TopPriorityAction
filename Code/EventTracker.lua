local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@alias EventHandler fun(event:string,eventArgs:any[])

---@class EventTracker
---@field private Frame Frame
---@field private Handlers table<string, EventHandler>
---@field Timestamp number

---@type EventTracker
local EventTracker = {
    Frame = CreateFrame("Frame"),
    Handlers = {},
    Timestamp = 0,
}

---loads saved setting
---@param eventArgs any[]
function EventTracker.Handlers.ADDON_LOADED(event, eventArgs)
    local name = eventArgs[1]
    if name == "TopPriorityAction" then
        addon.SavedSettings:Load()
        EventTracker:UnRegisterEvent(event)
    end
end

---@param eventArgs any[]
function EventTracker.Handlers.PLAYER_ENTERING_WORLD(event, eventArgs)
    addon:DetectRotation()
    EventTracker:UnRegisterEvent(event)
end

function EventTracker.Handlers.PLAYER_SPECIALIZATION_CHANGED(event, eventArgs)
    addon:DetectRotation()
end

function EventTracker:RegisterEvents()
    for event, _ in pairs(self.Handlers) do
        self.Frame:RegisterEvent(event)
    end
    local this = self
    local getTime = GetTime
    local handlers = this.Handlers
    self.Frame:SetScript("OnEvent", function(_, event, ...)
        this.Timestamp = getTime()
        local handler = handlers[event]
        if handler then
            local eventArgs = { ... }
            handler(event, eventArgs)
        end
    end)
    return self
end

---@param event string
function EventTracker:UnRegisterEvent(event)
    self.Frame:UnregisterEvent(event)
    return self
end

function EventTracker:Init()
    return self:RegisterEvents()
end

-- attach to addon
addon.EventTracker = EventTracker:Init()
