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
        AutoShot = {
            Id = 75,
        },
        GrievousWound = {
            Id = 240559,
            Debuff = 240559,
        },
        NecroticPitch = {
            Id = 153692,
            Debuff = 153692,
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
