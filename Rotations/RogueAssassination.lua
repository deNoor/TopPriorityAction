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
    Stealth = {
        Id = 1784,
        Buff1 = 1784,
        Buff2 = 115191,
    },
    Ambush = {
        Id = 8676,
    },
    Subterfuge = {
        Id = 108208,
        Buff = 115192,
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
    ImprovedGarrote = {
        Id = 381632,
        Buff = 392403,
    },
    ShroudedSuffocation = {
        Id = 385478,
    },
    CausticSpatter = {
        Id = 421975,
        Debuff = 421976,
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
        Buff = 11327,
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
        Buff = 1966,
    },
    TricksOfTheTrade = {
        Id = 57934,
    },
    ThistleTea = {
        Id = 381623,
        Buff = 381623,
    },
    ColdBlood = {
        Id = 382245,
        Buff = 382245,
    },
    EchoingReprimand = {
        Id = 385616,
        Buff2 = 323558,
        Buff3 = 323559,
        Buff4 = 323560,
    },
    Kingsbane = {
        Id = 385627,
        Debuff = 385627,
    },
    ShadowDance = {
        Id = 185313,
        Buff = 185422,
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
        Name = "feint",
    },
    Kick = {
        Name = "kick",
    },
    CombatStealth = {
        Name = "combatstealth",
    },
}

local setBonus = {
    DFAmir = {
        SetId = 1566,
    },
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
    ComboFinisher          = 5,
    ComboKidney            = 4,
    -- locals
    InStealth              = false,
    InStealthStance        = false,
    InRange                = false,
    InEncounter            = false,
    InInstance             = false,
    Energy                 = 0,
    EnergyDeficit          = 0,
    Combo                  = 0,
    ComboDeficit           = 0,
    ComboFinisherAllowed   = false,
    ComboEchoing           = false,
    ComboHolding           = false,
    NowCasting             = 0,
    CastingEndsIn          = 0,
    CCUnlockIn             = 0,
    ActionAdvanceWindow    = 0,
    MyHealthPercent        = 0,
    MyHealthPercentDeficit = 0,
    MyHealAbsorb           = 0,
    InCombatWithTarget     = false,
    CanAttackTarget        = false,
    CanAttackMouseover     = false,
    CanDotTarget           = false,
    WorthyTarget           = false,
    NanoBursting           = false,
    ShortBursting          = false,
    CombatStealthSent      = false,
    AmirSet4p              = false,
}

local UnitInVehicle = UnitInVehicle
function rotation:SelectAction()
    self:Refresh()
    local playerBuffs = self.Player.Buffs
    local targetDebuffs = self.Player.Target.Debuffs
    if (not UnitInVehicle("player")) then
        self:Utility()
    end
    if ((not self.InInstance or self.InCombatWithTarget)) then
        if (self.CanAttackTarget and self.InRange and self.InStealth) then
            self:StealthOpener()
        end
        if (self.CanAttackTarget and self.InRange) then
            self:AutoAttack()
            self:SingleTarget()
        end
    end
end

