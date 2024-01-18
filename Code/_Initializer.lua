local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

-- need to be loaded first. Use to initialize addon-wide data.

-- keybinds --------------------------
_G["BINDING_HEADER_TOPPRIOACTION_HEADER"] = "Top priority action"
_G["BINDING_NAME_TOPPRIOACTION_SWITCH"] = "Switch"
_G["BINDING_NAME_TOPPRIOACTION_BURST"] = "Burst"
_G["BINDING_NAME_TOPPRIOACTION_AOE"] = "AoE"
_G["BINDING_NAME_TOPPRIOACTION_DISPEL"] = "Dispel"
TpaKeys = {}
function TpaKeys.Toggle(toggle)
    addon.SavedSettings.Instance[toggle] = not addon.SavedSettings.Instance[toggle]
    addon.SavedSettings:RaiseSettingUpdate()
end

--------------------------------------

-- slash commands --------------------
SLASH_TPrioS1 = "/tpa"
local tonumber = tonumber
---@type table<string,fun(...)>
local cmdHandlers = {
    switch = function(...)
        addon.SavedSettings.Instance.Enabled = not addon.SavedSettings.Instance.Enabled
        addon.SavedSettings:RaiseSettingUpdate()
    end,
    start = function(...)
        addon.SavedSettings.Instance.Enabled = true
        addon.SavedSettings:RaiseSettingUpdate()
    end,
    stop = function(...)
        addon.SavedSettings.Instance.Enabled = false
        addon.SavedSettings:RaiseSettingUpdate()
    end,
    aoe = function(...)
        addon.SavedSettings.Instance.AOE = not addon.SavedSettings.Instance.AOE
        addon.SavedSettings:RaiseSettingUpdate()
    end,
    burst = function(...)
        addon.SavedSettings.Instance.Burst = not addon.SavedSettings.Instance.Burst
        addon.SavedSettings:RaiseSettingUpdate()
    end,
    dispel = function(...)
        addon.SavedSettings.Instance.Dispel = not addon.SavedSettings.Instance.Dispel
        addon.SavedSettings:RaiseSettingUpdate()
    end,
    pause = function(arg, ...)
        local seconds = tonumber(arg)
        if seconds then
            addon.Rotation.PauseTimestamp = addon.Rotation.Timestamp + seconds
        end
    end,
    aaw = function(arg, ...)
        local ms = tonumber(arg)
        addon.SavedSettings.Instance:UpdateAdvanceWindow(ms)
    end,
    cmd = function(...)
        addon.CmdBus:Add(...)
    end,
    thanksbye = function(...)
        addon.Convenience:ThanksBye()
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
    local spell = Spell:CreateFromSpellID(spellId)
    if (not spell:IsSpellEmpty()) then
        spell:ContinueOnSpellLoad(callback)
    end
end

local Item = Item
function DataQuery.OnItemLoaded(itemId, callback)
    local item = Item:CreateFromItemID(itemId)
    if (not item:IsItemEmpty()) then
        item:ContinueOnItemLoad(callback)
    end
end

function DataQuery.OnEqupItemLoaded(slotId, callback)
    local item = Item:CreateFromEquipmentSlot(slotId)
    if (not item:IsItemEmpty()) then
        item:ContinueOnItemLoad(callback)
    end
end

addon.DataQuery = DataQuery
--------------------------------------

-- helper functions ------------------
---@class Helper
---@field Print fun(...)
---@field Throw fun(...)
---@field ToHashSet fun(table:string[]|integer[]):table<string|integer,string|integer>
---@field AddVirtualMethods fun(instance:table, classDefinition:table):table @adds methods to object instance

local Helper = {}
local tconcat, tinsert = table.concat, tinsert

local function prepare(...)
    local first = ...
    local args = nil
    if (type(first) == "table") then
        args = first
    else
        args = { ... }
    end
    local count = 0
    for _, _ in pairs(args) do
        count = count + 1
    end
    for i = 1, count do
        local value = args[i]
        value = value == nil and "nil" or value
        args[i] = tostring(value)
    end
    tinsert(args, "")
    return args
end

local print = print
function Helper.Print(...)
    print(tconcat(prepare(...), " "))
end

local error = error
function Helper.Throw(...)
    error(tconcat(prepare(...), " "))
end

function Helper.ToHashSet(table)
    local t = {}
    for index, value in ipairs(table) do
        t[value] = value
    end
    return t
end

---adds methods to object instance
---@param instance table
---@param classDefinition table
function Helper.AddVirtualMethods(instance, classDefinition)
    for name, func in pairs(classDefinition) do                   -- add functions directly, direct lookup might be faster than metatable lookup
        if (type(func) == "function" and not instance[name]) then -- insert only non-overriden functions
            instance[name] = func
        end
    end
    return instance
end

addon.Helper = Helper
--------------------------------------

---@class Empty
---@field Rotation Rotation
---@field Action PlayerAction

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
    Name = "Empty-Nospec",
    Spells = {},
    Items = {},
    RangeChecker = emptyAction,
    Pulse = function(_) return emptyAction end,
    SelectAction = function(_)
    end,
    ShouldNotRun = function(_) return true end,
    Activate = function(_)
    end,
    Dispose = function(_)
    end,
}

---@class Initializer
---@field Empty Empty
---@field NewSpell fun(spell:Spell):Spell
---@field NewItem fun(spell:Item):Item
---@field NewAuraCollection fun(unitId:UnitId,filter:string):AuraCollection
---@field NewEventTracker fun(frameHandlers:table<string, EventHandler>, customHandlers:table<string, EventHandler>?):EventTracker
---@field NewPlayer fun():Player
---@field NewEquipment fun():Equipment
---@field NewUnit fun(unit:Unit):Unit

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
    NewUnit = nil,
}

-- attach to addon
addon.Initializer = Initializer
