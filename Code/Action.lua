local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction


---@class Action : PlayerAction
---@field Type ActionType
---@field IsAvailable fun(self:Action):boolean
---@field IsUsableNow fun(self:Action):boolean,boolean @usable, noMana
---@field IsQueued fun(self:Action):boolean
---@field IsInRange fun(self:Action, unit:WowUnit):boolean
---@field ReadyIn fun(self:Action):number

---@alias ActionType
---| "Empty"
---| "Spell"
---| "EquipItem"
---| "Item"
