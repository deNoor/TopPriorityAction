local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class Spell
---@field Id integer
---@field Name string
---@field Key string
---@field Buff integer
---@field Debuff integer
---@field NoGCD boolean
---@field HasCD boolean
---@field ChangesBased boolean
---@field HardCast boolean
---@field Known boolean
---@field ReadyIn fun(self:Spell):number
---@field IsUsableNow fun(self:Spell):boolean,boolean
---@field IsQueued fun(self:Spell):boolean
---@field IsKnown fun(self:Spell):boolean
---@field CCUnlockIn fun(self:Spell):number
---@field IsInRange fun(self:Spell):boolean

local max, pairs, ipairs = max, pairs, ipairs

---@type Spell
local Spell = {}

---@param spell Spell
---@return Spell
local function NewSpell(spell)
    local spell = spell or addon.Helper:Throw({ "attempt to initialize nil player spell" })
    if (spell.Id < 1) then
        addon.Helper:Throw({ "attempt to initialize empty player spell", spell.Id, })
    end
    for name, func in pairs(Spell) do -- add functions directly, direct lookup might be faster than metatable lookup
        if (type(func) == "function") then
            spell[name] = func
        end
    end
    return spell
end

local GetSpellCooldown = GetSpellCooldown
function Spell:ReadyIn()
    local now = addon.Rotation.Timestamp
    local start, duration = GetSpellCooldown(self.Id)
    if start then
        return max(0, start + duration - now) -- seconds
    end
end

local GetSpellInfo, IsSpellKnownOrOverridesKnown, GetSpellBaseCooldown, GetSpellCharges = GetSpellInfo, IsSpellKnownOrOverridesKnown, GetSpellBaseCooldown, GetSpellCharges
function addon:UpdateKnownSpells()
    local spells = self.Rotation.Spells
    for key, spell in pairs(spells) do
        local name, rank, icon, castTime, minRange, maxRange, spellID = GetSpellInfo(spell.Id)
        spell.Name = name
        spell.HardCast = castTime > 0
        spell.Known = IsSpellKnownOrOverridesKnown(spell.Id)
        local cooldownMS, gcdMS = GetSpellBaseCooldown(spell.Id)
        spell.NoGCD = gcdMS == 0
        spell.HasCD = cooldownMS > 0
        spell.ChangesBased = (GetSpellCharges(spell.Id)) ~= nil
    end
end

function Spell:IsKnown()
    return self.Known
end

local IsUsableSpell = IsUsableSpell
function Spell:IsUsableNow()
    local onCD = (self.HasCD or self.ChangesBased) and self:ReadyIn() >= addon.Rotation.Settings.SpellQueueWindow
    local usable, noMana = IsUsableSpell(self.Id)
    return not onCD and usable, noMana
end

local IsSpellInRange = IsSpellInRange
function Spell:IsInRange()
    return (IsSpellInRange(self.Name, "target") or 0) == 1
end

local IsCurrentSpell = IsCurrentSpell
function Spell:IsQueued()
    return IsCurrentSpell(self.Id)
end

local GetSpellLossOfControlCooldown = GetSpellLossOfControlCooldown
function Spell:CCUnlockIn()
    local now = addon.Rotation.Timestamp
    local start, duration = GetSpellLossOfControlCooldown(self.Id)
    if start then
        return max(0, start + duration - now)
    end
end

local GetSpellCharges = GetSpellCharges
function Spell:ActiveCharges()
    if(self.ChangesBased) then
        local currentCharges, maxCharges, lastChargeCooldownStart, chargeCooldownDuration = GetSpellCharges(self.Id)
        return currentCharges
    else
        return 0
    end
end

function Spell:Report()
    addon.Helper:Print({ "Id", self.Id, "Name", self.Name, "Key", self.Key })
end

addon.Initializer.NewSpell = NewSpell
