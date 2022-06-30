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
    Bloodbath = {
        Id = 335096,
    },
    RagingBlow = {
        Id = 85288,
    },
    CrushingBlow = {
        Id = 335097,
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
        Buff = 1719,
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
    RecklessAbandon = {
        Id = 202751,
        TalendId = 22402,
    },
    Siegebreaker = {
        Id = 280772,
        TalendId = 16037,
    },
    -- procs
    Victorious = {
        Id = 32216,
        Buff = 32216,
    },
    -- Shadowlands specials
    Condemn = {
        Id = 330325,
    },
    -- racials
    LightsJudgment = {
        Id = 255647,
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
            function() if (settings.Burst) then return spells.LightsJudgment end end,
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
            function() if (self.EnrageSec > 1 + self.ActionAdvanceWindow) then return spells.Bladestorm end end,
            function() return spells.Siegebreaker end,
            function() return spells.Rampage end,
            function() if (spells.Condemn.Known) then return spells.Condemn else return spells.Execute end end,
            function() if (self.EnrageSec > self.ActionAdvanceWindow) then return spells.DragonRoar end end,
            function() if (self.EnrageSec > self.ActionAdvanceWindow) then return self:RagingAndCrushingBlow() end end,
            function() return self:BloodThristOrBath() end,
            function() return self:RagingAndCrushingBlow() end,
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
        }
    return rotation:RunPriorityList(aoeList)
end

function rotation:ImproovedRecklessness()
    local player = self.Player
    return player.Talents[spells.RecklessAbandon.TalendId] and player.Buffs:Remains(spells.Recklessness.Buff) > self.ActionAdvanceWindow
end

function rotation:RagingAndCrushingBlow()
    return self:ImproovedRecklessness() and spells.CrushingBlow or spells.RagingBlow
end

function rotation:BloodThristOrBath()
    return self:ImproovedRecklessness() and spells.Bloodbath or spells.Bloodthist
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
    spells.Condemn.Key = spells.Execute.Key
    spells.RagingBlow.Key = "3"
    spells.CrushingBlow.Key = spells.RagingBlow.Key
    spells.Bloodthist.Key = "4"
    spells.Bloodbath.Key = spells.Bloodthist.Key
    spells.Rampage.Key = "5"
    spells.Siegebreaker.Key = "6"
    spells.Recklessness.Key = "7"
    spells.Whirlwind.Key = "8"
    spells.Bladestorm.Key = "9"
    spells.DragonRoar.Key = spells.Bladestorm.Key
    spells.VictoryRush.Key = "-"
    spells.ImpendingVictory.Key = spells.VictoryRush.Key

    local equip = addon.Player.Equipment
    equip.Trinket13.Key = "F11"
    spells.LightsJudgment.Key = "F12"
end

addon:AddRotation("WARRIOR", 2, rotation)
