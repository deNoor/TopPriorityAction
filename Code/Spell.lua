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
---@field Known boolean
---@field Empty Spell
---@field ReadyIn fun(self:Spell):number

---@type Spell
local Spell = {}

---@param spell Spell
---@return Spell
local function NewSpell(spell)
    local spell = spell or addon.Helper:Throw({ "attempt to initialize empty player spell" })
    for name, func in pairs(Spell) do -- add functions directly, direct lookup might be faster than metatable lookup
        spell[name] = func
    end
    return spell
end

local GetSpellCooldown, max = GetSpellCooldown, max
function Spell:ReadyIn()
    local now = addon.Rotation.Timestamp
    local start, duration = GetSpellCooldown(self.Id)
    if start then
        return max(0, start + duration - now)
    end
end

local IsSpellKnownOrOverridesKnown = IsSpellKnownOrOverridesKnown
function addon:UpdateKnownSpells()
    local spells = self.Rotation.Spells
    for name, spell in pairs(spells) do
        spell.Known = spell.Id > 0 and IsSpellKnownOrOverridesKnown(spell.Id)
    end
end

function Spell:IsKnown()
    return self.Known
end

function Spell:Report()
    addon.Helper:Print({ "Id", self.Id, "Key", self.Key })
end

addon.Initializer.NewSpell = NewSpell
