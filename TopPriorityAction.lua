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
---@field AddRotation fun(self:TopPriorityAction, class:string, spec:integer, spells:table<string,Spell>, rotation:Rotation)
---@field DetectRotation fun(self:TopPriorityAction)
---@field UpdateTalents fun(self:TopPriorityAction)
---@field UpdateKnownSpells fun(self:TopPriorityAction)
---@field Player Player
---@field EventTracker EventTracker

local Program = {
    UpdateEverySec = 1 / 60,
    Frame = CreateFrame("Frame"),
}

function Program:RegisterActionUpdater()
    local updateLimit = self.UpdateEverySec
    local lastUpdate = 0
    local getTime = GetTime
    local addon = addon
    local shared = addon.Shared
    self.Frame:SetScript("OnUpdate", function()
        local now = getTime()
        if (now - lastUpdate > updateLimit) then
            lastUpdate = now
            local rotation = addon.Rotation
            rotation.Timestamp = now
            shared.CurrentAction = rotation:Pulse() or rotation.EmptySpell
        end
    end)
    return self
end

function Program:Main()
    self:RegisterActionUpdater()
end

-- run addon
Program:Main()
