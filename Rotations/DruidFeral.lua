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
local items = addon.Common.Items

---@type Rotation
local rotation = {
    Name = "Druid-Feral",
    Spells = spells,
    Items = items,

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
    NowCasting             = 0,
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
    if (playerBuffs:Applied(spells.CatForm.Buff))
    then
        self:Utility()
        if (self.CanAttackTarget and (not self.InInstance or self.InCombatWithTarget)) then
            if (self.InRange and self.Stealhed) then
                self:StealthOpener()
            end
            self:Dispel()
            if (self.InRange) then
                if (not self.Settings.AOE) then
                    self:SingleTarget()
                else
                    self:Aoe()
                end
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
            function() if (settings.Burst) then return spells.Berserk end end,
            function() if (settings.Burst) then return spells.ConvokeTheSpirits end end,
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
            function() if (settings.Burst) then return spells.Berserk end end,
            function() if (settings.Burst) then return spells.ConvokeTheSpirits end end,
            function() if (self.Combo >= self.ComboCap and player.Buffs:Remains(spells.SavageRoar.Buff) < 10.8) then return spells.SavageRoar end end,
            function() if (self.Combo >= self.ComboCap) then return spells.PrimalWrath end end,
            function() if (self.CanDotTarget and self.Combo >= self.ComboCap and target.Debuffs:Remains(spells.Rip.Debuff) < 7.2) then return spells.Rip end end,
            function() if (self.Combo >= self.ComboCap) then return spells.FerociousBite end end,
            function() if (self.CanDotTarget and target.Debuffs:Remains(spells.Rake.Debuff) < 4.5) then return spells.Rake end end,
            function() if (target.Debuffs:Remains(spells.Thrash.Debuff) < 4.5) then return spells.Thrash end end,
            function() if (player.Talents[spells.BrutalSlash.TalentId]) then return spells.BrutalSlash else return spells.Swipe end end,
            function() return spells.Thrash end, -- dump energy when Slash is out ouf charges
        }
    return rotation:RunPriorityList(aoeList)
end

local utilityList
function rotation:Utility()
    local player = self.Player
    utilityList = utilityList or
        {
            function() if ((self.MyHealthPercentDeficit > 15 or self.MyHealAbsorb > 0) and player.Buffs:Remains(spells.PredatorySwiftness.Buff) > self.GcdReadyIn + 0.5) then return spells.Regrowth:ProtectFromDoubleCast() end end,
            function() if (self.MyHealthPercentDeficit > 65) then return items.Healthstone end end,
        }
    return rotation:RunPriorityList(utilityList)
end

local mouseoverList
function rotation:Dispel()
    local settings = self.Settings
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

    mouseoverList = mouseoverList or {
        function()
            if (settings.Dispel and CanDispel() and self.ManaPercent > 6.5) then
                if (self.MouseoverIsFriend and spells.RemoveCorruption:IsInRange("mouseover")) then return spells.RemoveCorruption end
                if (self.MouseoverIsEnemy and spells.Soothe:IsInRange("mouseover")) then return spells.Soothe end
            end
        end,
    }
    return rotation:RunPriorityList(mouseoverList)
end

function rotation:Refresh()
    local player = self.Player
    local timestamp = self.Timestamp
    player.Buffs:Refresh(timestamp)
    player.Debuffs:Refresh(timestamp)
    player.Target.Buffs:Refresh(timestamp)
    player.Target.Debuffs:Refresh(timestamp)
    player.Mouseover.Buffs:Refresh(timestamp)
    player.Mouseover.Debuffs:Refresh(timestamp)

    self.InRange = self.RangeChecker:IsInRange()
    self.Energy, self.EnergyDeficit = player:Resource(Enum.PowerType.Energy)
    self.Combo, self.ComboDeficit = player:Resource(Enum.PowerType.ComboPoints)
    self.ManaPercent = player:ResourcePercent(Enum.PowerType.Mana)
    self.MyHealthPercent, self.MyHealthPercentDeficit = player:HealthPercent()
    self.MyHealAbsorb = player:HealAbsorb()
    self.GcdReadyIn = player:GCDReadyIn()
    self.NowCasting, self.CastingEndsIn = player:NowCasting()
    self.ActionAdvanceWindow = self.Settings.ActionAdvanceWindow
    self.InInstance = player:InInstance()
    self.InCombatWithTarget = player.Target:InCombatWithMe()
    self.CanAttackTarget = player.Target:CanAttack()
    self.CanDotTarget = player.Target:CanDot()
    self.MouseoverIsFriend, self.MouseoverIsEnemy = player.Mouseover:IsFriend(), player.Mouseover:IsEnemy()
end

function rotation:Dispose()
    self.LocalEvents:Dispose()
    self.LocalEvents = nil
end

function rotation:Activate()
    self.EmptyAction = addon.Initializer.Empty.Action
    self.Player = addon.Player
    self.InterruptUndesirable = addon.WowClass.InterruptUndesirable
    self.LocalEvents = self:CreateLocalEventTracker()
    self:SetLayout()
end

function rotation:CreateLocalEventTracker()
    local frameHandlers = {}

    local IsStealthed = IsStealthed
    function frameHandlers.UPDATE_STEALTH(event, ...)
        self.Stealhed = IsStealthed()
    end

    function frameHandlers.UNIT_SPELLCAST_SENT(event, ...)
        local unit = ...
        if (unit == "player") then
            self.LastCastSent = self.LocalEvents.EventTimestamp
        end
    end

    return addon.Initializer.NewEventTracker(frameHandlers):RegisterEvents()
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
    spells.BrutalSlash.Key = spells.Swipe.Key
    spells.PrimalWrath.Key = "0"
    spells.Regrowth.Key = "-"
    spells.Soothe.Key = "F6"
    spells.RemoveCorruption.Key = "F6"
    spells.SavageRoar.Key = "F1"

    local equip = addon.Player.Equipment
    equip.Trinket13.Key = "F11"

    local items = self.Items
    items.Healthstone.Key = "F12"
end

addon:AddRotation("DRUID", 2, rotation)
