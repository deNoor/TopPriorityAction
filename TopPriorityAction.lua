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
---@field Rotation Rotation
---@field DetectRotation fun(self:TopPriorityAction)
---@field Player Player
---@field EventTracker EventTracker

local Program = {
    UpdateEveryFrameCount = 240,
    Frame = CreateFrame("Frame"),
}

function Program:RegisterActionUpdater()
    local frameCount = 0
    local updateLimit = self.UpdateEveryFrameCount
    local getTime = GetTime
    local addon = addon
    local shared = addon.Shared
    self.Frame:SetScript("OnUpdate", function()
        frameCount = frameCount + 1
        if (frameCount % updateLimit == 0) then
            frameCount = 0
            local rotation = addon.Rotation
            rotation.Timestamp = getTime()
            shared.CurrentAction = rotation:Pulse()
        end
    end)
    return self
end

function Program:Main()
    self:RegisterActionUpdater()
end

-- run addon
Program:Main()