local stealthOpenerList
function rotation:StealthOpener()
    local target = self.Player.Target
    stealthOpenerList = stealthOpenerList or
        {
            function() return self:SliceAndDice() end,
            function() if (self.CanDotTarget) then return self:Rupture() end end,
            function() return self.CanDotTarget and spells.Garrote or spells.Ambush end,
            function() return self.EmptyAction end,
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
            function() return self:AwaitCombatStealth() end,
            function() if (not self.ComboHolding) then return self:UseTrinket() end end,
            function() if (not self.ComboHolding and (self.ComboFinisherAllowed or self.ComboEchoing) and player.Buffs:Remains(spells.SliceAndDice.Buff) < 6 and player.Buffs:Applied(spells.SliceAndDice.Buff)) then return spells.Envenom end end,
            function() if (not self.ComboHolding) then return self:SliceAndDice() end end,
            function() if (spells.ThistleTea.Known and spells.ThistleTea:ActiveCharges() > 2 and self.Energy < 50 and not player.Buffs:Applied(spells.ThistleTea.Buff)) then return spells.ThistleTea end end,
            function() if (spells.ThistleTea.Known and spells.Kingsbane.Known and target.Debuffs:Applied(spells.Kingsbane.Debuff) and target.Debuffs:Remains(spells.Kingsbane.Debuff) < 6) then return spells.ThistleTea end end,
            function() if (spells.Kingsbane.Known and settings.Dispel and self.InInstance and target.Debuffs:Applied(spells.Kingsbane.Debuff) and target.Debuffs:Remains(spells.Kingsbane.Debuff) < 3) then return spells.Vanish end end,
            function() if (not self.ComboHolding and self.CanDotTarget) then return self:Rupture() end end,
            function() if (settings.Burst and target.Debuffs:Remains(spells.Rupture.Debuff) > 2 and target.Debuffs:Remains(spells.Garrote.Debuff) > 2) then return spells.Deathmark end end,
            function() if (spells.Kingsbane.Known and settings.Burst and not player.Buffs:Applied(spells.Subterfuge.Buff) and not player.Buffs:Applied(spells.Vanish.Buff)) then return spells.Kingsbane end end,
            function() if (not self.ComboHolding and (self.ComboFinisherAllowed or self.ComboEchoing) and target.Debuffs:Applied(spells.Kingsbane.Debuff) and player.Buffs:Remains(spells.Envenom.Buff) < target.Debuffs:Remains(spells.Kingsbane.Debuff) and player.Buffs:Remains(spells.Envenom.Buff) < spells.Envenom.Pandemic) then return spells.Envenom end end,
            function() if (not self.ComboHolding and (self.ComboFinisherAllowed or self.ComboEchoing) and self.Settings.AOE and self.CanDotTarget and target.Debuffs:Remains(spells.CrimsonTempest.Debuff) < spells.CrimsonTempest.Pandemic) then return spells.CrimsonTempest end end,
            function() if (self.ComboFinisherAllowed or self.ComboEchoing) then return spells.Envenom end end,
            function() return spells.EchoingReprimand end,
            function() if (target.Debuffs:Applied(spells.Kingsbane.Debuff) and target.Debuffs:Remains(spells.Shiv.Debuff) < target.Debuffs:Remains(spells.Kingsbane.Debuff) and target.Debuffs:Remains(spells.Shiv.Debuff) < spells.Shiv.Pandemic) then return spells.Shiv end end,
            function() if (self.CanDotTarget and self.WorthyTarget and target.Debuffs:Remains(spells.Garrote.Debuff) < 3) then return spells.Garrote end end,
            function() if (self.CanDotTarget and self.WorthyTarget and self.ShortBursting and player.Buffs:Applied(spells.ImprovedGarrote.Buff) and target.Debuffs:Remains(spells.Garrote.Debuff) < 15) then return spells.Garrote end end,
            -- function() if (spells.CausticSpatter.Known and settings.AOE and not target.Debuffs:Applied(spells.CausticSpatter.Debuff)) then return spells.Mutilate end end,
            function() if (player.Buffs:Applied(spells.Blindside.Buff)) then return spells.Ambush end end,
            function() if (self.Settings.AOE) then return spells.FanOfKnives end end,
            function() return spells.Ambush end,
            function() return spells.Mutilate end,
        }
    return rotation:RunPriorityList(singleTargetList)
end

