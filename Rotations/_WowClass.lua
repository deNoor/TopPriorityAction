local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class WowClass

local WowClass = {
    DRUID = {
        [2] = nil, -- Feral
    },
}

addon.WowClass = WowClass
