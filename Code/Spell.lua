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
---@field CastCount fun(self:Spell):integer
---@field IsAutoRepeat fun(self:Spell):boolean

local max, pairs, ipairs = max, pairs, ipairs
local C_Spell, C_SpellBook = C_Spell, C_SpellBook

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

function Spell:ReadyIn()
    local now = addon.Timestamp
    local spellCooldownInfo = C_Spell.GetSpellCooldown(self.Id)
    if spellCooldownInfo then
        return max(0, spellCooldownInfo.startTime + spellCooldownInfo.duration - now) -- seconds
    end
    addon.Helper.Throw("Spell returned no cooldown", self.Id, self.Name)
end

local IsPlayerSpell, GetSpellBaseCooldown = IsPlayerSpell, GetSpellBaseCooldown
function addon:UpdateKnownSpells()
    ---@param key string
    ---@param spell Spell
    ---@return fun()
    local function MakeSpellUpdater(key, spell)
        return function()
            local overrideId = C_Spell.GetOverrideSpell(spell.Id)
            if (overrideId ~= spell.Id) then
                spell.Id = overrideId
                addon.DataQuery.OnSpellLoaded(spell.Id, MakeSpellUpdater(key, spell))
                return
            end
            local spellInfo = C_Spell.GetSpellInfo(spell.Id)
            if (not spellInfo) then
                addon.Helper.Throw(key, "GetSpellInfo failed")
            end
            spell.Name = spellInfo.name
            spell.Icon = spellInfo.iconID
            spell.HardCast = spellInfo.castTime > 0
            spell.IsPassive = C_Spell.IsSpellPassive(spell.Id)
            spell.SpellBookSlot, spell.SpellBookType = C_SpellBook.FindSpellBookSlotForSpell(spell.Id)
            spell.Known = spell.IsPassive and IsPlayerSpell(spell.Id) or spell.SpellBookSlot ~= nil
            local cooldownMS, gcdMS = GetSpellBaseCooldown(spell.Id)
            spell.NoGCD = gcdMS == 0
            spell.HasCD = cooldownMS > 0
            spell.ChargesBased = C_Spell.GetSpellCharges(spell.Id) ~= nil
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

function Spell:IsUsableNow()
    local actionAdvanceWindow = addon.Rotation.Settings.ActionAdvanceWindow
    if (self:CCUnlockIn() > actionAdvanceWindow) then
        return false, false
    end
    local usable, insufficientPower = C_Spell.IsSpellUsable(self.Id)
    if (usable == nil) then
        return false, false
    end
    if (usable) then
        local onCD = self:ReadyIn() > (addon.Rotation.GcdReadyIn + 0.1) -- (self.HasCD or self.ChargesBased) and
        usable = not onCD
    end
    return usable, insufficientPower
end

function Spell:IsInRange(unit)
    unit = unit or "target"
    if (self.Known) then
        return C_Spell.IsSpellInRange(self.Id, unit) or false
    else
        return false
    end
end

function Spell:IsQueued()
    return C_Spell.IsCurrentSpell(self.Id)
end

function Spell:CCUnlockIn()
    local now = addon.Timestamp
    local start, duration = C_Spell.GetSpellLossOfControlCooldown(self.Id)
    return start and max(0, start + duration - now) or 0
end

function Spell:ActiveCharges()
    if (self.ChargesBased) then
        local spellChargeInfo = C_Spell.GetSpellCharges(self.Id)
        return spellChargeInfo.currentCharges
    else
        return 0
    end
end

function Spell:CastCount()
    return C_Spell.GetSpellCastCount(self.Id)
end

function Spell:IsAutoRepeat()
    return C_Spell.IsAutoRepeatSpell(self.Id) or false
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