local utilityList
function rotation:Utility()
    local player = self.Player
    local target = self.Player.Target
    local mouseover = player.Mouseover
    local gashFrenzyId = addon.Common.Spells.GashFrenzy.Debuff
    utilityList = utilityList or
        {
            function() if (self.MyHealthPercentDeficit > 55) then return items.Healthstone end end,
            function() if (self.CmdBus:Find(cmds.Feint.Name) and not player.Buffs:Applied(spells.Feint.Buff)) then return spells.Feint end end,
            function() if (not self.ShortBursting and (self.MyHealthPercentDeficit > 35 or self.MyHealAbsorb > 0 or player.Debuffs:Applied(gashFrenzyId))) then return spells.CrimsonVial end end,
            function() if (self.CmdBus:Find(cmds.Kick.Name) and not self.InStealth and not self.CombatStealthSent and ((self.CanAttackMouseover and spells.Kick:IsInRange("mouseover") and mouseover:CanKick()) or (not self.CanAttackMouseover and self.CanAttackTarget and spells.Kick:IsInRange("target") and target:CanKick()))) then return spells.Kick end end,
            function() if (self.CmdBus:Find(cmds.Kidney.Name) and not self.InStealth and not self.CombatStealthSent and ((self.CanAttackMouseover and spells.KidneyShot:IsInRange("mouseover")) or (not self.CanAttackMouseover and self.CanAttackTarget and spells.KidneyShot:IsInRange("target")))) then return self:KidneyOnCommand() end end,
            function() if (not self.InStealth) then return self:AutoStealth() end end,
            function() if (self.InEncounter and player.Buffs:Remains(items.RaidRune.Buff) < 60 * 5) then return items.RaidRune end end,
        }
    return rotation:RunPriorityList(utilityList)
end

local autoAttackList
function rotation:AutoAttack()
    autoAttackList = autoAttackList or
        {
            function() if (self.GcdReadyIn > self.ActionAdvanceWindow and not spells.AutoAttack:IsQueued()) then return spells.AutoAttack end end,
        }
    return rotation:RunPriorityList(autoAttackList)
end

---@return Spell?
function rotation:AutoStealth()
    if (self.InEncounter) then
        return spells.Stealth
    end
end

function rotation:ExpectCombatStealth()
    self.CmdBus:Add(self.Cmds.CombatStealth.Name, 0.4)
end

function rotation:AwaitedVanish()
    local necroticPitch = addon.Common.Spells.NecroticPitch
    if (self.Player.Debuffs:Applied(necroticPitch.Debuff)) then
        return nil
    end
    if (self.Energy > 80 and self.GcdReadyIn < 0.05) then
        return spells.Vanish
    else
        return self.EmptyAction
    end
end

function rotation:AwaitedShadowDance()
    if (self.Energy > 80 and self.GcdReadyIn < 0.05) then
        return spells.ShadowDance
    else
        return self.EmptyAction
    end
end

function rotation:AwaitCombatStealth()
    if (self.CombatStealthSent and not self.InStealthStance) then return self.EmptyAction end
end

function rotation:SliceAndDice()
    if (self.Combo > 0 and self.Player.Buffs:Remains(spells.SliceAndDice.Buff) < 2) then
        return spells.SliceAndDice
    end
    return nil
end

function rotation:Rupture()
    local player = self.Player
    local target = self.Player.Target
    if ((self.ComboFinisherAllowed or self.ComboEchoing) and target.Debuffs:Remains(spells.Rupture.Debuff) < 4) then
        return spells.Rupture
    end
    return nil
end

function rotation:DelayedEnvenom()
    local player = self.Player
    local target = self.Player.Target
    if (target.Debuffs:Applied(spells.Shiv.Debuff)) then
        return spells.Envenom
    end
    if (player.Buffs:Remains(spells.Envenom.Buff) < spells.Envenom.Pandmic or self.Energy > 100) then
        return spells.Envenom
    else
        return self.EmptyAction
    end
end

local aoeTrinkets = addon.Helper.ToHashSet({
    198451, -- 10y healing/damage aoe
})
local burstTrinkets = addon.Helper.ToHashSet({
    133642, -- +stats
})

