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
    HUNTER = {
        [1] = nil, -- BeastMastery
    },
    ROGUE = {
        [1] = nil, -- Assassination
        [2] = nil, -- Outlaw
    },
    WARRIOR = {
        [2] = nil, -- Fury
        [3] = nil, -- Protection
    },
}

WowClass.InterruptUndesirable = addon.Helper.ToHashSet({
    323764, -- ConvokeTheSpirits
})

addon.WowClass = WowClass
