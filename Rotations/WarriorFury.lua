local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@type table<string,Spell>
local spells = {
    Execute = {
        Id = 280735,
    },
    Slam = {
        Id = 1464,
    },
    BerserkerStance = {
        Id = 386196,
        Buff = 386196,
    },
    DefensiveStance = {
        Id = 386208,
        Buff = 386208,
    },
    VictoryRush = {
        Id = 34428,
    },
    ImpendingVictory = {
        Id = 202168,
    },
    Whirlwind = {
        Id = 190411,
        Buff = 85739,
    },
    Bloodthist = {
        Id = 23881,
    },
    RagingBlow = {
        Id = 85288,
    },
    Rampage = {
        Id = 184367,
    },
    Onslaught = {
        Id = 315720,
    },
    Enrage = {
        Id = 184361,
        Buff = 184362,
    },
    Recklessness = {
        Id = 1719,
        Buff = 1719,
    },
    Avatar = {
        Id = 107574,
    },
    OdynsFury = {
        Id = 385059,
    },
    TitanicThrow = {
        Id = 384090,
    },
    Pummel = {
        Id = 6552,
    },
    StormBolt = {
        Id = 107570,
    },
    Shockwave = {
        Id = 46968,
    },
    EnragedRegeneration = {
        Id = 184364,
        Buff = 184364,
    },
    StormOfSwords = {
        Id = 388903,
    },
    Annihilator = {
        Id = 383916,
    },
    Tenderize = {
        Id = 388933,
    },
    Victorious = {
        Id = 32216,
        Buff = 32216,
    },
    LightsJudgment = {
        Id = 255647,
    },
}

local cmds = {
    Kick = {
        Name = "kick",
    },
    StormBolt = {
        Name = "stormbolt",
    },
    Shockwave = {
        Name = "shockwave",
    },
    TitanicThrow = {
        Name = "titanicthrow",
    },
}

---@type table<string,Item>
local items = addon.Common.Items

---@type Rotation
local rotation = {
    Name                   = "Warrior-Fury",
    Spells                 = spells,
    Items                  = items,
    Cmds                   = cmds,
    RangeChecker           = spells.Execute,
    -- locals
    InRange                = false,
    Rage                   = 0,
    RageDeficit            = 0,
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
    Enraged                = false,
}

function rotation:SelectAction()
    self:Refresh()
    local playerBuffs = self.Player.Buffs
    local targetDebuffs = self.Player.Target.Debuffs
    self:Utility()
    if (self.CanAttackTarget and (not self.InInstance or self.InCombatWithTarget)) then
        if (self.InRange) then
            self:AutoAttack()
            self:SingleTarget()
        end
    end
end

