local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@type table<string,Spell>
local spells = {
    TigersFury = {
        Id = 5217,
        Buff = 5217,
    },
    Rake = {
        Id = 1822,
        Debuff = 155722,
    },
    Shred = {
        Id = 5221,
    },
    FerociousBite = {
        Id = 22568,
    },
    Rip = {
        Id = 1079,
        Debuff = 1079,
    },
    Berserk = {
        Id = 106951,
        Buff = 106951,
    },
    Thrash = {
        Id = 106832,
        Debuff = 106830,
    },
    Swipe = {
        Id = 213764,
    },
    -- talents
    BrutalSlash = {
        Id = 202028,
        TalentId = 21711,
    },
    PrimalWrath = {
        Id = 285381,
        TalentId = 22370,
    },
    SavageRoar = {
        Id = 52610,
        Buff = 52610,
        TalentId = 18579,
    },
    -- defensives
    Barkskin = {
        Id = 22812,
        Buff = 22812,
    },
    SurvivalInstincts = {
        Id = 61336,
        Buff = 61336,
    },
    Regrowth = {
        Id = 8936,
    },
    -- CC and utility spells
    Maim = {
        Id = 22570,
        Debuff = 203123,
    },
    -- shapeshit forms
    CatForm = {
        Id = 768,
        Buff = 768,
    },
    BearForm = {
        Id = 5487,
        Buff = 5487,
    },
    TravelForm = {
        Id = 783,
        Buff = 783,
    },
    BoomkinForm = {
        Id = 197625,
        Buff = 197625,
    },
    -- utility
    Soothe = {
        Id = 2908,
    },
    RemoveCorruption = {
        Id = 2782,
    },
    -- Procs
    OmenOfClarity = {
        Id = 16864,
        Buff = 135700, -- Clear casting
    },
    PredatorySwiftness = {
        Id = 16974,
        Buff = 69369,
    },
    -- Shadowlands specials
    AdaptiveSwarm = {
        Id = 325727,
    },
    ConvokeTheSpirits = {
        Id = 323764,
    },
}

---@type table<string,Item>
local items = {}

---@type Rotation
local rotation = {
    Spells = spells,
    Items = items,

    -- instance fields, init nils in Activate
    LocalEvents      = nil, ---@type EventTracker
    EmptyAction      = addon.Initializer.Empty.Action,
    Player           = addon.Player,
    RangeChecker     = spells.Rake,
    ComboCap         = 4,
    DispellableTypes = addon.Helper.ToHashSet({ "Curse", "Poison", }),

    -- locals
    Stealhed               = IsStealthed(), -- UPDATE_STEALTH, IsStealthed()
    InRange                = false,
    Energy                 = 0,
    EnergyDeficit          = 0,
    Combo                  = 0,
    ComboDeficit           = 0,
    ManaPercent            = 0,
    GcdReadyIn             = 0,
    CastingEndsIn          = 0,
    CCUnlockIn             = 0,
    ActionAdvanceWindow    = 0,
    MyHealthPercent        = 0,
    MyHealthPercentDeficit = 0,
    MyHealAbsorb           = 0,
    InInstance             = false,
    InCombatWithTarget     = false,
    CanAttackTarget        = false,
    CanDotTarget           = false,
    LastCastSent           = 0,
    MouseoverIsFriend      = false,
    MouseoverIsEnemy       = false,
}

function rotation:SelectAction()
    self:Refresh()
    local playerBuffs = self.Player.Buffs
    local targetDebuffs = self.Player.Target.Debuffs
    if (playerBuffs:Applied(spells.CatForm.Buff)
        and (not self.InInstance or self.InCombatWithTarget)
        and self.CastingEndsIn <= self.ActionAdvanceWindow
        )
    then
        self:Utility()
        if (self.InRange and self.CanAttackTarget) then
            if (self.Stealhed) then
                self:StealthOpener()
            end
            if (not self.Settings.AOE) then
                self:SingleTarget()
            else
                self:Aoe()
            end
        end
    end
end

local stealthOpenerList
function rotation:StealthOpener()
    stealthOpenerList = stealthOpenerList or
        {
            function() return spells.Rake end,
        }
    return rotation:RunPriorityList(stealthOpenerList)
