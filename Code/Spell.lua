local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class Spell
---@field Id integer
---@field Key string
---@field Buff integer
---@field Debuff integer
---@field NoGCD boolean
---@field HardCast boolean
---@field New fun(spell:Spell):Spell

---@type Spell
local Spell = {
}

---@param spell Spell
---@return Spell
function Spell.New(spell)
    local o = spell or addon.Helper:Throw({ "attempt to initialize empty player spell" })
    for key, value in pairs(Spell) do -- add functions directly, direct lookup might be faster than metatable lookup
        if (key ~= "New") then -- skip ctor to prevent mistaken calls
            o[key] = value
        end
    end
    return o
end

function Spell:Report()
    addon.Helper:Print({ "Id", self.Id, "Key", self.Key })
end

addon.Initializer.NewSpell = Spell.New
