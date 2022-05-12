local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class WowClass
---@field AddRotation fun(self:WowClass, class:string, spec:integer, spells:table<string,Spell>, rotation:Rotation)
---@field DRUID Druid

---@class Druid
---@field [2] Rotation

local WowClass = {
    DRUID = {
        [2] = nil, -- Feral
    },
}

local emptySpell = { Id = -1, Key = "", }
function WowClass:AddRotation(class, spec, spells, rotation)
    for name, spell in pairs(spells) do
        addon.Initializer.NewSpell(spell)
    end
    rotation = rotation or addon.Helper:Throw({ "attempt to add nil rotation for", class, spec })
    rotation.EmptySpell = emptySpell
    WowClass[class] = { [spec] = rotation }
end

addon.WowClass = WowClass
