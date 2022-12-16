local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class PlayerAction
---@field Id integer
---@field Key string
---@field Name string
---@field Icon integer

---@class SharedData
---@field CurrentAction PlayerAction
---@field RangeCheckSpell PlayerAction

-- shared by name with other addonds. Need to be global
---@type SharedData
TopPriorityActionSharedData = {
    CurrentAction = {
        Id = 0,
        Key = "",
        Name = "Empty",
        Icon = 0,
    },
    RangeCheckSpell = {},
}

-- attach to addon
addon.Shared = TopPriorityActionSharedData