end

local singleTargetList
function rotation:SingleTarget()
    local settings = self.Settings
    local player = self.Player
    local target = self.Player.Target
    local equip = player.Equipment
    singleTargetList = singleTargetList or
        {
            function() return spells.AdaptiveSwarm end,
            function() if (self.EnergyDeficit > 55) then return spells.TigersFury end end,
            function() if (equip.Trinket13:IsInRange("target")) then return equip.Trinket13 end end,
            function() if (settings.Burst) then return spells.ConvokeTheSpirits end end,
            function() if (settings.Burst) then return spells.Berserk end end,
            function() if (self.Combo >= self.ComboCap and player.Buffs:Remains(spells.SavageRoar.Buff) < 10.8) then return spells.SavageRoar end end,
            function() if (self.CanDotTarget and self.Combo >= self.ComboCap and target.Debuffs:Remains(spells.Rip.Debuff) < 7.2) then return spells.Rip end end,
            function() if (self.Combo >= self.ComboCap) then if (self.Energy < 50) then return self.EmptyAction else return spells.FerociousBite end end end,
            function() if (self.CanDotTarget and target.Debuffs:Remains(spells.Rake.Debuff) < 4.5) then return spells.Rake end end,
            function() if (player.Buffs:Applied(spells.OmenOfClarity.Buff)) then return spells.Shred end end,
            function() if (player.Talents[spells.BrutalSlash.TalentId]) then return spells.BrutalSlash end end,
            function() return spells.Shred end,
        }
    return rotation:RunPriorityList(singleTargetList)
end

local aoeList
function rotation:Aoe()
    local settings = self.Settings
    local player = self.Player
    local target = self.Player.Target
    local equip = player.Equipment
    aoeList = aoeList or
        {
            function() return spells.AdaptiveSwarm end,
            function() if (self.EnergyDeficit > 55) then return spells.TigersFury end end,
            function() if (equip.Trinket13:IsInRange("target")) then return equip.Trinket13 end end,
            function() if (settings.Burst) then return spells.ConvokeTheSpirits end end,
            function() if (settings.Burst) then return spells.Berserk end end,
            function() if (self.Combo >= self.ComboCap and player.Buffs:Remains(spells.SavageRoar.Buff) < 10.8) then return spells.SavageRoar end end,
            function() if (self.Combo >= self.ComboCap) then return spells.PrimalWrath end end,
            function() if (self.CanDotTarget and self.Combo >= self.ComboCap and target.Debuffs:Remains(spells.Rip.Debuff) < 7.2) then return spells.Rip end end,
            function() if (self.Combo >= self.ComboCap) then if (self.Energy < 50) then return self.EmptyAction else return spells.FerociousBite end end end,
            function() if (self.CanDotTarget and target.Debuffs:Remains(spells.Rake.Debuff) < 4.5) then return spells.Rake end end,
            function() if (target.Debuffs:Remains(spells.Thrash.Debuff) < 4.5) then return spells.Thrash end end,
            function() if (player.Talents[spells.BrutalSlash.TalentId]) then return spells.BrutalSlash else return spells.Swipe end end,
            function() return spells.Thrash end, -- dump energy when Slash is out ouf charges
        }
    return rotation:RunPriorityList(aoeList)
end

local utilityList
function rotation:Utility()
    local settings = self.Settings
    local player = self.Player
    local target = self.Player.Target
    local mouseover = self.Player.Mouseover
    local function CanDispel()
        if (self.MouseoverIsFriend) then
            return mouseover.Debuffs:HasDispelable(self.DispellableTypes)
        end
        if (self.MouseoverIsEnemy) then
            return mouseover.Buffs:HasPurgeable()
        end
        return false
    end

    utilityList = utilityList or
        {
            function() if ((self.MyHealthPercentDeficit > 15 or self.MyHealAbsorb > 0) and player.Buffs:Remains(spells.PredatorySwiftness.Buff) > self.GcdReadyIn + 0.5 and not spells.Regrowth:IsQueued()) then return spells.Regrowth end end,
            function() if (settings.Dispel and spells.RemoveCorruption:IsInRange("mouseover") and CanDispel() and self.ManaPercent > 6.5) then
                    if (self.MouseoverIsFriend) then return spells.RemoveCorruption end
                    if (self.MouseoverIsEnemy) then return spells.Soothe end
                end
            end,
        }
    return rotation:RunPriorityList(utilityList)
