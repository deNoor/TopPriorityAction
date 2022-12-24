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
    PistolShot = {
        Id = 185763,
        Opportunity = 195627,
    },
    Ambush = {
        Id = 8676,
    },
    Eviscerate = {
        Id = 196819,
    },
    Dispatch = {
        Id = 2098,
    },
    SliceAndDice = {
        Id = 315496,
        Buff = 315496,
        Pandemic = 18 * 0.3
    },
    RollTheBones = {
        Id = 315508,
        Pandemic = 30 * 0.3,
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
    BetweenTheEyes = {
        Id = 315341,
    },
    GreenskinsWickers = {
        Id = 386823,
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
    }
}

---@type table<string,Item>
local items = {}

---@type Rotation
local rotation = {
    Name = "Rogue-Assassination",
    Spells = spells,
    Items = items,
    Cmds = cmds,

    -- instance fields, init nils in Activate
    LocalEvents          = nil, ---@type EventTracker
    CmdBus               = addon.CmdBus,
    EmptyAction          = addon.Initializer.Empty.Action,
    Player               = addon.Player,
    InterruptUndesirable = addon.WowClass.InterruptUndesirable,
    RangeChecker         = spells.SinisterStrike,
    ComboFinisher        = 4,
    ComboKidney          = 4,

    -- locals
    Stealhed               = IsStealthed(), -- UPDATE_STEALTH, IsStealthed()
    InRange                = false,
    Energy                 = 0,
    EnergyDeficit          = 0,
    Combo                  = 0,
    ComboDeficit           = 0,
    ComboFinisherAllowed   = false,
    ComboHolding           = false,
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
            function() if (self.CmdBus:Find(cmds.Kidney.Name)) then return self:KidneyOnCommand() end end,
            function() if (self.Energy < 30) then return spells.ThistleTea end end,
            function() if (self.Combo > 0 and not self.ComboHolding and player.Buffs:Remains(spells.SliceAndDice.Buff) < 3) then return spells.SliceAndDice end end,
            function() return self:RollTheBones() end,
            function() if (settings.Burst and not self.ComboHolding) then return spells.AdrenalineRush end end,
            function() if (self.Settings.AOE and not self.ComboHolding and not player.Buffs:Applied(spells.BladeFlurry.Buff)) then return spells.BladeFlurry end end,
            function() if (self.ComboFinisherAllowed and not self.ComboHolding) then return spells.BetweenTheEyes end end,
            -- function() if (self.ComboFinisherAllowed and not self.ComboHolding and player.Buffs:Remains(spells.SliceAndDice.Buff) < spells.SliceAndDice.Pandemic) then return spells.SliceAndDice end end,
            function() if (self.ComboFinisherAllowed and not self.ComboHolding) then return spells.Dispatch end end,
            function() if (self.ComboDeficit > 4 and not target:IsTotem()) then return spells.MarkedForDeath end end,
            function() if (target.Buffs:HasPurgeable()) then return spells.Shiv end end,
            function() if (settings.Burst and self.InInstance and spells.Vanish:ReadyIn() <= self.GcdReadyIn) then return self:AwaitedVanishAmbush() end end,
            function() if (player.Buffs:Applied(spells.PistolShot.Opportunity)) then return spells.PistolShot end end,
            function() return spells.Ambush end,
            function() return spells.SinisterStrike end,
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

function rotation:AwaitedVanishAmbush()
    if (self.GcdReadyIn < 10 and (self.Energy > 50 or self.Player.Buffs:Applied(spells.Blindside.Buff))) then
        return spells.Vanish
    else
        return self.EmptyAction
    end
end

local wipe = table.wipe
local activeRtb = {
    TrueBearing = false, -- CDR
    SkullAndCrossbones = false, -- 25% Double SS
    Broadside = false, -- 1 combo gen
    RuthlessPrecision = false, -- crit
    BuriedTreasure = false, -- energy regen
    GrandMelee = false, -- SnD increase and leech
}
local rtbBuffsIds = {
    TrueBearing = 193359,
    SkullAndCrossbones = 199603,
    Broadside = 193356,
    RuthlessPrecision = 193357,
    BuriedTreasure = 199600,
    GrandMelee = 193358,
}
---@return Spell?
function rotation:RollTheBones()
    local rtb = spells.RollTheBones
    local buffs = self.Player.Buffs
    local inPandemic = false
    local count = 0
    for name, id in pairs(rtbBuffsIds) do
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
        elseif (count > 1 and (activeRtb.GrandMelee or activeRtb.BuriedTreasure)) then
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

---@return boolean
function rotation:FinisherAllowed()
    local comboFinisher = self.ComboFinisher
    if (spells.GreenskinsWickers.Known and spells.BetweenTheEyes:ReadyIn() <= self.GcdReadyIn) then
        comboFinisher = 5
    elseif (self.Player.Buffs:Applied(spells.RollTheBones.Broadside)) then
        comboFinisher = 4
    end
    return self.Combo >= comboFinisher
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
    self.ComboFinisherAllowed = self:FinisherAllowed() -- self.ComboDeficit <= self.ComboFinisherToMax
    self.ComboHolding = false
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

    spells.SliceAndDice.Pandemic = self:ComboPandemic(6)
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
    spells.PistolShot.Key = "2"
    spells.SinisterStrike.Key = "3"
    spells.Eviscerate.Key = "4"
    spells.Dispatch.Key = spells.Eviscerate.Key
    spells.RollTheBones.Key = "5"
    spells.BetweenTheEyes.Key = "6"
    spells.AdrenalineRush.Key = "7"
    spells.BladeFlurry.Key = "8"

    spells.ThistleTea.Key = "s-1"
    spells.MarkedForDeath.Key = "s-2"
    spells.Ambush.Key = "s-3"
    spells.Shiv.Key = "s-6"
    spells.Feint.Key = "s-7"
    spells.KidneyShot.Key = "s-8"
    spells.Vanish.Key = "s-9"
    spells.AutoAttack.Key = "s-="

    spells.CrimsonVial.Key = "F6"

    local equip = addon.Player.Equipment
    equip.Trinket13.Key = "s--"
end

addon:AddRotation("ROGUE", 2, rotation)
