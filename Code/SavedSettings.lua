local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class SavedSettings
---@field Instance Settings
---@field Load fun()

---@class Settings

local SavedSettings = {}
function SavedSettings:Load()
    TopPriorityActionSettings = TopPriorityActionSettings or {} -- saved variable from .toc file
    self.Instance = TopPriorityActionSettings
end

addon.SavedSettings = SavedSettings