end

local UnitIsFriend, UnitIsEnemy = UnitIsFriend, UnitIsEnemy
function rotation:Refresh()
    local player = self.Player
    local timestamp = self.Timestamp
    player.Buffs:Refresh(timestamp)
    player.Debuffs:Refresh(timestamp)
    player.Target.Buffs:Refresh(timestamp)
    player.Target.Debuffs:Refresh(timestamp)
    player.Mouseover.Buffs:Refresh(timestamp)
    player.Mouseover.Debuffs:Refresh(timestamp)

    self.InRange = self.RangeChecker:IsInRange("target")
    self.Energy, self.EnergyDeficit = player:Resource(Enum.PowerType.Energy)
    self.Combo, self.ComboDeficit = player:Resource(Enum.PowerType.ComboPoints)
    self.ManaPercent = player:ResourcePercent(Enum.PowerType.Mana)
    self.MyHealthPercent, self.MyHealthPercentDeficit = player:HealthPercent()
    self.MyHealAbsorb = player:HealAbsorb()
    self.GcdReadyIn = player:GCDReadyIn()
    self.CastingEndsIn = player:CastingEndsIn()
    self.ActionAdvanceWindow = self.Settings.ActionAdvanceWindow
    self.InInstance = player:InInstance()
    self.InCombatWithTarget = player:InCombatWithTarget()
    self.CanAttackTarget = player:CanAttackTarget()
    self.CanDotTarget = player:CanDotTarget()
    self.MouseoverIsFriend, self.MouseoverIsEnemy = UnitIsFriend("player", "mouseover"), UnitIsEnemy("player", "mouseover")
end

function rotation:Dispose()
    self.LocalEvents:Dispose()
    self.LocalEvents = nil
end

function rotation:Activate()
    addon.Player.Buffs = addon.Initializer.NewAuraCollection("player", "PLAYER|HELPFUL")
    addon.Player.Debuffs = addon.Initializer.NewAuraCollection("player", "HARMFUL")
    addon.Player.Target.Buffs = addon.Initializer.NewAuraCollection("target", "HELPFUL")
    addon.Player.Target.Debuffs = addon.Initializer.NewAuraCollection("target", "PLAYER|HARMFUL")
    addon.Player.Mouseover.Buffs = addon.Initializer.NewAuraCollection("mouseover", "HELPFUL")
    addon.Player.Mouseover.Debuffs = addon.Initializer.NewAuraCollection("mouseover", "RAID|HARMFUL")

    self.WaitForResource = true
    self.LocalEvents = self:CreateLocalEventTracker()
    self:SetLayout()
end

function rotation:CreateLocalEventTracker()
    local handlers = {}

    local IsStealthed = IsStealthed
    function handlers.UPDATE_STEALTH(event, eventArgs)
        self.Stealhed = IsStealthed()
    end

    function handlers.UNIT_SPELLCAST_SENT(event, eventArgs)
        if (eventArgs[1] == "player") then
            self.LastCastSent = self.LocalEvents.EventTimestamp
        end
    end

    return addon.Initializer.NewEventTracker(handlers):RegisterEvents()
end

function rotation:SetLayout()
    local spells = self.Spells
    spells.TigersFury.Key = "1"
    spells.Rake.Key = "2"
    spells.Shred.Key = "3"
    spells.FerociousBite.Key = "4"
    spells.Rip.Key = "5"
    spells.AdaptiveSwarm.Key = "6"
    spells.ConvokeTheSpirits.Key = "6"
    spells.Berserk.Key = "7"
    spells.Thrash.Key = "8"
    spells.Swipe.Key = "9"
    spells.BrutalSlash.Key = "9"
    spells.PrimalWrath.Key = "0"
    spells.Regrowth.Key = "-"
    spells.Soothe.Key = "F6"
    spells.RemoveCorruption.Key = "F6"
    spells.SavageRoar.Key = "F1"

    local equip = addon.Player.Equipment
    equip.Trinket13.Key = "F11"
end

addon:AddRotation("DRUID", 2, rotation)
