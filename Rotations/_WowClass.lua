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
}

WowClass.InterruptUndesirable = addon.Helper.ToHashSet({
    323764, -- ConvokeTheSpirits
})

addon.WowClass = WowClass
