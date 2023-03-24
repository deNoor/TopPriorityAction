local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class TopPriorityAction
---@field CmdBus CmdBus
---@field Common Common
---@field Convenience Convenience
---@field DataQuery DataQuery
---@field EventTracker EventTracker
---@field Helper Helper
---@field Initializer Initializer
---@field Player Player
---@field Shared SharedData
---@field SavedSettings SavedSettings
---@field WowClass WowClass
---@field Rotation Rotation
---@field AddRotation fun(self:TopPriorityAction, class:string, spec:integer, rotation:Rotation)
---@field DetectRotation fun(self:TopPriorityAction)
---@field UpdateKnownSpells fun(self:TopPriorityAction)
---@field UpdateKnownItems fun(self:TopPriorityAction)
---@field UpdateEquipment fun(self:TopPriorityAction)
---@field UpdateRotationResource fun(self:TopPriorityAction)

local Program = {
    UpdateEverySec = 1 / 61,
    Ticker = nil,
}

function Program:RegisterActionUpdater()
    local getTime = GetTime
    local eventRegistry = EventRegistry
    local addon = addon
    local convenience = addon.Convenience
    local event = addon.Shared.CustomEvents.ADDON_TPA_ACTION_UPDATE
    local emptyAction = addon.Initializer.Empty.Action
    local currentAction = emptyAction
    self.Ticker = C_Timer.NewTicker(
        self.UpdateEverySec,
        function()
            local now = getTime()
            local rotation = addon.Rotation
            rotation.Timestamp = now
            local action = convenience:UserAction() or rotation:Pulse() or emptyAction
            if (action ~= currentAction) then
                currentAction = action
                eventRegistry:TriggerEvent(event, action)
            end
        end)
    return self
end

function Program:Main()
    self:RegisterActionUpdater()
end

-- run addon
Program:Main()
