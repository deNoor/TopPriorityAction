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
    PistolShot = {
        Id = 185763,
        Opportunity = 195627,
    },
    Ambush = {
        Id = 8676,
        Audacity = 386270,
    },
    Eviscerate = {
        Id = 196819,
    },
    Dispatch = {
        Id = 2098,
    },
    SummarilyDispatched = {
        Id = 381990,
        Buff = 386868,
    },
    SliceAndDice = {
        Id = 315496,
        Buff = 315496,
        Pandemic = 18 * 0.3
    },
    RollTheBones = {
        Id = 315508,
        Pandemic = 30 * 0.3,
        TrueBearing = 193359,
        SkullAndCrossbones = 199603,
        Broadside = 193356,
        RuthlessPrecision = 193357,
        BuriedTreasure = 199600,
        GrandMelee = 193358,
    },
    KeepItRolling = {
        Id = 381989,
    },
    Shiv = {
        Id = 5938,
    },
    AdrenalineRush = {
        Id = 13750,
        Buff = 13750,
        LoadedDice = 256171,
    },
    Stealth = {
        Id = 1784,
    },
    StealthSubterfuge = {
        Id = 115191,
    },
    Vanish = {
        Id = 1856,
        Buff = 11327,
    },
    BladeFlurry = {
        Id = 13877,
        Buff = 13877,
    },
    KillingSpree = {
        Id = 51690,
    },
    Dreadblades = {
        Id = 343142,
        Debuff = 343142,
    },
    BladeRush = {
        Id = 271877,
    },
    Sepsis = {
        Id = 385408,
    },
    GhostlyStrike = {
        Id = 196937,
        Debuff = 196937,
    },
    BetweenTheEyes = {
        Id = 315341,
        Debuff = 315341,
    },
    ImprovedBetweenTheEyes = {
        Id = 235484,
    },
    GreenskinsWickers = {
        Id = 386823,
        Buff = 394131,
    },
    FanTheHammer = {
        Id = 381846,
    },
    TakeThemBySurprise = {
        Id = 382742,
        Buff = 385907,
    },
    SwiftSlasher = {
        Id = 381988,
    },
    ImprovedAdrenalineRush = {
        Id = 395422,
    },
    Subterfuge = {
        Id = 108208,
        Buff = 115192,
    },
    SealFate = {
        Id = 14190,
    },
    ImprovedAmbush = {
        Id = 381620,
    },
    QuickDraw = {
        Id = 196938,
    },
    CrimsonVial = {
        Id = 185311,
    },
    Feint = {
        Id = 1966,
    },
    TricksOfTheTrade = {
        Id = 57934,
    },
    MarkedForDeath = {
        Id = 137619,
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
    ShadowDance = {
        Id = 185313,
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
    Vanish = {
        Name = "vanish",
    },
    ShadowDance = {
        Name = "shadowdance",
    },
    Stealth = {
        Name = "stealth",
    },
    PistolShot = {
        Name = "pistolshot",
    },
}

local setBonuses = {
    DFVault = {
        ItemsId = 1535,
        Buff2Id = 394879,
        Buff4Id = 394888,
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
    ComboFinisher          = 6,
    ComboKidney            = 4,
    -- locals
    Stealthed              = IsStealthed(), -- UPDATE_STEALTH, IsStealthed()
    InRange                = false,
    Energy                 = 0,
    EnergyDeficit          = 0,
    Combo                  = 0,
    ComboDeficit           = 0,
    FanTheHammerTicks      = 0,
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
    InInstance             = false,
    InCombatWithTarget     = false,
    CanAttackTarget        = false,
    CanAttackMouseover     = false,
    CanDotTarget           = false,
    WorthyTarget           = false,
    NanoBursting           = false,
    ShortBursting          = false,
    CombatStealthSent      = false,
}

function rotation:SelectAction()
    self:Refresh()
    local playerBuffs = self.Player.Buffs
    local targetDebuffs = self.Player.Target.Debuffs
    self:Utility()
    if ((not self.InInstance or self.InCombatWithTarget)) then
        if (self.CanAttackTarget and self.InRange and (self.Stealthed or self.CombatStealthSent)) then
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
    local settings = self.Settings
    local player = self.Player
    local target = self.Player.Target
    stealthOpenerList = stealthOpenerList or
        {
            function() if (settings.Burst and (not spells.ImprovedAdrenalineRush.Known or self.Combo < 3) and not self:KillingSpreeSoon()) then return spells.AdrenalineRush end end,
            function() if (spells.RollTheBones.Known) then return self:RollTheBones() end end,
            function() if (spells.KeepItRolling.Known and settings.Burst) then return self:KeepItRolling() end end,
            function() if (spells.MarkedForDeath.Known and self.Combo < 3 and not target:IsTotem() and not self.ShortBursting) then return spells.MarkedForDeath end end,
            function() return self:SliceAndDice() end,
            -- function() if (spells.ColdBlood.Known) then return spells.ColdBlood end end,
            function() return spells.Ambush end,
            function() return self.EmptyAction end,
        }
    return rotation:RunPriorityList(stealthOpenerList)
end

local singleTargetList
function rotation:SingleTarget()
    local settings = self.Settings
    local player = self.Player
    local target = self.Player.Target
    local mouseover = player.Mouseover
    local equip = player.Equipment
    singleTargetList = singleTargetList or
        {
            -- function() if (self.CmdBus:Find(cmds.Kick.Name) and target:CanKick() and not mouseover:Exists()) then return spells.Kick end end,
            -- function() if (self.CmdBus:Find(cmds.Kidney.Name)) then return self:KidneyOnCommand() end end,
            -- function() if (spells.ColdBlood.Known) then return spells.ColdBlood end end,
            function() if (spells.KeepItRolling.Known and settings.Burst) then return self:KeepItRolling() end end,
            function() if (settings.AOE and not self.ComboHolding and not player.Buffs:Applied(spells.BladeFlurry.Buff)) then return spells.BladeFlurry end end,
            function() if (not self.ComboHolding) then return self:UseTrinket() end end,
            function() if (spells.BladeRush.Known and settings.AOE and player.Buffs:Applied(spells.BladeFlurry.Buff) and (not self.ShortBursting or self.Energy < 50)) then return spells.BladeRush end end,
            function() if (spells.KillingSpree.Known and settings.Burst and not self.ComboFinisherAllowed and not self.ComboHolding and not self.ShortBursting and (not player.Buffs:Applied(spells.AdrenalineRush.Buff) or self.Energy < 50)) then return spells.KillingSpree end end,
            function() if (spells.RollTheBones.Known and not self.ComboHolding) then return self:RollTheBones() end end,
            function() if (not self.ComboHolding) then return self:SliceAndDice() end end,
            function() if (spells.ThistleTea.Known and settings.Burst and self.Energy < 50 and not player.Buffs:Applied(spells.ThistleTea.Buff) and not self.ComboHolding) then return spells.ThistleTea end end,
            function() if (target.Buffs:HasPurgeable() and not self.ShortBursting) then return spells.Shiv end end,
            function() if ((self.ComboFinisherAllowed or self.ComboEchoing) and (spells.GreenskinsWickers.Known or spells.ImprovedBetweenTheEyes.Known or (self.WorthyTarget and target.Debuffs:Remains(spells.BetweenTheEyes.Debuff) < 3))) then return spells.BetweenTheEyes end end,
            function() if (self.ComboFinisherAllowed or self.ComboEchoing) then return spells.Dispatch end end,
            function() if (spells.MarkedForDeath.Known and self.Combo < 3 and not target:IsTotem() and not self.ShortBursting) then return spells.MarkedForDeath end end,
            function() if (settings.Burst and not self.ComboHolding and (not spells.ImprovedAdrenalineRush.Known or self.Combo < 3) and not self:KillingSpreeSoon()) then return spells.AdrenalineRush end end,
            function() if (spells.Dreadblades.Known and settings.Burst and not self.ShortBursting and not self.ComboHolding and self.Combo < 3 and not self:KillingSpreeSoon()) then return spells.Dreadblades end end,
            function() return spells.Ambush end,
            function() if (spells.GhostlyStrike.Known and self.WorthyTarget and not target.Debuffs:Applied(spells.GhostlyStrike.Debuff)) then return spells.GhostlyStrike end end,
            function() if (spells.Sepsis.Known and settings.Burst and not self.ShortBursting) then return spells.Sepsis end end,
            function() if (spells.BladeRush.Known and not settings.AOE and self.Energy < 80 and not player.Buffs:Applied(spells.PistolShot.Opportunity)) then return spells.BladeRush end end,
            function() if (spells.EchoingReprimand.Known and settings.Burst) then return spells.EchoingReprimand end end,
            function() if (settings.Burst and settings.Dispel and not self.ShortBursting and self.InInstance and not self.ComboHolding and spells.Vanish:ReadyIn() <= self.GcdReadyIn) then return self:AwaitedVanishAmbush() end end,
            function() if (spells.ShadowDance.Known and settings.Burst and not self.ShortBursting and not self.ComboHolding and spells.ShadowDance:ReadyIn() <= self.GcdReadyIn and not self:KillingSpreeSoon() and player.Buffs:Applied(spells.SliceAndDice.Buff)) then return self:AwaitedShadowDance() end end,
            function() return self:PistolShot() end,
            function() return spells.SinisterStrike end,
        }
    return rotation:RunPriorityList(singleTargetList)
end

local utilityList
function rotation:Utility()
    local player = self.Player
    local target = self.Player.Target
    local mouseover = player.Mouseover
    local grievousWoundId = addon.Common.Spells.GrievousWound.Debuff
    utilityList = utilityList or
        {
            function() if (self.MyHealthPercentDeficit > 55) then return items.Healthstone end end,
            function() if (self.CmdBus:Find(cmds.Feint.Name)) then return spells.Feint end end,
            function() if (not self.ShortBursting and (self.MyHealthPercentDeficit > 35 or self.MyHealAbsorb > 0 or player.Debuffs:Applied(grievousWoundId))) then return spells.CrimsonVial end end,
            function() if (self.CmdBus:Find(cmds.Kick.Name) and not self.Stealthed and not self.CombatStealthSent and ((self.CanAttackMouseover and spells.Kick:IsInRange("mouseover") and mouseover:CanKick()) or (not self.CanAttackMouseover and self.CanAttackTarget and spells.Kick:IsInRange("target") and target:CanKick()))) then return spells.Kick end end,
            function() if (self.CmdBus:Find(cmds.Kidney.Name) and not self.Stealthed and not self.CombatStealthSent and ((self.CanAttackMouseover and spells.KidneyShot:IsInRange("mouseover")) or (not self.CanAttackMouseover and self.CanAttackTarget and spells.KidneyShot:IsInRange("target")))) then return self:KidneyOnCommand() end end,
            function() if (not self.Stealthed) then return self:AutoStealth() end end,
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

local C_ChallengeMode = C_ChallengeMode
---@return Spell?
function rotation:AutoStealth()
    if (self.InInstance and C_ChallengeMode.IsChallengeModeActive()) then
        return spells.Stealth
    end
end

function rotation:ExpectVanish()
    self.CmdBus:Add(self.Cmds.Vanish.Name, 0.4)
end

function rotation:ExpectDance()
    self.CmdBus:Add(self.Cmds.ShadowDance.Name, 0.4)
end

function rotation:ExpectStealth()
    self.CmdBus:Add(self.Cmds.Stealth.Name, 0.4)
end

function rotation:AwaitedVanishAmbush()
    local necroticPitch = addon.Common.Spells.NecroticPitch
    if (self.Player.Debuffs:Applied(necroticPitch.Debuff)) then
        return nil
    end
    if (self.Energy > 80 and self.GcdReadyIn < self.ActionAdvanceWindow + 0.2) then
        self:ExpectVanish()
        return spells.Vanish
    else
        return self.EmptyAction
    end
end

function rotation:AwaitedShadowDance()
    if (self.Energy > 80 and self.GcdReadyIn < self.ActionAdvanceWindow + 0.2) then
        self:ExpectDance()
        return spells.ShadowDance
    else
        return self.EmptyAction
    end
end

function rotation:SliceAndDice()
    if (self.Player.Buffs:Applied(spells.RollTheBones.GrandMelee)) then
        return nil
    end
    if (spells.SwiftSlasher.Known) then
        if (self.Player.Buffs:Remains(spells.SliceAndDice.Buff) < spells.SliceAndDice.Pandemic) then
            if (spells.RollTheBones.Known and self.ComboDeficit > 0) then
                self.ComboFinisherAllowed = false
                return nil
            else
                return spells.SliceAndDice
            end
        end
        return nil
    end
    if (self.ComboFinisherAllowed and self.Player.Buffs:Remains(spells.SliceAndDice.Buff) < spells.SliceAndDice.Pandemic) then
        return spells.SliceAndDice
    end
    return nil
end

function rotation:PistolShot()
    if (spells.FanTheHammer.Known) then
        local stacks = self.Player.Buffs:Stacks(spells.PistolShot.Opportunity) - self.FanTheHammerTicks
        if (stacks > 0) then
            return spells.PistolShot
        end
        return nil
    end
    if (self.Player.Buffs:Applied(spells.PistolShot.Opportunity)) then
        return spells.PistolShot
    end
    return nil
end

function rotation:KillingSpreeSoon()
    return spells.KillingSpree.Known and spells.KillingSpree:ReadyIn() <= self.GcdReadyIn
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

local dice = {
    Broadside = false,          -- 1 combo gen
    SkullAndCrossbones = false, -- 25% Double SS
    TrueBearing = false,        -- CDR
    RuthlessPrecision = false,  -- crit
    BuriedTreasure = false,     -- energy regen
    GrandMelee = false,         -- SnD application and leech
}
---@return Spell?
function rotation:RollTheBones()
    if (self.NanoBursting) then
        return nil
    end

    if (spells.SwiftSlasher.Known and not self.Player.Buffs:Applied(spells.SliceAndDice.Buff)) then
        return nil
    end

    local rtb = spells.RollTheBones
    local buffs = self.Player.Buffs
    local inPandemic = false
    local count = 0
    for name, _ in pairs(dice) do
        local id = rtb[name] or addon.Helper.Print("RollTheBones buff id is missing for", name)
        local aura = buffs:Find(id)
        if (aura and aura.FullDuration > 20 and aura.Remains > self.ActionAdvanceWindow) then
            dice[name] = true
            count = count + 1
            inPandemic = inPandemic or aura.Remains < rtb.Pandemic
        else
            dice[name] = false
        end
    end

    local reroll = function()
        if (count > 2) then
            return false
        elseif (dice.Broadside or dice.SkullAndCrossbones) then
            return false
        elseif (count > 1 and not (dice.GrandMelee and dice.BuriedTreasure)) then
            return false
        else
            return true
        end
    end

    if (reroll()) then
        return rtb
    end
end

local diceToKeep = {
    Broadside = true,
    SkullAndCrossbones = true,
    TrueBearing = true,
    RuthlessPrecision = true,
    BuriedTreasure = true,
    GrandMelee = false,
}
---@return Spell?
function rotation:KeepItRolling()
    local rtb = spells.RollTheBones
    local buffs = self.Player.Buffs
    local count = 0
    for name, _ in pairs(diceToKeep) do
        local id = rtb[name] or addon.Helper.Print("RollTheBones buff id is missing for", name)
        local aura = buffs:Find(id)
        if (aura and aura.Remains > 0.5) then
            count = count + 1
        end
    end
    if (count > 2) then
        return spells.KeepItRolling
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

---@param initialDuration number
---@return number
function rotation:ComboPandemic(initialDuration)
    return initialDuration * (1 + self.Combo) * 0.3
end

local max, min = max, min
---@return boolean
function rotation:FinisherAllowed()
    local comboMax = self.Combo + self.ComboDeficit
    local comboFinisher = max(5, min(self.ComboFinisher, comboMax - 1))
    if (spells.SummarilyDispatched.Known) then
        comboFinisher = max(5, comboFinisher)
    elseif (spells.GreenskinsWickers.Known and spells.BetweenTheEyes:ReadyIn() <= self.GcdReadyIn) then
        comboFinisher = max(5, comboFinisher)
    end
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

function rotation:Predictions()
    if (spells.ShadowDance:IsQueued()) then
        self:ExpectDance()
    end
    if (spells.ShadowDance:IsQueued()) then
        self:ExpectVanish()
    end
    if (spells.FanTheHammer.Known and self.CmdBus:Find(self.Cmds.PistolShot.Name)) then
        local maxCombo = self.Combo + self.ComboDeficit
        self.Combo = self.Combo + (self.FanTheHammerTicks * (self.Player.Buffs:Applied(spells.RollTheBones.Broadside) and 1 or 2))
        self.ComboDeficit = maxCombo - self.Combo
    end
end

function rotation:ShortBurstEffects()
    local player = self.Player
    return player.Buffs:Applied(spells.ShadowDance.Buff) or player.Debuffs:Applied(spells.Dreadblades.Debuff)
end

function rotation:NanoBurstEffects()
    local player = self.Player
    return player.Buffs:Applied(spells.Subterfuge.Buff) or player.Buffs:Applied(spells.Vanish.Buff)
end

local tricksMacro = addon.Convenience:CreateTricksMacro("TricksNamed", spells.TricksOfTheTrade)

local IsStealthed = IsStealthed
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
    self.InInstance = player:InInstance()
    self.InCombatWithTarget = player.Target:InCombatWithMe()
    self.CanAttackTarget, self.CanAttackMouseover = player.Target:CanAttack(), player.Mouseover:CanAttack()
    self.CanDotTarget = player.Target:CanDot()
    self.WorthyTarget = player.Target:IsWorthy()
    self.Stealthed = IsStealthed()
    self:Predictions()
    self.NanoBursting = rotation:NanoBurstEffects()
    self.ShortBursting = self.NanoBursting or self:ShortBurstEffects()
    self.ComboFinisherAllowed = self:FinisherAllowed()
    self.ComboEchoing = self:ComboEcho()

    spells.SliceAndDice.Pandemic = self:ComboPandemic(6)

    self.CombatStealthSent = (self.CmdBus:Find(cmds.Vanish.Name) or self.CmdBus:Find(cmds.ShadowDance.Name)) ~= nil
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

    local spellIdHandlers = {
        [spells.Vanish.Id] = function()
            self:ExpectVanish()
        end,
        [spells.ShadowDance.Id] = function()
            self:ExpectDance()
        end,
        [spells.Stealth.Id] = function()
            self:ExpectStealth()
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

    local min = min
    local spellIdHandlers = {
        [spells.Vanish.Id] = function()
            self:ExpectVanish()
        end,
        [spells.ShadowDance.Id] = function()
            self:ExpectDance()
        end,
        [spells.Ambush.Id] = function()
            self.CmdBus:Remove(self.Cmds.Vanish.Name)
            self.CmdBus:Remove(self.Cmds.ShadowDance.Name)
            self.CmdBus:Remove(self.Cmds.Stealth.Name)
        end,
        [spells.PistolShot.Id] = function()
            if (spells.FanTheHammer.Known) then
                if (not self.CmdBus:Find(self.Cmds.PistolShot.Name)) then
                    self.CmdBus:Add(self.Cmds.PistolShot.Name, 0.4)
                    self.FanTheHammerTicks = min(self.Player.Buffs:Stacks(spells.PistolShot.Opportunity), 2)
                elseif (self.FanTheHammerTicks > 0) then
                    self.FanTheHammerTicks = self.FanTheHammerTicks - 1
                end
            end
        end,
    }
    function frameHandlers.UNIT_SPELLCAST_SUCCEEDED(event, target, castGUID, spellID)
        local spellHandler = spellIdHandlers[spellID]
        if (spellHandler) then
            spellHandler()
        end
    end

    function frameHandlers.GROUP_ROSTER_UPDATE(event, ...)
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
    spells.PistolShot.Key = "2"
    spells.SinisterStrike.Key = "3"
    spells.Eviscerate.Key = "4"
    spells.Dispatch.Key = spells.Eviscerate.Key
    spells.BetweenTheEyes.Key = "5"
    spells.RollTheBones.Key = "6"
    spells.AdrenalineRush.Key = "7"
    spells.BladeFlurry.Key = "8"
    spells.Feint.Key = "0"

    spells.Stealth.Key = "F5"
    spells.Kick.Key = "F7"
    spells.CrimsonVial.Key = "F11"
    spells.AutoAttack.Key = "F12"

    spells.ThistleTea.Key = "n-1"
    spells.ShadowDance.Key = spells.ThistleTea.Key
    spells.EchoingReprimand.Key = spells.ThistleTea.Key
    spells.MarkedForDeath.Key = "n-2"
    spells.Ambush.Key = "n-3"
    spells.KillingSpree.Key = "n-4"
    spells.Dreadblades.Key = spells.KillingSpree.Key
    spells.BladeRush.Key = "n-5"
    spells.Sepsis.Key = spells.BladeRush.Key
    spells.KeepItRolling.Key = spells.BladeRush.Key
    spells.GhostlyStrike.Key = spells.BladeRush.Key
    spells.Shiv.Key = "n-6"
    spells.ColdBlood.Key = "n-7"
    spells.KidneyShot.Key = "n-8"
    spells.Vanish.Key = "n-9"

    local equip = addon.Player.Equipment
    equip.Trinket14.Key = "n-0"
    equip.Trinket13.Key = "n--"

    local items = self.Items
    items.Healthstone.Key = "n-+"
end

addon:AddRotation("ROGUE", 2, rotation)
