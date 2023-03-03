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
    Shiv = {
        Id = 5938,
    },
    AdrenalineRush = {
        Id = 13750,
        Buff = 13750,
        LoadedDice = 256171,
    },
    Vanish = {
        Id = 1856,
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
        Name = "feint"
    },
    Kick = {
        Name = "kick",
    }
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
    TinyTarget             = false,
    ShortBursting          = false,
    SetBonus2              = false,
}

function rotation:SelectAction()
    self:Refresh()
    local playerBuffs = self.Player.Buffs
    local targetDebuffs = self.Player.Target.Debuffs
    self:Utility()
    if ((not self.InInstance or self.InCombatWithTarget)) then
        if (self.CanAttackTarget and self.InRange and self.Stealhed) then
            self:StealthOpener()
        end
        if (self.Player.Mouseover:Exists() and self.RangeChecker:IsInRange("mouseover")) then
            self:MouseoverCmd()
        end
        if (self.CanAttackTarget and self.InRange) then
            self:AutoAttack()
            self:SingleTarget()
        end
    end
end

local stealthOpenerList
function rotation:StealthOpener()
    local player = self.Player
    local target = self.Player.Target
    stealthOpenerList = stealthOpenerList or
        {
            function() return self:RollTheBones() end,
            function() if (spells.MarkedForDeath.Known and self.ComboDeficit > 3 and not target:IsTotem() and not self.ShortBursting) then return spells.MarkedForDeath end end,
            function() return self:SliceAndDice() end,
            function() return spells.Ambush end,
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
            function() if (self.CmdBus:Find(cmds.Kick.Name) and target:CanKick() and not mouseover:Exists()) then return spells.Kick end end,
            function() if (self.CmdBus:Find(cmds.Kidney.Name)) then return self:KidneyOnCommand() end end,
            function() if (settings.AOE and not self.ComboHolding and not player.Buffs:Applied(spells.BladeFlurry.Buff)) then return spells.BladeFlurry end end,
            function() if (not self.ComboHolding) then return self:UseTrinket() end end,
            function() if (spells.KillingSpree.Known and settings.Burst and not self.ComboFinisherAllowed and not self.ComboHolding and not self.ShortBursting and not player.Buffs:Applied(spells.AdrenalineRush.Buff)) then return spells.KillingSpree end end,
            function() if (spells.RollTheBones.Known and not self.ComboHolding and not self.ShortBursting) then return self:RollTheBones() end end,
            function() if (not self.ComboHolding and not self.ShortBursting) then return self:SliceAndDice() end end,
            function() if (spells.ThistleTea.Known and self.Energy < 50 and not player.Buffs:Applied(spells.ThistleTea.Buff) and not self.ComboHolding) then return spells.ThistleTea end end,
            function() if (target.Buffs:HasPurgeable() and not self.ShortBursting) then return spells.Shiv end end,
            function() if (spells.BladeRush.Known and settings.AOE and player.Buffs:Applied(spells.BladeFlurry.Buff) and (not self.ShortBursting or self.Energy < 50)) then return spells.BladeRush end end,
            function() if (spells.BladeRush.Known and not settings.AOE and (self.EnergyDeficit > 50 and not self.ShortBursting or self.Energy < 50)) then return spells.BladeRush end end,
            function() if (spells.ColdBlood.Known and spells.ImprovedBetweenTheEyes.Known and self.ComboFinisherAllowed) then return self:ColdBlood() end end,
            function() if (self.ComboFinisherAllowed and (spells.GreenskinsWickers.Known or spells.ImprovedBetweenTheEyes.Known or target.Debuffs:Remains(spells.BetweenTheEyes.Debuff) < 3)) then return spells.BetweenTheEyes end end,
            function() if (spells.ColdBlood.Known and spells.SummarilyDispatched.Known and self.ComboFinisherAllowed) then return self:ColdBlood() end end,
            function() if (self.ComboFinisherAllowed) then return spells.Dispatch end end,
            function() if (spells.MarkedForDeath.Known and self.ComboDeficit > 3 and not target:IsTotem() and not self.ShortBursting) then return spells.MarkedForDeath end end,
            function() if (settings.Burst and not self.ComboHolding and (not spells.ImprovedAdrenalineRush.Known or self.ComboDeficit > 3) and not self:KillingSpreeSoon()) then return spells.AdrenalineRush end end,
            function() if (spells.Dreadblades.Known and settings.Burst and not self.ComboHolding and self.ComboDeficit > 3 and not self:KillingSpreeSoon()) then return spells.Dreadblades end end,
            function() if (spells.ColdBlood.Known and not spells.GreenskinsWickers.Known) then return self:ColdBlood() end end,
            function() return spells.Ambush end,
            function() if (spells.GhostlyStrike.Known and not target.Debuffs:Applied(spells.GhostlyStrike.Debuff)) then return spells.GhostlyStrike end end,
            function() if (settings.Burst and not self.ShortBursting and not self.ComboHolding and self.InInstance and spells.Vanish:ReadyIn() <= self.GcdReadyIn and (not spells.TakeThemBySurprise.Known or not player.Buffs:Applied(spells.TakeThemBySurprise.Buff))) then return self:AwaitedVanishAmbush() end end,
            function() if (spells.Sepsis.Known and settings.Burst and not self.ShortBursting) then return spells.Sepsis end end,
            function() if (spells.ColdBlood.Known) then return self:ColdBlood() end end,
            function() return self:PistolShot() end,
            function() if (spells.BladeRush.Known and (not settings.AOE or player.Buffs:Applied(spells.BladeFlurry.Buff))) then return spells.BladeRush end end,
            function() if (spells.ShadowDance.Known and settings.Burst and spells.ShadowDance:ReadyIn() <= self.GcdReadyIn and not self:KillingSpreeSoon() and player.Buffs:Applied(spells.SliceAndDice.Buff)) then return self:AwaitedShadowDance() end end,
            function() return spells.SinisterStrike end,
        }
    return rotation:RunPriorityList(singleTargetList)
