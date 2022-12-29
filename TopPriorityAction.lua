local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class TopPriorityAction
---@field CmdBus CmdBus
---@field Common Common
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
    local updateLimit = self.UpdateEverySec
    local getTime = GetTime
    local addon = addon
    local shared = addon.Shared
    local emptyAction = addon.Initializer.Empty.Action
    self.Ticker = C_Timer.NewTicker(
        self.UpdateEverySec,
        function()
            local now = getTime()
            local rotation = addon.Rotation
            rotation.Timestamp = now
            shared.CurrentAction = rotation:Pulse() or emptyAction
        end)
    return self
end

function Program:Main()
    self:RegisterActionUpdater()
end

-- run addon
Program:Main()
