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
    Pummel = {
        Id = 6552,
    },
    StormBolt = {
        Id = 107570,
    },
    DemoralizingShout = {
        Id = 1160,
    },
}

local cmds = {
    Kick = {
        Name = "kick",
    },
    StormBolt = {
        Name = "stormbolt",
    },
    DemoralizingShout = {
        Name = "demoralshout",
    },
}

---@type table<string,Item>
local items = addon.Common.Items

---@type Rotation
local rotation = {
    Name = "Warrior-Protection",
    Spells = spells,
    Items = items,
    Cmds = cmds,

    RangeChecker = spells.Execute,

    -- locals
    InRange                = false,
    Rage                   = 0,
    RageDeficit            = 0,
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
            if (self.Settings.Burst) then
                self:BattleMode()
            else
                self:DefenceMode()
            end
        end
    end
end

local singleTargetList
function rotation:SingleTarget()
    local settings = self.Settings
    local player = self.Player
    local target = self.Player.Target
    local equip = player.Equipment
    local grievousWoundId = addon.Common.Spells.GrievousWound.Debuff
    singleTargetList = singleTargetList or
        {
            function() if (self.CmdBus:Find(cmds.Kick.Name) and target:CanKick()) then return spells.Pummel end end,
        }
    return rotation:RunPriorityList(singleTargetList)
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
            function() return spells.Execute end,
            function() return spells.Revenge end,
            function() return spells.ShieldSlam end,
            function() return spells.ThunderClap end,
            function() if (player.Buffs:Applied(spells.ImpedingVictory.Buff)) then return spells.ImpedingVictory end end,
        }
    return rotation:RunPriorityList(battleList)
end

local defenseList
function rotation:DefenceMode()
    local settings = self.Settings
    local player = self.Player
    local target = self.Player.Target
    local equip = player.Equipment
    local grievousWoundId = addon.Common.Spells.GrievousWound.Debuff
    defenseList = defenseList or
        {
            function() if (not player.Buffs:Applied(spells.DefensiveStance.Buff)) then return spells.DefensiveStance end end,
            function() if (player.Buffs:Remains(spells.ShieldBlock.Buff) < spells.ShieldBlock.Pandemic) then return spells.ShieldBlock end end,
            function() if (self.Rage >= 75 or not player.Buffs:Applied(spells.IgnorePain.Buff)) then return spells.IgnorePain end end,
            function() if (self.MyHealthPercentDeficit > 35 or player.Debuffs:Applied(grievousWoundId)) then return spells.ImpedingVictory end end,
            function() return spells.ShieldSlam end,
            function() return spells.ThunderClap end,
            function() if (player.Buffs:Applied(spells.Revenge.Buff)) then return spells.Revenge end end,
            function() if (player.Buffs:Applied(spells.Execute.Buff)) then return spells.Execute end end,
        }
    return rotation:RunPriorityList(defenseList)
end

local utilityList
function rotation:Utility()
    local player = self.Player
    local target = self.Player.Target
    local grievousWoundId = addon.Common.Spells.GrievousWound.Debuff
    utilityList = utilityList or
        {
            function() if (self.MyHealthPercentDeficit > 55) then return items.Healthstone end end,
            function() if (self.CmdBus:Find(cmds.StormBolt.Name)) then return spells.StormBolt end end,
            function() if (self.CmdBus:Find(cmds.DemoralizingShout.Name)) then return spells.DemoralizingShout end end,
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
    self.GcdReadyIn = player:GCDReadyIn()
    self.NowCasting, self.CastingEndsIn = player:NowCasting()
    self.ActionAdvanceWindow = self.Settings.ActionAdvanceWindow
    self.InInstance = player:InInstance()
    self.InCombatWithTarget = player.Target:InCombatWithMe()
    self.CanAttackTarget = player.Target:CanAttack()
    self.CanDotTarget = player.Target:CanDot()
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
    spells.ShieldSlam.Key = "3"
    spells.ThunderClap.Key = "4"
    spells.IgnorePain.Key = "5"
    spells.ShieldBlock.Key = "6"

    spells.ImpedingVictory.Key = "s-1"
    spells.Execute.Key = "s-3"
    spells.Revenge.Key = "s-4"
    spells.BattleStance.Key = "s-6"
    spells.DefensiveStance.Key = spells.BattleStance.Key
    spells.DemoralizingShout.Key = "s-7"
    spells.StormBolt.Key = "s-8"

    spells.Pummel.Key = "F7"
    spells.AutoAttack.Key = "F12"

    local equip = addon.Player.Equipment
    equip.Trinket14.Key = "s-0"
    equip.Trinket13.Key = "s--"

    local items = self.Items
    items.Healthstone.Key = "s-="
end

addon:AddRotation("WARRIOR", 3, rotation)
