local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class TopPriorityAction
---@field Initializer Initializer
---@field Helper Helper
---@field Shared SharedData
---@field SavedSettings SavedSettings
---@field WowClass WowClass
---@field Player Player
---@field EventTracker EventTracker

local Program = {
    UpdateEveryFrameCount = 2,
    Frame = CreateFrame("Frame"),
}

function Program:RegisterActionUpdater()
    local frameCount = 0
    local updateLimit = self.UpdateEveryFrameCount
    local getTime = GetTime
    local player = addon.Player
    local currentAction = addon.Shared.CurrentAction
    self.Frame:SetScript("OnEvent", function()
        frameCount = frameCount + 1
        if (frameCount % updateLimit == 0) then
            frameCount = 0
            local rotation = player.Rotation
            rotation.Timestamp = getTime()
            currentAction.Key = rotation.Pulse().Key
        end
    end)
    return self
end

function Program:Main()
    self:RegisterActionUpdater()
end

-- run addon
Program:Main()
