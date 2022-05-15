local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class PlayerAction
---@field Id integer
---@field Name string
---@field Key string

---@class SharedData
---@field CurrentAction PlayerAction
---@field RangeCheckSpell Spell

-- shared by name with other addonds. Need to be global
---@type SharedData
TopPriorityActionSharedData = {
    CurrentAction = {
        Id = 0,
        Key = "",
        Name = "Empty",
    },
    RangeCheckSpell = {},
}

-- attach to addon
addon.Shared = TopPriorityActionSharedData