---@return EquipItem?
function rotation:UseTrinket()
    local equip = self.Player.Equipment
    ---@param ids integer[]
    ---@return EquipItem
    local trinketFrom = function(ids)
        return (ids[equip.Trinket13.Id] and equip.Trinket13) or (ids[equip.Trinket14.Id] and equip.Trinket14)
    end
    local aoeTrinket = trinketFrom(aoeTrinkets)
    if (aoeTrinket and self.Settings.AOE) then
        return aoeTrinket
    end
    local burstTrinket = trinketFrom(burstTrinkets)
    if (burstTrinket and self.Settings.Burst) then
        return burstTrinket
    end
    return nil
end

function rotation:KidneyOnCommand()
    local readyIn = spells.KidneyShot:ReadyIn()
    if (readyIn < 2) then
        if (self.Combo < self.ComboKidney) then
            self.ComboHolding = true
            self.ComboFinisherAllowed = false
            return nil
        end
        return (readyIn > self.ActionAdvanceWindow) and self.EmptyAction or spells.KidneyShot
    end
end

---@param perComboDuration number
---@param baseDuration number?
---@return number
function rotation:ComboPandemic(perComboDuration, baseDuration)
    baseDuration = baseDuration or perComboDuration
    return (baseDuration + perComboDuration * self.Combo) * 0.3
end

local max, min = max, min
---@return boolean
function rotation:FinisherAllowed()
    local comboMax = self.Combo + self.ComboDeficit
    local comboFinisher = max(4, min(self.ComboFinisher, comboMax - 1))
    return self.Combo >= comboFinisher
end

local echoBuffs = {
    [2] = spells.EchoingReprimand.Buff2,
    [3] = spells.EchoingReprimand.Buff3,
    [4] = spells.EchoingReprimand.Buff4,
}
---@return boolean
function rotation:ComboEcho()
    if (not spells.EchoingReprimand.Known) then
        return false
    end
    local combo = self.Combo
    if (2 <= combo and combo <= 4) then
        local buffId = echoBuffs[combo] or addon.Helper.Print("EchoingReprimand buff id is missing for", combo)
        return self.Player.Buffs:Applied(buffId)
    end
    return false
end

local max, min = max, min
function rotation:Predictions()
    if (spells.ShadowDance:IsQueued()) then
        self:ExpectCombatStealth()
    end
    if (spells.Vanish:IsQueued()) then
        self:ExpectCombatStealth()
    end
end

function rotation:ShortBurstEffects()
    local player = self.Player
    return player.Buffs:Applied(spells.ShadowDance.Buff) or player.Buffs:Applied(spells.Subterfuge.Buff)
end

function rotation:NanoBurstEffects()
    local player = self.Player
    return player.Buffs:Applied(spells.Vanish.Buff)
end

local GetShapeshiftForm = GetShapeshiftForm
function rotation:StealthStance()
    local stance = GetShapeshiftForm(true)
    return (stance and (stance == 1 or stance == 2))
end

local tricksMacro = addon.Convenience:CreateTricksMacro("TricksNamed", spells.TricksOfTheTrade)

local IsStealthed, C_ChallengeMode, IsEncounterInProgress = IsStealthed, C_ChallengeMode, IsEncounterInProgress
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
    self.ComboHolding = false
    self.MyHealthPercent, self.MyHealthPercentDeficit = player:HealthPercent()
    self.MyHealAbsorb = player:HealAbsorb()
    self.NowCasting, self.CastingEndsIn = player:NowCasting()
    self.ActionAdvanceWindow = self.Settings.ActionAdvanceWindow
    self.InInstance = player:InInstance()
    self.InCombatWithTarget = player.Target:InCombatWithMe()
    self.CanAttackTarget, self.CanAttackMouseover = player.Target:CanAttack(), player.Mouseover:CanAttack()
    self.CanDotTarget = player.Target:CanDot()
    self.WorthyTarget = player.Target:IsWorthy()
    self.InStealth = IsStealthed()
    self.InStealthStance = self:StealthStance()
    self:Predictions()
    self.NanoBursting = rotation:NanoBurstEffects()
    self.ShortBursting = self.NanoBursting or self:ShortBurstEffects()
    self.ComboFinisherAllowed = self:FinisherAllowed()
    self.ComboEchoing = self:ComboEcho()
    spells.SliceAndDice.Pandemic = self:ComboPandemic(6)
    spells.Rupture.Pandemic = self:ComboPandemic(4)
    spells.CrimsonTempest.Pandemic = self:ComboPandemic(2, 4)
    spells.Envenom.Pandemic = self:ComboPandemic(1, 0)
    self.CombatStealthSent = self.CmdBus:Find(cmds.CombatStealth.Name) ~= nil
    self.AmirSet4p = player.Equipment:ActiveSetBonus(setBonus.DFAmir.SetId, 4)
    self.InEncounter = C_ChallengeMode.IsChallengeModeActive() or IsEncounterInProgress() or false
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
    tricksMacro:Update()
    self:SetLayout()
