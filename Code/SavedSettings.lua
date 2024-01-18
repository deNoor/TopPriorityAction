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
---@field UpdateAdvanceWindow fun(self:Settings,newValue?:integer)

---@type SavedSettings
local SavedSettings = {
    Instance = {
        Enabled = false,
        Burst = false,
        AOE = false,
        Dispel = false,
        ActionAdvanceWindow = 75 / 1000,
        UpdateAdvanceWindow = function(self, ms)
            local spellQueueWindow = GetSpellQueueWindow();
            ms = ms or (self.ActionAdvanceWindow * 1000) or spellQueueWindow
            self.ActionAdvanceWindow = max(1, min(ms, spellQueueWindow)) / 1000
            addon.Helper.Print("action advance window", self.ActionAdvanceWindow * 1000)
            addon.Helper.Print("spell queue window", spellQueueWindow)
        end,
    }
}
function SavedSettings:Load()
    TopPriorityActionSettings = TopPriorityActionSettings -- saved variable from .toc file
        or self.Instance
    self.Instance = addon.Helper.AddVirtualMethods(TopPriorityActionSettings, self.Instance)
    self.Instance:UpdateAdvanceWindow()
    self:RaiseSettingUpdate()
end

local EventRegistry = EventRegistry
function SavedSettings:RaiseSettingUpdate()
    EventRegistry:TriggerEvent(addon.Shared.CustomEvents.ADDON_TPA_SETTINGS_UPDATE, self.Instance)
end

-- attach to addon
addon.SavedSettings = SavedSettings
