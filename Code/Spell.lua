local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class Spell : Action
---@field Buff integer
---@field Debuff integer
---@field NoGCD boolean
---@field HasCD boolean
---@field ChargesBased boolean
---@field HardCast boolean
---@field Known boolean
---@field UserId integer
---@field SpellBookType string
---@field SpellBookSlot integer
---@field ProtectFromDoubleCast fun(self:Spell):Spell
---@field CCUnlockIn fun(self:Spell):number
---@field ActiveCharges fun(self:Spell):integer

local max, pairs, ipairs = max, pairs, ipairs

---@type Spell
local Spell = {}

---@param spell Spell
---@return Spell
local function NewSpell(spell)
    local spell = spell or addon.Helper.Throw("attempt to initialize nil player spell")
    if (spell.Id < 1) then
        addon.Helper.Throw("attempt to initialize empty player spell", spell.Id)
    end
    spell.Type = "Spell"
    addon.Helper.AddVirtualMethods(spell, Spell)
    return spell
end

local GetSpellCooldown = GetSpellCooldown
function Spell:ReadyIn()
    local now = addon.Rotation.Timestamp
    local start, duration, enabled = GetSpellCooldown(self.Id)
    if start then
        return max(0, start + duration - now) -- seconds
    end
    addon.Helper.Throw("Spell returned no cooldown", self.Id, self.Name)
end

local GetSpellInfo, IsSpellKnownOrOverridesKnown, IsPlayerSpell, GetSpellBaseCooldown, GetSpellCharges, IsPassiveSpell, GetOverrideSpell, FindSpellBookSlotBySpellID = GetSpellInfo, IsSpellKnownOrOverridesKnown, IsPlayerSpell, GetSpellBaseCooldown, GetSpellCharges, IsPassiveSpell, C_SpellBook.GetOverrideSpell, FindSpellBookSlotBySpellID
function addon:UpdateKnownSpells()
    ---@param key string
    ---@param spell Spell
    ---@return fun()
    local function MakeSpellUpdater(key, spell)
        return function()
            local overrideId = GetOverrideSpell(spell.Id)
            if (overrideId ~= spell.Id) then
                spell.Id = overrideId
                addon.DataQuery.OnSpellLoaded(spell.Id, MakeSpellUpdater(key, spell))
                return
            end
            local name, rank, icon, castTime, minRange, maxRange, spellID = GetSpellInfo(spell.Id)
            if (not name) then
                addon.Helper.Throw(key, "GetSpellInfo failed")
            end
            spell.Name = name
            spell.Icon = icon
            spell.HardCast = castTime > 0
            if (IsPassiveSpell(spell.Id)) then -- name ~= nil, IsPlayerSpell(spell.Id), IsSpellKnownOrOverridesKnown(spell.Id)
                spell.Known = IsPlayerSpell(spell.Id)
            else
                spell.SpellBookType = BOOKTYPE_SPELL -- also BOOKTYPE_PET if added some time
                spell.SpellBookSlot = FindSpellBookSlotBySpellID(spell.Id)
                spell.Known = spell.SpellBookSlot ~= nil
            end
            local cooldownMS, gcdMS = GetSpellBaseCooldown(spell.Id)
            spell.NoGCD = gcdMS == 0
            spell.HasCD = cooldownMS > 0
            spell.ChargesBased = (GetSpellCharges(spell.Id)) ~= nil
        end
    end

    local spells = self.Rotation.Spells
    for key, spell in pairs(spells) do
        if (spell.Id > 0) then
            spell.UserId = spell.UserId and spell.UserId or spell.Id
            spell.Id = spell.UserId and spell.UserId or spell.Id
            addon.DataQuery.OnSpellLoaded(spell.Id, MakeSpellUpdater(key, spell))
        end
    end
end

function Spell:IsAvailable()
    return self.Known
end

local IsUsableSpell = IsUsableSpell
function Spell:IsUsableNow()
    local actionAdvanceWindow = addon.Rotation.Settings.ActionAdvanceWindow
    if (self:CCUnlockIn() > actionAdvanceWindow) then
        return false, false
    end
    local usable, noMana = IsUsableSpell(self.SpellBookSlot, self.SpellBookType)
    if (usable == nil) then
        return false, false
    end
    if (usable) then
        local onCD = (self.HasCD or self.ChargesBased) and self:ReadyIn() > actionAdvanceWindow
        usable = not onCD
    end
    return usable, noMana
end

local IsSpellInRange = IsSpellInRange
function Spell:IsInRange(unit)
    unit = unit or "target"
    if (self.SpellBookSlot and self.SpellBookType) then
        return (IsSpellInRange(self.SpellBookSlot, self.SpellBookType, unit) or 0) == 1
    else
        return false
    end
end

local IsCurrentSpell = IsCurrentSpell
function Spell:IsQueued()
    return IsCurrentSpell(self.Id)
end

local GetSpellLossOfControlCooldown = GetSpellLossOfControlCooldown
function Spell:CCUnlockIn()
    local now = addon.Rotation.Timestamp
    local start, duration = GetSpellLossOfControlCooldown(self.Id)
    return start and max(0, start + duration - now) or 0
end

local GetSpellCharges = GetSpellCharges
function Spell:ActiveCharges()
    if (self.ChargesBased) then
        local currentCharges, maxCharges, lastChargeCooldownStart, chargeCooldownDuration = GetSpellCharges(self.Id)
        return currentCharges
    else
        return 0
    end
end

local emptySpell = addon.Initializer.Empty.Action
function Spell:ProtectFromDoubleCast()
    if (self:IsQueued()) then
        return emptySpell
    end
    return self
end

function Spell:Report()
    addon.Helper.Print("Id", self.Id, "Name", self.Name, "Key", self.Key)
end

-- attach to addon
addon.Initializer.NewSpell = NewSpell
