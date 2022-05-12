local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

-- need to be loaded first. Use to initialize addon-wide data.

-- initialized and attached on ADDON_LOADED event

SLASH_MTEST1 = "/mtest"
SlashCmdList.MTEST = function(msg, editBox)
    local key = strsplit(" ", msg)
    TopPriorityActionSharedData.CurrentAction.Key = strupper(key)
end

-- helper functions------------------

---@class Helper
---@field Print fun(self:Helper, params:string[])
---@field Throw fun(self:Helper, params:string[])

local Helper = {}
local concat = table.concat

local print = print
function Helper:Print(params)
    print(concat(params, " "))
end

local error = error
function Helper:Error(params)
    error(concat(params, " "))
end

addon.Helper = Helper
-------------------------------------

---@class Initializer
---@field NewSpell fun(spell:Spell):Spell
---@field NewAuraCollection fun(unit:string,filter:string):AuraCollection

---@type Initializer
local Initializer = {
    NewSpell = nil,
    NewAuraCollection = nil,
}

addon.Initializer = Initializer