end

local utilityList
function rotation:Utility()
    local player = self.Player
    local grievousWoundId = addon.Common.Spells.GrievousWound.Debuff
    utilityList = utilityList or
        {
            function() if (self.CmdBus:Find(cmds.Feint.Name)) then return spells.Feint end end,
            function() if (not self.ShortBursting and (self.MyHealthPercentDeficit > 35 or self.MyHealAbsorb > 0 or player.Debuffs:Applied(grievousWoundId))) then return spells.CrimsonVial end end,
            function() if (self.MyHealthPercentDeficit > 55) then return items.Healthstone end end,
        }
    return rotation:RunPriorityList(utilityList)
end

local mouseoverList
function rotation:MouseoverCmd()
    local mouseover = self.Player.Mouseover
    mouseoverList = mouseoverList or
        {
            function() if (self.CmdBus:Find(cmds.Kick.Name) and mouseover:CanKick()) then return spells.Kick end end,
            function() if (self.CmdBus:Find(cmds.Kidney.Name)) then return self:KidneyOnCommand() end end,
        }
    return rotation:RunPriorityList(mouseoverList)
end

local autoAttackList
function rotation:AutoAttack()
    autoAttackList = autoAttackList or
        {
            function() if (self.GcdReadyIn > self.ActionAdvanceWindow and not spells.AutoAttack:IsQueued()) then return spells.AutoAttack end end,
        }
    return rotation:RunPriorityList(autoAttackList)
end

function rotation:AwaitedVanishAmbush()
    local necroticPitch = addon.Common.Spells.NecroticPitch
    if (self.Player.Debuffs:Applied(necroticPitch.Debuff)) then
        return nil
    end
    if (self.GcdReadyIn < 0.01 and self.Energy > 50) then
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

function rotation:SliceAndDice()
    if (self.Player.Buffs:Applied(spells.RollTheBones.GrandMelee)) then
        return nil
    end
    if (spells.SwiftSlasher.Known) then
        if (self.Player.Buffs:Remains(spells.SliceAndDice.Buff) < spells.SliceAndDice.Pandemic) then
            if (self.ComboDeficit > 0) then
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
        local stacks = self.Player.Buffs:Stacks(spells.PistolShot.Opportunity)
        if (self.ComboDeficit > 3 and stacks > 0 or stacks > 3) then
            return spells.PistolShot
        end
        return nil
    end
    if (self.Player.Buffs:Applied(spells.PistolShot.Opportunity)) then
        return spells.PistolShot
    end
    return nil
end

function rotation:ColdBlood()
    local settings = self.Settings
    local player = self.Player
    if (self.ComboHolding) then
        return nil
    end
    if (settings.AOE and player.Buffs:Remains(spells.BladeFlurry.Buff) < 1 and spells.BladeFlurry:ReadyIn() < 1) then
        return nil
    end
    if (spells.GreenskinsWickers.Known) then
        if (not self.ComboFinisherAllowed and player.Buffs:Applied(spells.GreenskinsWickers.Buff) and self:PistolShot()) then
            return spells.ColdBlood
        end
        return nil
    end
    if (spells.ImprovedBetweenTheEyes.Known) then
        if (self.ComboFinisherAllowed and (not spells.FanTheHammer.Known or self.GcdReadyIn <= self.ActionAdvanceWindow) and spells.BetweenTheEyes:ReadyIn() <= self.GcdReadyIn) then
            return spells.ColdBlood
        end
        return nil
    end
    if (spells.SummarilyDispatched.Known) then
        local stacks, remains = player.Buffs:Stacks(spells.SummarilyDispatched.Buff), player.Buffs:Remains(spells.SummarilyDispatched.Buff)
        local setBonus4 = player.Equipment:ActiveSetBonus(setBonuses.DFVault.ItemsId, 4)
        if (self.ComboFinisherAllowed and (not spells.FanTheHammer.Known or self.GcdReadyIn <= self.ActionAdvanceWindow) and ((setBonus4 and player.Buffs:Applied(setBonuses.DFVault.Buff4Id)) or (stacks > 4 or (stacks > 2 and remains < 3)))) then
            return spells.ColdBlood
        end
        return nil
    end
    if (not self.ComboFinisherAllowed and (not spells.FanTheHammer.Known or self.GcdReadyIn <= self.ActionAdvanceWindow) and spells.Ambush:IsUsableNow()) then
        local setBonus2 = player.Equipment:ActiveSetBonus(setBonuses.DFVault.ItemsId, 2)
        if (setBonus2 and not player.Buffs:Applied(setBonuses.DFVault.Buff2Id)) then
            return nil
        end
        local usable, noMana = spells.Ambush:IsUsableNow()
        if (usable or noMana) then
            return spells.ColdBlood
        end
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

