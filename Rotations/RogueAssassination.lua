local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@type table<string,Spell>
local spells = {
    SinisterStrike = {
        Id = 1752,
    },
    AutoAttack = {
        Id = 6603,
    },
    Mutilate = {
        Id = 1329,
    },
    Ambush = {
        Id = 8676,
    },
    Garrote = {
        Id = 703,
        Debuff = 703,
        Pandemic = 18 * 0.3
    },
    Eviscerate = {
        Id = 196819,
    },
    Envenom = {
        Id = 32645,
        Buff = 32645,
    },
    SliceAndDice = {
        Id = 315496,
        Buff = 315496,
    },
    Rupture = {
        Id = 1943,
        Debuff = 1943,
        Pandemic = 16 * 0.3
    },
    Shiv = {
        Id = 5938,
        Debuff = 319504,
        Pandemic = 8 * 0.3,
    },
    Deathmark = {
        Id = 360194,
        Debuff = 360194,
    },
    Vanish = {
        Id = 1856,
    },
    FanOfKnives = {
        Id = 51723,
    },
    CrimsonVial = {
        Id = 185311,
    },
}

---@type table<string,Item>
local items = {}

---@type Rotation
local rotation = {
    Name = "Rogue-Assassination",
    Spells = spells,
    Items = items,

    -- instance fields, init nils in Activate
    LocalEvents          = nil, ---@type EventTracker
    EmptyAction          = addon.Initializer.Empty.Action,
    Player               = addon.Player,
    InterruptUndesirable = addon.WowClass.InterruptUndesirable,
    RangeChecker         = spells.SinisterStrike,
    ComboFinisherToMax   = 2,

    -- locals
    Stealhed               = IsStealthed(), -- UPDATE_STEALTH, IsStealthed()
    InRange                = false,
    Energy                 = 0,
    EnergyDeficit          = 0,
    Combo                  = 0,
    ComboDeficit           = 0,
    ComboFinisherAllowed   = false,
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
    if (true)
    then
        self:Utility()
        if (self.CanAttackTarget and (not self.InInstance or self.InCombatWithTarget)) then
            if (self.InRange and self.Stealhed) then
                self:StealthOpener()
            end
            if (self.InRange) then
                self:AutoAttack()
                self:SingleTarget()
                -- if (not self.Settings.AOE) then
                --     self:SingleTarget()
                -- else
                --     self:Aoe()
                -- end
            end
        end
    end
end

local stealthOpenerList
function rotation:StealthOpener()
    stealthOpenerList = stealthOpenerList or
        {
            function() return spells.Ambush end,
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
            function() if (self.Combo > 0 and player.Buffs:Remains(spells.SliceAndDice.Buff) < self.ActionAdvanceWindow) then return spells.SliceAndDice end end,
            function() if (settings.Burst and target.Debuffs:Remains(spells.Rupture.Debuff) > 2 and target.Debuffs:Remains(spells.Garrote.Debuff) > 2) then return spells.Deathmark end end,
            function() if (self.CanDotTarget and self.ComboFinisherAllowed and target.Debuffs:Remains(spells.Rupture.Debuff) < spells.Rupture.Pandemic) then return spells.Rupture end end,
            function() if (self.ComboFinisherAllowed) then return spells.Envenom end end,
            function() if (settings.Burst and self.InInstance and spells.Vanish:ReadyIn() <= self.GcdReadyIn) then return (self.GcdReadyIn < 30) and spells.Vanish or self.EmptyAction end end, -- self.GcdReadyIn < self.ActionAdvanceWindow and spells.Vanish or self.EmptyAction
            function() if (self.CanDotTarget and target.Debuffs:Remains(spells.Garrote.Debuff) < spells.Garrote.Pandemic) then return spells.Garrote end end,
            function() if (target.Debuffs:Remains(spells.Shiv.Debuff) < spells.Shiv.Pandemic) then return spells.Shiv end end,
            function() if (self.Settings.AOE) then return spells.FanOfKnives end return spells.Mutilate end,
            -- function() return spells.AdaptiveSwarm end,
            -- function() if (self.EnergyDeficit > 55) then return spells.TigersFury end end,
            -- function() if (equip.Trinket13:IsInRange("target")) then return equip.Trinket13 end end,
            -- function() if (settings.Burst) then return spells.Berserk end end,
            -- function() if (settings.Burst) then return spells.ConvokeTheSpirits end end,
            -- function() if (self.Combo >= self.ComboCap and player.Buffs:Remains(spells.SavageRoar.Buff) < 10.8) then return spells.SavageRoar end end,
            -- function() if (self.CanDotTarget and self.Combo >= self.ComboCap and target.Debuffs:Remains(spells.Rip.Debuff) < 7.2) then return spells.Rip end end,
            -- function() if (self.Combo >= self.ComboCap) then if (self.Energy < 50) then return self.EmptyAction else return spells.FerociousBite end end end,
            -- function() if (self.CanDotTarget and target.Debuffs:Remains(spells.Rake.Debuff) < 4.5) then return spells.Rake end end,
            -- function() if (player.Buffs:Applied(spells.OmenOfClarity.Buff)) then return spells.Shred end end,
            -- function() if (player.Talents[spells.BrutalSlash.TalentId]) then return spells.BrutalSlash end end,
            -- function() return spells.Shred end,
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
            -- function() return spells.AdaptiveSwarm end,
            -- function() if (self.EnergyDeficit > 55) then return spells.TigersFury end end,
            -- function() if (equip.Trinket13:IsInRange("target")) then return equip.Trinket13 end end,
            -- function() if (settings.Burst) then return spells.Berserk end end,
            -- function() if (settings.Burst) then return spells.ConvokeTheSpirits end end,
            -- function() if (self.Combo >= self.ComboCap and player.Buffs:Remains(spells.SavageRoar.Buff) < 10.8) then return spells.SavageRoar end end,
            -- function() if (self.Combo >= self.ComboCap) then return spells.PrimalWrath end end,
            -- function() if (self.CanDotTarget and self.Combo >= self.ComboCap and target.Debuffs:Remains(spells.Rip.Debuff) < 7.2) then return spells.Rip end end,
            -- function() if (self.Combo >= self.ComboCap) then return spells.FerociousBite end end,
            -- function() if (self.CanDotTarget and target.Debuffs:Remains(spells.Rake.Debuff) < 4.5) then return spells.Rake end end,
            -- function() if (target.Debuffs:Remains(spells.Thrash.Debuff) < 4.5) then return spells.Thrash end end,
            -- function() if (player.Talents[spells.BrutalSlash.TalentId]) then return spells.BrutalSlash else return spells.Swipe end end,
            -- function() return spells.Thrash end, -- dump energy when Slash is out ouf charges
        }
    return rotation:RunPriorityList(aoeList)
end

local utilityList
function rotation:Utility()
    local player = self.Player
    utilityList = utilityList or
        {
            function() if (self.MyHealthPercentDeficit > 35 or self.MyHealAbsorb > 0) then return spells.CrimsonVial end end,
        }
    return rotation:RunPriorityList(utilityList)
end

local autoAttackList
function rotation:AutoAttack()
    autoAttackList = autoAttackList or
        {
            function() if (not spells.AutoAttack:IsQueued()) then return spells.AutoAttack end end,
        }
    return rotation:RunPriorityList(autoAttackList)
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
    self.ComboFinisherAllowed = self.ComboDeficit <= self.ComboFinisherToMax
    self.MyHealthPercent, self.MyHealthPercentDeficit = player:HealthPercent()
    self.MyHealAbsorb = player:HealAbsorb()
    self.GcdReadyIn = player:GCDReadyIn()
    self.NowCasting, self.CastingEndsIn = player:NowCasting()
    self.ActionAdvanceWindow = self.Settings.ActionAdvanceWindow
    self.InInstance = player:InInstance()
    self.InCombatWithTarget = player:InCombatWithTarget()
    self.CanAttackTarget = player:CanAttackTarget()
    self.CanDotTarget = player:CanDotTarget()
    self.MouseoverIsFriend, self.MouseoverIsEnemy = UnitIsFriend("player", "mouseover"), UnitIsEnemy("player", "mouseover")

    spells.Rupture.Pandemic = (4 + 4 * self.Combo) * 0.3
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
    function handlers.UPDATE_STEALTH(event, ...)
        self.Stealhed = IsStealthed()
    end

    return addon.Initializer.NewEventTracker(handlers):RegisterEvents()
end

function rotation:SetLayout()
    local spells = self.Spells
    spells.SliceAndDice.Key = "1"
    spells.Garrote.Key = "2"
    spells.SinisterStrike.Key = "3"
    spells.Ambush.Key = spells.SinisterStrike.Key
    spells.Mutilate.Key = spells.SinisterStrike.Key
    spells.Eviscerate.Key = "4"
    spells.Envenom.Key = spells.Eviscerate.Key
    spells.Rupture.Key = "5"
    spells.Shiv.Key = "6"
    spells.Deathmark.Key = "7"

    spells.FanOfKnives.Key = "8"

    spells.CrimsonVial.Key = "F6"
    spells.Vanish.Key = "F10"
    spells.AutoAttack.Key = "F12"

    local equip = addon.Player.Equipment
    equip.Trinket13.Key = "F11"
end

function test()
    return spells.AutoAttack:IsQueued()
end

addon:AddRotation("ROGUE", 1, rotation)
