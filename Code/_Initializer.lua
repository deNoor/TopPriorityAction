local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

-- need to be loaded first. Use to initialize addon-wide data.

-- keybinds --------------------------
BINDING_HEADER_TPRIOACTION = "Top priority action"
BINDING_NAME_SWITCH = "Switch"
BINDING_NAME_BURST = "Burst"
BINDING_NAME_AOE = "AoE"
TpaKeys = {}
function TpaKeys.Toggle(toggle)
    addon.SavedSettings.Instance[toggle] = not addon.SavedSettings.Instance[toggle]
end

--------------------------------------

-- slash commands --------------------
SLASH_TPrioS1 = "/tpa"
local tonumber = tonumber
---@type table<string,fun()>
local cmdHandlers = {
    switch = function(...)
        addon.SavedSettings.Instance.Enabled = not addon.SavedSettings.Instance.Enabled
    end,
    start = function(...)
        addon.SavedSettings.Instance.Enabled = true
    end,
    stop = function(...)
        addon.SavedSettings.Instance.Enabled = false
    end,
    aoe = function(...)
        addon.SavedSettings.Instance.AOE = not addon.SavedSettings.Instance.AOE
    end,
    burst = function(...)
        addon.SavedSettings.Instance.Burst = not addon.SavedSettings.Instance.Burst
    end,
    pause = function(arg, ...)
        local seconds = tonumber(arg)
        if seconds then
            addon.Rotation.PauseTimestamp = addon.Rotation.Timestamp + seconds
        end
    end,
    sqw = function(...)
        addon.SavedSettings.Instance.SpellQueueWindow = (GetSpellQueueWindow() / 1000)
    end,
}
local toLower = strlower
SlashCmdList.TPrioS = function(msg, editBox)
    local args = { strsplit(" ", msg) }
    if (#args <= 0) then
        return
    end
    local handler = cmdHandlers[toLower(args[1])]
    if handler then
        handler(select(1, unpack(args, 2)))
    end
end
--------------------------------------

-- helper functions ------------------
---@class Helper
---@field Print fun(self:Helper, params:string[])
---@field Throw fun(self:Helper, params:string[])

local Helper = {}
local concat = table.concat
local function prepare(table)
    if (type(table) ~= "table") then
        table = { table }
    end
    tinsert(table, "")
    for i = 1, #table do
        local value = table[i] or "nil"
        table[i] = tostring(value)
    end
    return table
end

local print = print
function Helper:Print(params)
    print(concat(prepare(params), " "))
end

local error = error
function Helper:Error(params)
    error(concat(prepare(params), " "))
end

addon.Helper = Helper
--------------------------------------

---@class Initializer
---@field NewSpell fun(spell:Spell):Spell
---@field NewAuraCollection fun(unit:string,filter:string):AuraCollection
---@field NewEventTracker fun(handlers:table<string, EventHandler>):EventTracker

---@type Initializer
local Initializer = {
    NewSpell = nil,
    NewAuraCollection = nil,
    NewEventTracker = nil,
}

addon.Initializer = Initializer