local activeRtb = {
    TrueBearing = false, -- CDR
    SkullAndCrossbones = false, -- 25% Double SS
    Broadside = false, -- 1 combo gen
    RuthlessPrecision = false, -- crit
    BuriedTreasure = false, -- energy regen
    GrandMelee = false, -- SnD application and leech
}
---@return Spell?
function rotation:RollTheBones()
    if (self.ShortBursting) then
        return nil
    end

    if (spells.SwiftSlasher.Known and not self.Player.Buffs:Applied(spells.SliceAndDice.Buff)) then
        return nil
    end

    local rtb = spells.RollTheBones
    local buffs = self.Player.Buffs
    local inPandemic = false
    local count = 0
    for name, _ in pairs(activeRtb) do
        local id = rtb[name] or addon.Helper.Print("RollTheBones buff id is missing for", name)
        local aura = buffs:Find(id)
        if (aura and aura.FullDuration > 20 and aura.Remains > self.ActionAdvanceWindow) then
            activeRtb[name] = true
            count = count + 1
            inPandemic = inPandemic or aura.Remains < rtb.Pandemic
        else
            activeRtb[name] = false
        end
    end

    local reroll = function()
        if (count > 2) then
            return false
        elseif (activeRtb.TrueBearing or activeRtb.SkullAndCrossbones) then
            return false
        elseif (count > 1 and not (activeRtb.GrandMelee and activeRtb.BuriedTreasure)) then
            return false
        else
            return true
        end
    end

    if (reroll()) then
        return rtb
    end
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
    local comboFinisher = min(comboMax, self.ComboFinisher)
    if (spells.SummarilyDispatched.Known) then
        comboFinisher = max(5, self.ComboFinisher)
    elseif (spells.GreenskinsWickers.Known and spells.BetweenTheEyes:ReadyIn() <= self.GcdReadyIn) then
        comboFinisher = max(5, self.ComboFinisher)
    elseif (self.Player.Buffs:Applied(spells.RollTheBones.Broadside)) then
        comboFinisher = min(comboMax - 1, self.ComboFinisher)
    end
    return self.Combo >= comboFinisher
end

function rotation:ShortBurstEffects()
    local player = self.Player
    return player.Buffs:Applied(spells.ShadowDance.Buff) or player.Debuffs:Applied(spells.Dreadblades.Debuff) or player.Buffs:Applied(spells.Subterfuge.Buff) or player.Buffs:Applied(spells.ColdBlood.Buff)
end

local tricksMacro = addon.Convenience:CreateTricksMacro("TricksNamed", spells.TricksOfTheTrade)

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
    self.ComboFinisherAllowed = self:FinisherAllowed()
    self.ComboHolding = false
    self.MyHealthPercent, self.MyHealthPercentDeficit = player:HealthPercent()
    self.MyHealAbsorb = player:HealAbsorb()
    self.NowCasting, self.CastingEndsIn = player:NowCasting()
    self.InInstance = player:InInstance()
    self.InCombatWithTarget = player.Target:InCombatWithMe()
    self.CanAttackTarget = player.Target:CanAttack()
    self.CanDotTarget = player.Target:CanDot()
    self.TinyTarget = player.Target:IsTiny()
    self.ShortBursting = self:ShortBurstEffects()

    spells.SliceAndDice.Pandemic = self:ComboPandemic(6)
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
        self.Stealhed = IsStealthed()
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

    spells.ThistleTea.Key = "s-1"
    spells.ShadowDance.Key = spells.ThistleTea.Key
    spells.MarkedForDeath.Key = "s-2"
    spells.Ambush.Key = "s-3"
    spells.KillingSpree.Key = "s-4"
    spells.Dreadblades.Key = spells.KillingSpree.Key
    spells.BladeRush.Key = "s-5"
    spells.Sepsis.Key = spells.BladeRush.Key
    spells.GhostlyStrike.Key = spells.BladeRush.Key
    spells.Shiv.Key = "s-6"
    spells.ColdBlood.Key = "s-7"

    spells.KidneyShot.Key = "s-8"
    spells.Vanish.Key = "s-9"

    spells.Kick.Key = "F7"

    spells.CrimsonVial.Key = "F11"
    spells.AutoAttack.Key = "F12"

    local equip = addon.Player.Equipment
    equip.Trinket14.Key = "s-0"
    equip.Trinket13.Key = "s--"

    local items = self.Items
    items.Healthstone.Key = "s-="
end

addon:AddRotation("ROGUE", 2, rotation)
