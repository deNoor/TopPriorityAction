local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class CmdBus
---@field private Commands table<string, Cmd>
---@field Add fun(self:CmdBus, ...)
---@field Remove fun(self:CmdBus, name:string)
---@field Find fun(self:CmdBus, name:string):Cmd?

---@class Cmd
---@field private Frame Frame
---@field Name string
---@field Expiration number @GetTime() seconds
---@field Arg1 any
---@field Arg2 any
---@field Arg3 any

local getTime = GetTime

---@type CmdBus
local CmdBus = {
    Commands = {},
    Add = function(...) end,
}

local default = {
    Command = {
        DirationMax = 10,
    }
}

local cmdCache = {}
---@param name string
---@return Cmd
local function GetCached(name)
    local cmd = cmdCache[name] ---@type Cmd
    if (not cmd) then
        cmd = {
            Name = name,
            Expiration = -1,
        }
        cmdCache[name] = cmd
    end
    cmd.Expiration = -1
    cmd.Arg1 = nil
    cmd.Arg2 = nil
    cmd.Arg3 = nil
    return cmd
end

function CmdBus:Add(...)
    local warn = addon.Helper.Print
    local nameRaw, durationRaw, arg1, arg2, arg3 = ...
    local name = tostring(nameRaw)
    local duration = tonumber(durationRaw)
    if (type(name) ~= "string") then
        warn("expected a name but [1] was", name)
        return
    end
    if (type(duration) ~= "number") then
        warn("expected a duration but [2] was", duration)
        return
    elseif (duration < 1 or duration > default.Command.DirationMax) then
        warn("duration must be between 1 and", default.Command.DirationMax)
    end
    local cmd = GetCached(name)
    cmd.Expiration = getTime() + duration
    cmd.Arg1 = arg1
    cmd.Arg2 = arg2
    cmd.Arg3 = arg3
    self.Commands[name] = cmd
end

function CmdBus:Find(name)
    local cmd = self.Commands[name]
    if (cmd and cmd.Expiration > addon.Rotation.Timestamp) then
        return cmd
    end
end

function CmdBus:Remove(name)
    self.Commands[name] = nil
end

function CmdBus:Register()
    return self
end

-- attach to addon
addon.CmdBus = CmdBus:Register()