end

function rotation:CreateLocalEventTracker()
    local frameHandlers = {}

    local IsStealthed = IsStealthed
    function frameHandlers.UPDATE_STEALTH(event, ...)
        self.Stealthed = IsStealthed()
    end

    function frameHandlers.UPDATE_SHAPESHIFT_FORM(event, ...)
        self.InStealthStance = self:StealthStance()
    end

    local spellIdHandlers = {
        [spells.Vanish.Id] = function()
            self:ExpectCombatStealth()
        end,
        [spells.ShadowDance.Id] = function()
            self:ExpectCombatStealth()
        end,
        [spells.Stealth.Id] = function()
            self:ExpectCombatStealth()
        end,
    }
    function frameHandlers.UNIT_SPELLCAST_SENT(event, unit, target, castGUID, spellID)
        if (unit == "player") then
            local spellHandler = spellIdHandlers[spellID]
            if (spellHandler) then
                spellHandler()
            end
        end
    end

    function frameHandlers.GROUP_ROSTER_UPDATE(event, ...)
        tricksMacro:Update()
    end

    function frameHandlers.PLAYER_ENTERING_WORLD(event, ...)
        tricksMacro:Update()
    end

    function frameHandlers.CHALLENGE_MODE_START(event, ...)
        tricksMacro:Update()
    end

    function frameHandlers.PLAYER_REGEN_ENABLED(event, ...)
        if (tricksMacro.PendingUpdate) then
            tricksMacro:Update()
        end
    end

    return addon.Initializer.NewEventTracker(frameHandlers):RegisterEvents()
end

function rotation:SetLayout()
    local spells = self.Spells
    spells.SliceAndDice.Key = "1"
    spells.Garrote.Key = "2"
    spells.SinisterStrike.Key = "3"
    spells.Mutilate.Key = spells.SinisterStrike.Key
    spells.Ambush.Key = spells.Mutilate.Key
    spells.Eviscerate.Key = "4"
    spells.Envenom.Key = spells.Eviscerate.Key
    spells.Rupture.Key = "5"
    spells.Shiv.Key = "6"
    spells.Deathmark.Key = "7"
    spells.FanOfKnives.Key = "8"
    spells.CrimsonTempest.Key = "9"
    spells.CrimsonVial.Key = "0"
    spells.Feint.Key = "-"

    spells.ShadowDance.Key = "num1"
    spells.Kingsbane.Key = spells.ShadowDance.Key
    spells.EchoingReprimand.Key = spells.ShadowDance.Key
    spells.Vanish.Key = "num2"
    spells.Stealth.Key = "num3"
    spells.Kick.Key = "num4"
    spells.KidneyShot.Key = "num5"
    spells.ThistleTea.Key = "num6"

    spells.AutoAttack.Key = "num+"

    local equip = addon.Player.Equipment
    equip.Trinket14.Key = "num0"
    equip.Trinket13.Key = "num-"

    local items = self.Items
    items.RaidRune.Key = "num8"
    items.Healthstone.Key = "num9"
end

function test()
    return rotation.Player.Target
end

addon:AddRotation("ROGUE", 1, rotation)
