local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@type table<string,Spell>
local spells = {
    AutoAttack = addon.Common.Spells.AutoAttack,
    Execute = {
        Id = 163201,
        Buff = 52437,
    },
    Revenge = {
        Id = 6572,
        Buff = 5302,
    },
    ImpedingVictory = {
        Id = 202168,
        Buff = 32216,
    },
    ThunderClap = {
        Id = 6343,
    },
    ShieldSlam = {
        Id = 23922,
    },
    IgnorePain = {
        Id = 190456,
        Buff = 190456,
    },
    ShieldBlock = {
        Id = 2565,
        Buff = 132404,
        Pandemic = 8 * 0.3,
    },
    BattleStance = {
        Id = 386164,
        Buff = 386164,
    },
    DefensiveStance = {
        Id = 386208,
        Buff = 386208,
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
    Charge = {
        Id = 100,
    },
    ShieldCharge = {
        Id = 385952,
    },
    DemoralizingShout = {
        Id = 1160,
    },
    BoomingVoice = {
        Id = 202743,
    },
    LastStand = {
        Id = 12975,
    },
    Bolster = {
        Id = 280001,
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
    DemoralizingShout = {
        Name = "demoralshout",
    },
    TitanicThrow = {
        Name = "titanicthrow",
    },
    Charge = {
        Name = "charge",
    },
    ShieldCharge = {
        Name = "shieldcharge",
    },
}

---@type table<string,Item>
local items = addon.Common.Items

---@type Rotation
local rotation = {
    Name                   = "Warrior-Protection",
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
    ShieldBlockLow         = false,
}

function rotation:SelectAction()
    self:Refresh()
    local playerBuffs = self.Player.Buffs
    local targetDebuffs = self.Player.Target.Debuffs
    self:Utility()
    if (self.CanAttackTarget and (not self.InInstance or self.InCombatWithTarget)) then
        if (self.InRange) then
            self:AutoAttack()
            self:Base()
            if (self.Settings.Burst) then
                self:BattleMode()
            else
                self:DefenceMode()
            end
        end
    end
end

local baseList
function rotation:Base()
    local settings = self.Settings
    local player = self.Player
    local target = self.Player.Target
    local mouseover = player.Mouseover
    local equip = player.Equipment
    local grievousWoundId = addon.Common.Spells.GrievousWound.Debuff
    baseList = baseList or
        {
        }
    return rotation:RunPriorityList(baseList)
end

local battleList
function rotation:BattleMode()
    local settings = self.Settings
    local player = self.Player
    local target = self.Player.Target
    local equip = player.Equipment
    battleList = battleList or
        {
            function() if (not player.Buffs:Applied(spells.BattleStance.Buff)) then return spells.BattleStance end end,
            function() if (self.MyHealthPercentDeficit > 35 or self.MyHealAbsorb > 0) then return spells.ImpedingVictory end end,
            function() return spells.ShieldCharge end,
            function() return spells.Execute end,
            function() return spells.Revenge end,
            function() if (settings.AOE) then return spells.ThunderClap end end,
            function() return spells.ShieldSlam end,
            function() return spells.ThunderClap end,
            function() if (player.Buffs:Applied(spells.ImpedingVictory.Buff)) then return spells.ImpedingVictory end end,
            function() if (spells.BoomingVoice.Known) then return spells.DemoralizingShout end end,
        }
    return rotation:RunPriorityList(battleList)
end

local defenseList
function rotation:DefenceMode()
    local settings = self.Settings
    local player = self.Player
    local target = self.Player.Target
    local equip = player.Equipment
    defenseList = defenseList or
        {
            function() if (not player.Buffs:Applied(spells.DefensiveStance.Buff)) then return spells.DefensiveStance end end,
            function() if (spells.Bolster.Known and not player.Buffs:Applied(spells.ShieldBlock.Buff) and spells.ShieldBlock:ReadyIn() > 0.5) then return spells.LastStand end end,
            function() if (self.ShieldBlockLow) then return spells.ShieldBlock end end,
            function() if (((not self.ShieldBlockLow or self.Rage >= (30 + 35)) and self:CanAddIgnorePain()) or self.RageDeficit < 15) then return spells.IgnorePain end end,
            function() if (self.MyHealthPercentDeficit > 35 or self.MyHealAbsorb > 0) then return spells.ImpedingVictory end end,
            function() return spells.ShieldSlam end,
            function() return spells.ThunderClap end,
            function() if (player.Buffs:Applied(spells.Revenge.Buff)) then return spells.Revenge end end,
            function() if (player.Buffs:Applied(spells.Execute.Buff)) then return spells.Execute end end,
            function() if (not self.ShieldBlockLow and self.Rage > 40) then return spells.Revenge end end,
            function() if (spells.BoomingVoice.Known) then return spells.DemoralizingShout end end,
        }
    return rotation:RunPriorityList(defenseList)
end

local utilityList
function rotation:Utility()
    local player = self.Player
    local target = self.Player.Target
    local mouseover = player.Mouseover
    utilityList = utilityList or
        {
            function() if (self.MyHealthPercentDeficit > 55) then return items.Healthstone end end,
            function() if (self.CmdBus:Find(cmds.Charge.Name) and spells.Charge:IsInRange()) then return spells.Charge end end,
            function() if (self.CmdBus:Find(cmds.Kick.Name) and ((self.CanAttackMouseover and spells.Pummel:IsInRange("mouseover") and mouseover:CanKick()) or (not self.CanAttackMouseover and self.CanAttackTarget and spells.Pummel:IsInRange("target") and target:CanKick()))) then return spells.Pummel end end,
            function() if (spells.StormBolt.Known and self.CmdBus:Find(cmds.StormBolt.Name) and ((self.CanAttackMouseover and spells.StormBolt:IsInRange("mouseover")) or (not self.CanAttackMouseover and self.CanAttackTarget and spells.StormBolt:IsInRange("target")))) then return spells.StormBolt end end,
            function() if (self.CmdBus:Find(cmds.TitanicThrow.Name) and ((self.CanAttackMouseover and spells.TitanicThrow:IsInRange("mouseover")) or (not self.CanAttackMouseover and self.CanAttackTarget and spells.TitanicThrow:IsInRange("target")))) then return spells.TitanicThrow end end,
            function() if (self.CmdBus:Find(cmds.DemoralizingShout.Name)) then return spells.DemoralizingShout end end,
            function() if (spells.Shockwave.Known and self.CmdBus:Find(cmds.Shockwave.Name)) then return spells.Shockwave end end,
            function() if (spells.ShieldCharge.Known and self.CmdBus:Find(cmds.ShieldCharge.Name) and spells.ShieldCharge:IsInRange("target")) then return spells.ShieldCharge end end,
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
})
local burstTrinkets = addon.Helper.ToHashSet({
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
end

local min, PlayerEffectiveAttackPower, GetCombatRatingBonus, GetVersatilityBonus, CR_VERSATILITY_DAMAGE_DONE, ATTACK_POWER_MAGIC_NUMBER =
    min, PlayerEffectiveAttackPower, GetCombatRatingBonus, GetVersatilityBonus, CR_VERSATILITY_DAMAGE_DONE, ATTACK_POWER_MAGIC_NUMBER
function rotation:CanAddIgnorePain()
    local player = self.Player
    local ignorePain = player.Buffs:Find(spells.IgnorePain.Buff)
    if (not ignorePain or ignorePain.Remains < 0.5) then
        return true
    end
    local preferredCoef = 1.0
    local amount = ignorePain.Amount or 0
    local canAdd = PlayerEffectiveAttackPower() * ATTACK_POWER_MAGIC_NUMBER * (1 + (GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE)) / 100)
    local myHealth, myHealthDeficit = player:Health()
    local maxAmount = (myHealth + myHealthDeficit) * 0.3
    maxAmount = min(canAdd * preferredCoef, maxAmount)
    return maxAmount - amount > canAdd
end

function rotation:ShieldBlockFading()
    local player = self.Player
    return player.Buffs:Remains(spells.ShieldBlock.Buff) < 2.4
end

function rotation:Refresh()
    local player = self.Player
    local timestamp = addon.Timestamp
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
    self.ShieldBlockLow = self:ShieldBlockFading()
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
    spells.TitanicThrow.Key = "1"
    spells.ShieldCharge.Key = "2"
    spells.ShieldSlam.Key = "3"
    spells.ThunderClap.Key = "4"
    spells.IgnorePain.Key = "5"
    spells.ShieldBlock.Key = "6"
    spells.Shockwave.Key = "7"

    spells.StormBolt.Key = "F1"
    spells.Pummel.Key = "F7"
    spells.DemoralizingShout.Key = "F8"
    spells.LastStand.Key = "F9"
    spells.AutoAttack.Key = "F12"

    spells.ImpedingVictory.Key = "num1"
    spells.Execute.Key = "num3"
    spells.Revenge.Key = "num4"
    spells.BattleStance.Key = "num6"
    spells.DefensiveStance.Key = spells.BattleStance.Key

    local equip = addon.Player.Equipment
    equip.Trinket14.Key = "num0"
    equip.Trinket13.Key = "num-"

    local items = self.Items
    items.Healthstone.Key = "num+"
end

addon:AddRotation("WARRIOR", 3, rotation)
