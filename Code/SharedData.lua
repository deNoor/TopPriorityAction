local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class PlayerAction
---@field Id integer
---@field Key string
---@field Name string
---@field Icon integer

---@class CustomEvents
---@field ADDON_TPA_ACTION_UPDATE string
---@field ADDON_TPA_SETTINGS_UPDATE string

---@class SharedData
---@field CurrentAction PlayerAction
---@field RangeCheckSpell PlayerAction
---@field CustomEvents CustomEvents

-- shared by name with other addonds. Need to be global
---@type SharedData
TopPriorityActionSharedData = {
    CurrentAction = addon.Initializer.Empty.Action,
    RangeCheckSpell = {},
    CustomEvents = {
        ADDON_TPA_ACTION_UPDATE = "ADDON_TPA_ACTION_UPDATE",
        ADDON_TPA_SETTINGS_UPDATE = "ADDON_TPA_SETTINGS_UPDATE",
    },
}

-- attach to addon
addon.Shared = TopPriorityActionSharedData
