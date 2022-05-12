local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class SavedSettings
---@field Instance Settings
---@field Load fun(self:SavedSettings)

---@class Settings
---@field Enabled boolean
---@field Burst boolean
---@field AOE boolean

local SavedSettings = { Instance = nil }
function SavedSettings:Load()
    TopPriorityActionSettings = TopPriorityActionSettings or {} -- saved variable from .toc file
    self.Instance = TopPriorityActionSettings
end

addon.SavedSettings = SavedSettings
