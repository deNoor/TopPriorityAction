local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class PlayerAction
---@field Id integer
---@field Key string
---@field Name string
---@field Icon integer

---@class Action : PlayerAction
---@field Type ActionType
---@field IsAvailable fun(self:Action):boolean
---@field IsUsableNow fun(self:Action):boolean,boolean @usable, noMana
---@field IsQueued fun(self:Action):boolean
---@field IsInRange fun(self:Action, unit:UnitId?):boolean
---@field ReadyIn fun(self:Action):number

---@alias ActionType
---| "Empty"
---| "Spell"
---| "EquipItem"
---| "Item"
