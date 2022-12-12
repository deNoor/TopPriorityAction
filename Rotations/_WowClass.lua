local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class WowClass
---@field InterruptUndesirable table<integer,any>

local WowClass = {
    DRUID = {
        [2] = nil, -- Feral
        [3] = nil, -- Guardian
    },
    ROGUE = {
        [1] = nil, -- Assassination
    },
    WARRIOR = {
        [2] = nil, -- Fury
    },
}

WowClass.InterruptUndesirable = addon.Helper.ToHashSet({
    323764, -- ConvokeTheSpirits
})

addon.WowClass = WowClass
