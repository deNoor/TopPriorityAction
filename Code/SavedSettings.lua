local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class SavedSettings
---@field Instance Settings
---@field Load fun(self:SavedSettings)
---@field RaiseSettingUpdate fun(self:SavedSettings)

---@class Settings
---@field Enabled boolean
---@field Burst boolean
---@field AOE boolean
---@field Dispel boolean
---@field ActionAdvanceWindow integer

local SavedSettings = { Instance = nil }
function SavedSettings:Load()
    TopPriorityActionSettings = TopPriorityActionSettings or {} -- saved variable from .toc file
    TopPriorityActionSettings.ActionAdvanceWindow = TopPriorityActionSettings.ActionAdvanceWindow or (GetSpellQueueWindow() / 1000)
    self.Instance = TopPriorityActionSettings
    self:RaiseSettingUpdate()
end

local EventRegistry = EventRegistry
function SavedSettings:RaiseSettingUpdate()
    EventRegistry:TriggerEvent(addon.Shared.CustomEvents.ADDON_TPA_SETTINGS_UPDATE, self.Instance)
end

-- attach to addon
addon.SavedSettings = SavedSettings
