local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@type table<string,Spell>
local spells = {
    AutoAttack = addon.Common.Spells.AutoAttack,
    SinisterStrike = {
        Id = 1752,
    },
    Kick = {
        Id = 1766,
    },
    Mutilate = {
        Id = 1329,
    },
    Ambush = {
        Id = 8676,
    },
    Blindside = {
        Id = 328085,
        Buff = 121153,
    },
    Garrote = {
        Id = 703,
        Debuff = 703,
        Pandemic = 18 * 0.3,
    },
    Eviscerate = {
        Id = 196819,
    },
    Envenom = {
        Id = 32645,
        Buff = 32645,
        Pandmic = 4 * 0.3,
    },
    SliceAndDice = {
        Id = 315496,
        Buff = 315496,
    },
    Rupture = {
        Id = 1943,
        Debuff = 1943,
        Pandemic = 16 * 0.3,
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
    CrimsonTempest = {
        Id = 121411,
        Debuff = 121411,
        Pandemic = 8 * 0.3,
    },
    CrimsonVial = {
        Id = 185311,
    },
    Feint = {
        Id = 1966,
    },
    MarkedForDeath = {
        Id = 137619,
    },
    ThistleTea = {
        Id = 381623,
    },
    KidneyShot = {
        Id = 408,
    },
}

local cmds = {
    Kidney = {
        Name = "kidney",
    },
    Feint = {
        Name = "feint"
    },
    Kick = {
        Name = "kick",
    }
}

---@type table<string,Item>
local items = addon.Common.Items

---@type Rotation
local rotation = {
    Name                   = "Rogue-Assassination",
    Spells                 = spells,
    Items                  = items,
    Cmds                   = cmds,
    RangeChecker           = spells.SinisterStrike,
    ComboFinisherToMax     = 2,
    ComboKidney            = 4,
    -- locals
    Stealhed               = IsStealthed(), -- UPDATE_STEALTH, IsStealthed()
    InRange                = false,
    Energy                 = 0,
    EnergyDeficit          = 0,
    Combo                  = 0,
    ComboDeficit           = 0,
    ComboFinisherAllowed   = false,
    ComboHolding           = false,
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
            function() if (self.CmdBus:Find(cmds.Kick.Name) and target:CanKick(true)) then return spells.Kick end end,
            function() if (self.CmdBus:Find(cmds.Kidney.Name)) then return self:KidneyOnCommand() end end,
            function() if (self.Combo > 0 and not self.ComboHolding and not player.Buffs:Applied(spells.SliceAndDice.Buff)) then return spells.SliceAndDice end end,
            function() if (settings.Burst and not self.Settings.AOE and target.Debuffs:Remains(spells.Rupture.Debuff) > 2 and target.Debuffs:Remains(spells.Garrote.Debuff) > 2) then return spells.Deathmark end end,
            function() if (self.Energy < 30 and not self.ComboHolding) then return spells.ThistleTea end end,
            function()
                if (self.ComboFinisherAllowed and not self.ComboHolding and self.CanDotTarget and (not self.Settings.AOE and target.Debuffs:Remains(spells.Rupture.Debuff) < spells.Rupture.Pandemic or
                    (self.EnergyDeficit > 50 and not target.Debuffs:Applied(spells.Rupture.Debuff)))) then
                    return spells.Rupture
                end
            end,
            function() if (self.ComboFinisherAllowed and not self.ComboHolding and self.Settings.AOE) then return spells.CrimsonTempest end end,
            function() if (self.ComboFinisherAllowed and not self.ComboHolding) then return spells.Envenom end end,
            function() if (self.Combo < 1 and player.Buffs:Remains(spells.SliceAndDice.Buff) > 2 and not target:IsTotem()) then return spells.MarkedForDeath end end,
            function() if (settings.Burst and not self.Settings.AOE and self.InInstance and spells.Vanish:ReadyIn() <= self.GcdReadyIn) then return self:AwaitedVanishAmbush() end end,
            function() if (self.CanDotTarget and (not self.Settings.AOE and target.Debuffs:Remains(spells.Garrote.Debuff) < spells.Garrote.Pandemic or (not target.Debuffs:Applied(spells.Garrote.Debuff)))) then return spells.Garrote end end,
            function() if (self.Settings.AOE) then return spells.FanOfKnives end end,
            function() if (target.Debuffs:Remains(spells.Shiv.Debuff) < spells.Shiv.Pandemic) then return spells.Shiv end end,
            function() return spells.Ambush end,
            function() return spells.Mutilate end,
        }
    return rotation:RunPriorityList(singleTargetList)
end

local utilityList
function rotation:Utility()
    local player = self.Player
    utilityList = utilityList or
        {
            function() if (self.CmdBus:Find(cmds.Feint.Name)) then return spells.Feint end end,
            function() if (self.MyHealthPercentDeficit > 35 or self.MyHealAbsorb > 0) then return spells.CrimsonVial end end,
            function() if (self.MyHealthPercentDeficit > 65) then return items.Healthstone end end,
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

function rotation:DelayedEnvenom()
    local player = self.Player
    if (player.Buffs:Remains(spells.Envenom.Buff) < spells.Envenom.Pandmic or self.ComboDeficit <= 1) then
        return spells.Envenom
    end
end

function rotation:AwaitedVanishAmbush()
    if (self.GcdReadyIn < 0.01 and (self.Energy > 50 or self.Player.Buffs:Applied(spells.Blindside.Buff))) then
        return spells.Vanish
    else
        return self.EmptyAction
    end
end

function rotation:KidneyOnCommand()
    local readyIn = spells.KidneyShot:ReadyIn()
    if (readyIn < 2) then
        if (self.Combo < self.ComboKidney) then
            self.ComboHolding = true
            return nil
        end
        return (readyIn > self.ActionAdvanceWindow) and self.EmptyAction or spells.KidneyShot
    end
end

function rotation:ComboPandemic(initialDuration)
    return initialDuration * (1 + self.Combo) * 0.3
end

function rotation:Refresh()
    local player = self.Player
    local timestamp = self.Timestamp
    player.Buffs:Refresh(timestamp)
    player.Debuffs:Refresh(timestamp)
    player.Target.Buffs:Refresh(timestamp)
    player.Target.Debuffs:Refresh(timestamp)

    self.InRange = self.RangeChecker:IsInRange()
    self.Energy, self.EnergyDeficit = player:Resource(Enum.PowerType.Energy)
    self.Combo, self.ComboDeficit = player:Resource(Enum.PowerType.ComboPoints)
    self.ComboFinisherAllowed = self.ComboDeficit <= self.ComboFinisherToMax
    self.ComboHolding = false
    self.MyHealthPercent, self.MyHealthPercentDeficit = player:HealthPercent()
    self.MyHealAbsorb = player:HealAbsorb()
    self.NowCasting, self.CastingEndsIn = player:NowCasting()
    self.ActionAdvanceWindow = self.Settings.ActionAdvanceWindow
    self.InInstance = player:InInstance()
    self.InCombatWithTarget = player.Target:InCombatWithMe()
    self.CanAttackTarget = player.Target:CanAttack()
    self.CanDotTarget = player.Target:CanDot()

    spells.Rupture.Pandemic = self:ComboPandemic(4)
    spells.Envenom.Pandmic = self:ComboPandemic(1)
    spells.CrimsonTempest.Pandemic = self:ComboPandemic(2)
end

function rotation:Dispose()
    self.LocalEvents:Dispose()
    self.LocalEvents = nil
end

function rotation:Activate()
    self.Player = addon.Player
    self.CmdBus = addon.CmdBus
    self.EmptyAction = addon.Initializer.Empty.Action
    self.LocalEvents = self:CreateLocalEventTracker()
    self:SetLayout()
end

function rotation:CreateLocalEventTracker()
    local frameHandlers = {}

    local IsStealthed = IsStealthed
    function frameHandlers.UPDATE_STEALTH(event, ...)
        self.Stealhed = IsStealthed()
    end

    return addon.Initializer.NewEventTracker(frameHandlers):RegisterEvents()
end

function rotation:SetLayout()
    local spells = self.Spells
    spells.SliceAndDice.Key = "1"
    spells.Garrote.Key = "2"
    spells.SinisterStrike.Key = "3"
    spells.Mutilate.Key = spells.SinisterStrike.Key
    spells.Eviscerate.Key = "4"
    spells.Envenom.Key = spells.Eviscerate.Key
    spells.Rupture.Key = "5"
    spells.Shiv.Key = "6"
    spells.Deathmark.Key = "7"
    spells.FanOfKnives.Key = "8"
    spells.CrimsonTempest.Key = "9"

    spells.ThistleTea.Key = "n-1"
    spells.MarkedForDeath.Key = "n-2"
    spells.Ambush.Key = "n-3"
    spells.Feint.Key = "n-7"
    spells.KidneyShot.Key = "n-8"
    spells.Vanish.Key = "n-9"
    spells.AutoAttack.Key = "n-+"

    spells.CrimsonVial.Key = "F6"
    spells.Kick.Key = "F9"

    local equip = addon.Player.Equipment
    equip.Trinket13.Key = "n--"

    local items = self.Items
    items.Healthstone.Key = "F12"
end

addon:AddRotation("ROGUE", 1, rotation)