local singleTargetList
function rotation:SingleTarget()
    local settings = self.Settings
    local player = self.Player
    local target = self.Player.Target
    local mouseover = player.Mouseover
    local equip = player.Equipment
    local grievousWoundId = addon.Common.Spells.GrievousWound.Debuff
    singleTargetList = singleTargetList or
        {
            function() if (not player.Buffs:Applied(spells.BerserkerStance.Buff) and not player.Buffs:Applied(spells.DefensiveStance.Buff)) then return spells.BerserkerStance end end,
            function() if (self.MyHealthPercentDeficit > 35 or self.MyHealAbsorb > 0 or player.Debuffs:Applied(grievousWoundId)) then return spells.ImpendingVictory end end,
            function() if ((self.MyHealthPercentDeficit > 35 or self.MyHealAbsorb > 0) and player.Buffs:Applied(spells.EnragedRegeneration.Buff)) then return spells.Bloodthist end end,
            function() return self:UseTrinket() end,
            function() if (settings.Burst) then return spells.LightsJudgment end end,
            function() if (settings.Burst) then return spells.Recklessness end end,
            function() if (settings.Burst) then return spells.Avatar end end,
            function() if (settings.Burst) then return spells.OdynsFury end end,
            function() if (settings.AOE and not player.Buffs:Applied(spells.Whirlwind.Buff)) then return spells.Whirlwind end end,
            function() return spells.Rampage end,
            function() if (spells.Tenderize.Known) then return spells.Onslaught end end,
            function() if (not self.Enraged) then return spells.Rampage end end,
            function() if (not self.Enraged) then return spells.Bloodthist end end,
            function() return spells.Onslaught end,
            function() return spells.Execute end,
            function() if (spells.StormOfSwords.Known) then return spells.Slam end end,
            function() if (not spells.Annihilator.Known) then return spells.RagingBlow end end,
            function() return spells.Bloodthist end,
            function() return spells.Whirlwind end,
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
            function() if (self.CmdBus:Find(cmds.Kick.Name) and ((self.CanAttackMouseover and spells.Pummel:IsInRange("mouseover") and mouseover:CanKick()) or (not self.CanAttackMouseover and self.CanAttackTarget and spells.Pummel:IsInRange("target") and target:CanKick()))) then return spells.Pummel end end,
            function() if (spells.StormBolt.Known and self.CmdBus:Find(cmds.StormBolt.Name) and ((self.CanAttackMouseover and spells.StormBolt:IsInRange("mouseover")) or (not self.CanAttackMouseover and self.CanAttackTarget and spells.StormBolt:IsInRange("target")))) then return spells.StormBolt end end,
            function() if (self.CmdBus:Find(cmds.TitanicThrow.Name) and ((self.CanAttackMouseover and spells.TitanicThrow:IsInRange("mouseover")) or (not self.CanAttackMouseover and self.CanAttackTarget and spells.TitanicThrow:IsInRange("target")))) then return spells.TitanicThrow end end,
            function() if (spells.Shockwave.Known and self.CmdBus:Find(cmds.Shockwave.Name)) then return spells.Shockwave end end,
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

function rotation:Refresh()
    local player = self.Player
    local timestamp = self.Timestamp
    player.Buffs:Refresh(timestamp)
    player.Debuffs:Refresh(timestamp)
    player.Target.Buffs:Refresh(timestamp)
    player.Target.Debuffs:Refresh(timestamp)

    self.InRange = self.RangeChecker:IsInRange()
    self.Rage, self.RageDeficit = player:Resource(Enum.PowerType.Rage)
    self.MyHealthPercent, self.MyHealthPercentDeficit = player:HealthPercent()
    self.MyHealAbsorb = player:HealAbsorb()
    self.NowCasting, self.CastingEndsIn = player:NowCasting()
    self.ActionAdvanceWindow = self.Settings.ActionAdvanceWindow
    self.InInstance = player:InInstance()
    self.InCombatWithTarget = player.Target:InCombatWithMe()
    self.CanAttackTarget, self.CanAttackMouseover = player.Target:CanAttack(), player.Mouseover:CanAttack()
    self.CanDotTarget = player.Target:CanDot()
    self.Enraged = player.Buffs:Applied(spells.Enrage.Buff)
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

    return addon.Initializer.NewEventTracker(frameHandlers):RegisterEvents()
end

function rotation:SetLayout()
    local spells = self.Spells
    spells.Execute.Key = "2"
    spells.RagingBlow.Key = "3"
    spells.Bloodthist.Key = "4"
    spells.Rampage.Key = "5"
    spells.Onslaught.Key = "6"

    spells.Whirlwind.Key = "8"

    spells.StormBolt.Key = "F1"
    spells.Pummel.Key = "F7"
    spells.AutoAttack.Key = "F12"

    spells.VictoryRush.Key = "num1"
    spells.ImpendingVictory.Key = spells.VictoryRush.Key
    spells.Slam.Key = "num3"
    spells.BerserkerStance.Key = "num5"
    spells.OdynsFury.Key = "num6"
    spells.Avatar.Key = "num7"
    spells.Recklessness.Key = "num8"
    spells.LightsJudgment.Key = "num9"

    local equip = addon.Player.Equipment
    equip.Trinket14.Key = "num0"
    equip.Trinket13.Key = "num-"

    local items = self.Items
    items.Healthstone.Key = "num+"
end

addon:AddRotation("WARRIOR", 2, rotation)
