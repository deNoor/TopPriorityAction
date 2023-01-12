local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class Common
---@field Spells table<string, Spell>
---@field Items table<string, Item>

---@type Common
local Common = {
    Spells = {
        Gcd = {
            Id = 61304,
        },
        AutoAttack = {
            Id = 6603,
        },
        GrievousWound = {
            Id = 240559,
            Debuff = 240559,
        },
    },
    Items = {
        Healthstone = {
            Id = 5512,
        },
    }
}

-- attach to addon
addon.Common = Common
