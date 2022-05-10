local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class PlayerAction
---@field Key string

---@class SharedData
---@field CurrentAction PlayerAction

-- shared by name with other addonds. Need to be global
---@type SharedData
TopPriorityActionSharedData = {
    CurrentAction = {
        Key = ""
    }
}

-- attach to addon
addon.Shared = TopPriorityActionSharedData
