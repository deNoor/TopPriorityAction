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
    VictoryRush = {
        Id = 34428,
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
    Enrage = {
        Id = 184361,
        Buff = 184362,
    },
    Recklessness = {
        Id = 1719,
    },
    -- talents
    ImpendingVictory = {
        Id = 202168,
        TalendId = 22625,
    },
    DragonRoar = {
        Id = 118000,
        TalendId = 22398,
    },
    Bladestorm = {
        Id = 46924,
        TalendId = 22400,
    },
    -- procs
    Victorious = {
        Id = 32216,
        Buff = 32216,
    },
}

---@type table<string,Item>
local items = {}

---@type Rotation
local rotation = {
    Name = "Warrior-Fury",
    Spells = spells,
    Items = items,

    -- instance fields, init nils in Activate
    EmptyAction  = addon.Initializer.Empty.Action,
    Player       = addon.Player,
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
    LastCastSent           = 0,
    MouseoverIsFriend      = false,
    MouseoverIsEnemy       = false,

    EnrageSec = 0,
}

function rotation:SelectAction()
    self:Refresh()
    local playerBuffs = self.Player.Buffs
    local targetDebuffs = self.Player.Target.Debuffs
    if (true)
    then
        -- self:Utility()
        if (self.CanAttackTarget and (not self.InInstance or self.InCombatWithTarget)) then
            -- self:Dispel()
            if (self.InRange) then
                self:Aoe()
                self:Base()
            end
        end
    end
end

local baseList
function rotation:Base()
    local settings = self.Settings
    local player = self.Player
    local target = self.Player.Target
    local equip = player.Equipment
    baseList = baseList or
        {
            function() if (settings.Burst) then return spells.ConvokeTheSpirits end end,
            function() if (settings.Burst) then return spells.Recklessness end end,
            function() if (equip.Trinket13:IsInRange("target")) then return equip.Trinket13 end end,
            function()
                if (player.Talents[spells.ImpendingVictory.TalendId]) then
                    if (self.MyHealthPercentDeficit > 40) then return spells.ImpendingVictory end
                else
                    if (self.MyHealthPercentDeficit > 20) then return spells.VictoryRush end
                end
            end,
            function() if (settings.AOE and not player.Buffs:Applied(spells.Whirlwind.Buff)) then return spells.Whirlwind end end,
            function() if (self.EnrageSec <= self.ActionAdvanceWindow) then return spells.Rampage end end,
            function() return spells.Execute end,
            function() if (self.EnrageSec > 2 + self.ActionAdvanceWindow) then return spells.Bladestorm end end,
            function() if (self.EnrageSec > self.ActionAdvanceWindow) then return spells.DragonRoar end end,
            function() return spells.Rampage end,
            -- function() if (self.EnrageSec < self.ActionAdvanceWindow) then return spells.Bloodthist end end,
            -- function() if (spells.RagingBlow:ActiveCharges() > 1) then return spells.RagingBlow end end,
            function() return spells.Bloodthist end,
            function() return spells.RagingBlow end,
            function() if (player.Buffs:Remains(spells.Victorious.Buff) > 0.5) then return player.Talents[spells.ImpendingVictory.TalendId] and spells.ImpendingVictory or spells.VictoryRush end end,
            function() return spells.Whirlwind end,
        }
    return rotation:RunPriorityList(baseList)
end

local aoeList
function rotation:Aoe()
    local settings = self.Settings
    local player = self.Player
    local target = self.Player.Target
    local equip = player.Equipment
    aoeList = aoeList or
        {
            function() if (settings.AOE and not player.Buffs:Applied(spells.Whirlwind.Buff)) then return spells.Whirlwind end end,
        }
    return rotation:RunPriorityList(aoeList)
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
    self.Rage, self.RageDeficit = player:Resource(Enum.PowerType.Rage)
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
    self.EnrageSec = player.Buffs:Remains(spells.Enrage.Buff)
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

    self.WaitForResource = false
    self.LocalEvents = self:CreateLocalEventTracker()
    self:SetLayout()
end

function rotation:CreateLocalEventTracker()
    local handlers = {}

    return addon.Initializer.NewEventTracker(handlers):RegisterEvents()
end

function rotation:SetLayout()
    local spells = self.Spells
    spells.Execute.Key = "2"
    spells.RagingBlow.Key = "3"
    spells.Bloodthist.Key = "4"
    spells.Rampage.Key = "5"
    spells.Recklessness.Key = "7"
    spells.Whirlwind.Key = "8"
    spells.Bladestorm.Key = "9"
    spells.DragonRoar.Key = "9"
    spells.VictoryRush.Key = "-"
    spells.ImpendingVictory.Key = "-"

    local equip = addon.Player.Equipment
    equip.Trinket13.Key = "F11"
end

addon:AddRotation("WARRIOR", 2, rotation)
