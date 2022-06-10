local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@type table<string,Spell>
local spells = {
    Execute = {
        Id = 5308,
    },
    Slam = {
        Id = 1464,
    },
    VictoryRush = {
        Id = 34428,
    },
    Whirlwind = {
        Id = 190411,
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
    if (self.CastingEndsIn <= self.ActionAdvanceWindow
        )
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
            function() if (equip.Trinket13:IsInRange("target")) then return equip.Trinket13 end end,
            function() if (self.MyHealthPercentDeficit > 25) then return spells.VictoryRush end end,
            function() return spells.Rampage end,
            function() return spells.Execute end,
            function() return spells.RagingBlow end,
            function() return spells.Bloodthist end,
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
            function() if (settings.AOE) then return spells.Whirlwind end end,
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
    self.CastingEndsIn = player:CastingEndsIn()
    self.ActionAdvanceWindow = self.Settings.ActionAdvanceWindow
    self.InInstance = player:InInstance()
    self.InCombatWithTarget = player:InCombatWithTarget()
    self.CanAttackTarget = player:CanAttackTarget()
    self.CanDotTarget = player:CanDotTarget()
    self.MouseoverIsFriend, self.MouseoverIsEnemy = UnitIsFriend("player", "mouseover"),
        UnitIsEnemy("player", "mouseover")
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
    spells.Whirlwind.Key = "8"
    spells.VictoryRush.Key = "-"

    local equip = addon.Player.Equipment
    equip.Trinket13.Key = "F11"
end

addon:AddRotation("WARRIOR", 2, rotation)
