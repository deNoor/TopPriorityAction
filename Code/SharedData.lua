local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class CustomEvents
---@field ADDON_TPA_ACTION_UPDATE string
---@field ADDON_TPA_SETTINGS_UPDATE string
---@field ADDON_TPA_RANGE_CHECK_UPDATE string

---@class SharedData
---@field InRange boolean
---@field InRangeSet fun(self:SharedData, value:boolean)
---@field CustomEvents CustomEvents

-- shared by name with other addonds. Need to be global
---@type SharedData
TopPriorityActionSharedData = {
    InRange = false,
    CustomEvents = {
        ADDON_TPA_ACTION_UPDATE = "ADDON_TPA_ACTION_UPDATE", -- action:Action
        ADDON_TPA_SETTINGS_UPDATE = "ADDON_TPA_SETTINGS_UPDATE", -- settings:Settings
        ADDON_TPA_RANGE_CHECK_UPDATE = "ADDON_TPA_RANGE_CHECK_UPDATE", -- newValue:boolean
    },
}

local EventRegistry = EventRegistry
function TopPriorityActionSharedData:InRangeSet(value)
    if (self.InRange ~= value) then
        self.InRange = value
        EventRegistry:TriggerEvent(addon.Shared.CustomEvents.ADDON_TPA_RANGE_CHECK_UPDATE, value)
    end
end

-- attach to addon
addon.Shared = TopPriorityActionSharedData
