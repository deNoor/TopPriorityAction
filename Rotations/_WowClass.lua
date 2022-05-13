local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class WowClass
---@field AddRotation fun(self:WowClass, class:string, spec:integer, spells:table<string,Spell>, rotation:Rotation)
---@field FullGCDTime fun(self:WowClass): number
---@field GCDReadyIn fun(self:WowClass): number

local WowClass = {
    DRUID = {
        [2] = nil, -- Feral
    },
}

function WowClass:AddRotation(class, spec, spells, rotation)
    for name, spell in pairs(spells) do
        addon.Initializer.NewSpell(spell)
    end
    rotation = rotation or addon.Helper:Throw({ "attempt to add nil rotation for", class, spec })
    WowClass[class] = { [spec] = rotation }
end

local UnitPowerType, max, GetHaste = UnitPowerType, max, GetHaste
function WowClass:FullGCDTime()
    return (UnitPowerType("player") == 3 and 1 or max(0.75, 1.5 * 100 / (100+GetHaste())))
end

---@type Spell
local GCDspell = addon.Initializer.NewSpell({ Id = 61304, })
function WowClass:GCDReadyIn()
    return GCDspell:ReadyIn()
end

addon.WowClass = WowClass
