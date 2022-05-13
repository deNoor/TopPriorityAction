local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@alias EventHandler fun(event:string,eventArgs:any[])

---@class EventTracker
---@field private Frame Frame
---@field private Handlers table<string, EventHandler>
---@field Timestamp number
---@field private RegisterEvents fun(self:EventTracker)
---@field UnRegisterEvent fun(self:EventTracker, event:string)
---@field Dispose fun(self:EventTracker)

local EventTracker = {}

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
    for name, func in pairs(EventTracker) do -- add functions directly, direct lookup might be faster than metatable lookup
        eventTracker[name] = func
    end
    eventTracker:RegisterEvents()
    return eventTracker
end

-- addon global handlers
local handlers = {}

---loads saved setting
---@param eventArgs any[]
function handlers.ADDON_LOADED(event, eventArgs)
    local name = eventArgs[1]
    if name == "TopPriorityAction" then
        addon.SavedSettings:Load()
        addon.EventTracker:UnRegisterEvent(event)
    end
end

---@param eventArgs any[]
function handlers.PLAYER_ENTERING_WORLD(event, eventArgs)
    addon:DetectRotation()
    addon.EventTracker:UnRegisterEvent(event)
end

function handlers.PLAYER_SPECIALIZATION_CHANGED(event, eventArgs)
    addon:DetectRotation()
end

-- attach to addon
addon.Initializer.NewEventTracker = NewEventTracker
addon.EventTracker = NewEventTracker(handlers)
