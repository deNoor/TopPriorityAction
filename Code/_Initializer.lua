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
BINDING_NAME_DISPEL = "Dispel"
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
    dispel = function(...)
        addon.SavedSettings.Instance.Dispel = not addon.SavedSettings.Instance.Dispel
    end,
    pause = function(arg, ...)
        local seconds = tonumber(arg)
        if seconds then
            addon.Rotation.PauseTimestamp = addon.Rotation.Timestamp + seconds
        end
    end,
    aaw = function(arg, ...)
        local ms = tonumber(arg) or 400
        ms = max(0, min(ms, 400))
        addon.SavedSettings.Instance.ActionAdvanceWindow = (ms / 1000)
        addon.Helper.Print({ "action advance window", ms })
        addon.Helper.Print({ "spell queue window", GetSpellQueueWindow() })
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

-- Async data loader -----------------
---@class DataQuery
---@field OnSpellLoaded fun(spellId:integer, callback:function)
---@field OnItemLoaded fun(itemId:integer, callback:function)
---@field OnEqupItemLoaded fun(slotId:integer, callback:function)

local DataQuery = {}

local Spell = Spell
function DataQuery.OnSpellLoaded(spellId, callback)
    Spell:CreateFromSpellID(spellId):ContinueOnSpellLoad(callback)
end

local Item = Item
function DataQuery.OnItemLoaded(itemId, callback)
    Item:CreateFromItemID(itemId):ContinueOnItemLoad(callback)
end

function DataQuery.OnEqupItemLoaded(slotId, callback)
    Item:CreateFromEquipmentSlot(slotId):ContinueOnItemLoad(callback)
end

addon.DataQuery = DataQuery
--------------------------------------

-- helper functions ------------------
---@class Helper
---@field Print fun(params:string[])
---@field Throw fun(params:string[])
---@field ToHashSet fun(table:string[]):table<string,string>

local Helper = {}
local concat = table.concat
local function prepare(table)
    if (type(table) ~= "table") then
        table = { table }
    end
    tinsert(table, "")
    for i = 1, #table do
        local value = table[i]
        value = value == nil and "nil" or value
        table[i] = tostring(value)
    end
    return table
end

local print = print
function Helper.Print(params)
    print(concat(prepare(params), " "))
end

local error = error
function Helper.Throw(params)
    error(concat(prepare(params), " "))
end

function Helper.ToHashSet(table)
    local t = {}
    for index, value in ipairs(table) do
        t[value] = value
    end
    return t
end

addon.Helper = Helper
--------------------------------------

---@class Empty
---@field Rotation Rotation
---@field Action Action

---@type Action
local emptyAction = {
    Id = 0,
    Key = "",
    Name = "Empty",
    Icon = 0,
    Type = "Empty",
    IsAvailable = function() return true end,
    IsUsableNow = function() return true, false end,
    IsQueued = function() return false end,
    IsInRange = function() return true end,
    ReadyIn = function() return 0 end,
}
---@type Rotation
local emptyRotation = {
    Pulse = function(_) return emptyAction end,
    ShouldNotRun = function(_) return true end,
    Activate = function(_) end,
    Dispose = function(_) end,
    Spells = {},
    Items = {},
    Talents = {},
    Timestamp = 0,
    Settings = nil,
    GCDSpell = nil,
    PauseTimestamp = 0,
    IsPauseKeyDown = false,
    AddedPauseOnKey = 0,
    RangeChecker = emptyAction,
}

---@class Initializer
---@field Empty Empty
---@field NewSpell fun(spell:Spell):Spell
---@field NewItem fun(spell:Item):Item
---@field NewAuraCollection fun(unit:string,filter:WowUnit):AuraCollection
---@field NewEventTracker fun(handlers:table<string, EventHandler>):EventTracker
---@field NewEquipment fun():Equipment

---@type Initializer
local Initializer = {
    Empty = {
        Rotation = emptyRotation,
        Action = emptyAction,
    },
    NewSpell = nil,
    NewItem = nil,
    NewAuraCollection = nil,
    NewEventTracker = nil,
    NewEquipment = nil,
}

-- attach to addon
addon.Initializer = Initializer
