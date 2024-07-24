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
---@field IsPassive boolean
---@field SpellBookType integer
---@field SpellBookSlot integer
---@field ProtectFromDoubleCast fun(self:Spell):Spell
---@field CCUnlockIn fun(self:Spell):number
---@field ActiveCharges fun(self:Spell):integer
---@field IsAutoRepeat fun(self:Spell):boolean

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

local GetSpellCooldown = C_Spell.GetSpellCooldown
function Spell:ReadyIn()
    local now = addon.Timestamp
    local spellCooldownInfo = GetSpellCooldown(self.Id)
    if spellCooldownInfo then
        return max(0, spellCooldownInfo.startTime + spellCooldownInfo.duration - now) -- seconds
    end
    addon.Helper.Throw("Spell returned no cooldown", self.Id, self.Name)
end

local GetSpellInfo, IsPlayerSpell, GetSpellBaseCooldown, GetSpellCharges, IsSpellPassive, GetOverrideSpell, FindSpellBookSlotForSpell = C_Spell.GetSpellInfo, IsPlayerSpell, GetSpellBaseCooldown, C_Spell.GetSpellCharges, C_Spell.IsSpellPassive, C_Spell.GetOverrideSpell, C_SpellBook.FindSpellBookSlotForSpell
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
            local spellInfo = GetSpellInfo(spell.Id)
            if (not spellInfo) then
                addon.Helper.Throw(key, "GetSpellInfo failed")
            end
            spell.Name = spellInfo.name
            spell.Icon = spellInfo.iconID
            spell.HardCast = spellInfo.castTime > 0
            spell.IsPassive = IsSpellPassive(spell.Id)
            spell.SpellBookSlot, spell.SpellBookType = FindSpellBookSlotForSpell(spell.Id)
            spell.Known = spell.IsPassive and IsPlayerSpell(spell.Id) or spell.SpellBookSlot ~= nil
            local cooldownMS, gcdMS = GetSpellBaseCooldown(spell.Id)
            spell.NoGCD = gcdMS == 0
            spell.HasCD = cooldownMS > 0
            spell.ChargesBased = GetSpellCharges(spell.Id) ~= nil
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

local IsUsableSpell = C_Spell.IsSpellUsable
function Spell:IsUsableNow()
    local actionAdvanceWindow = addon.Rotation.Settings.ActionAdvanceWindow
    if (self:CCUnlockIn() > actionAdvanceWindow) then
        return false, false
    end
    local usable, insufficientPower = IsUsableSpell(self.Id)
    if (usable == nil) then
        return false, false
    end
    if (usable) then
        local onCD = self:ReadyIn() > (addon.Rotation.GcdReadyIn + 0.1) -- (self.HasCD or self.ChargesBased) and
        usable = not onCD
    end
    return usable, insufficientPower
end

local IsSpellInRange = C_Spell.IsSpellInRange
function Spell:IsInRange(unit)
    unit = unit or "target"
    if (self.Known) then
        return IsSpellInRange(self.Id, unit) or false
    else
        return false
    end
end

local IsCurrentSpell = C_Spell.IsCurrentSpell
function Spell:IsQueued()
    return IsCurrentSpell(self.Id)
end

local GetSpellLossOfControlCooldown = C_Spell.GetSpellLossOfControlCooldown
function Spell:CCUnlockIn()
    local now = addon.Timestamp
    local start, duration = GetSpellLossOfControlCooldown(self.Id)
    return start and max(0, start + duration - now) or 0
end

local GetSpellCharges = C_Spell.GetSpellCharges
function Spell:ActiveCharges()
    if (self.ChargesBased) then
        local spellChargeInfo = GetSpellCharges(self.Id)
        return spellChargeInfo.currentCharges
    else
        return 0
    end
end

local IsAutoRepeatSpell = C_Spell.IsAutoRepeatSpell
function Spell:IsAutoRepeat()
    return IsAutoRepeatSpell(self.Id) or false
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
