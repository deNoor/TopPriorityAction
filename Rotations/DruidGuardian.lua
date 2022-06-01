local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@type table<string,Spell>
local spells = {
    Ironfur = {
        Id = 192081,
        Buff = 192081,
    },
    FrenziedRegeneration = {
        Id = 22842,
        Buff = 22842,
    },
    Thrash = {
        Id = 77758,
        Debuff = 192090,
    },
    Mangle = {
        Id = 33917,
    },
    Swipe = {
        Id = 213771,
    },
    Maul = {
        Id = 6807,
    },
    Moonfire = {
        Id = 8921,
        Debuff = 164812,
    },
    Berserk = {
        Id = 50334,
        Buff = 50334,
    },
    -- shapeshit forms
    CatForm = {
        Id = 768,
        Buff = 768,
    },
    BearForm = {
        Id = 5487,
        Buff = 5487,
    },
    TravelForm = {
        Id = 783,
        Buff = 783,
    },
    BoomkinForm = {
        Id = 197625,
        Buff = 197625,
    },
    -- utility
    Soothe = {
        Id = 2908,
    },
    RemoveCorruption = {
        Id = 2782,
    },
    -- talents
    Renewal = {
        Id = 108238,
        TalentId = 18570,
    },
    -- defensives
    Barkskin = {
        Id = 22812,
        Buff = 22812,
    },
    SurvivalInstincts = {
        Id = 61336,
        Buff = 61336,
    },
    -- Procs
    Gore = {
        Id = 210706,
        Buff = 93622,
    },
    -- Shadowlands specials
    AdaptiveSwarm = {
        Id = 325727,
    },
    ConvokeTheSpirits = {
        Id = 323764,
    },
}

---@type table<string,Item>
local items = {}

---@type Rotation
local rotation = {
    Spells = spells,
    Items = items,

    -- instance fields, init nils in Activate
    EmptyAction      = addon.Initializer.Empty.Action,
    Player           = addon.Player,
    RangeChecker     = spells.Mangle,
    ComboCap         = 4,
    DispellableTypes = addon.Helper.ToHashSet({ "Curse", "Poison", }),

    -- locals
    InRange                = false,
    InRange40              = false,
    Rage                   = 0,
    RageDeficit            = 0,
    ManaPercent            = 0,
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
    if (playerBuffs:Applied(spells.BearForm.Buff)
        and (not self.InInstance or self.InCombatWithTarget)
        and self.CastingEndsIn <= self.ActionAdvanceWindow
        )
    then
        self:Utility()
        if (self.CanAttackTarget) then
            if (self.InRange) then
                self:Base()
            elseif (self.InRange40) then
                self:Distant()
            end
        end
    end
end

local distantList
function rotation:Distant()
    local settings = self.Settings
    local player = self.Player
    local target = self.Player.Target
    local equip = player.Equipment
    distantList = distantList or
        {
            function() if (not settings.AOE --[[ and target.Debuffs:Remains(spells.Moonfire.Debuff) < 4.8 ]] and spells.Moonfire:IsInRange("target")) then return spells.Moonfire end end,
        }
    return rotation:RunPriorityList(distantList)
end

local baseList
function rotation:Base()
    local settings = self.Settings
    local player = self.Player
    local target = self.Player.Target
    local equip = player.Equipment
    baseList = baseList or
        {
            -- function() return spells.AdaptiveSwarm end,
            function() if (settings.Burst) then return spells.ConvokeTheSpirits end end,
            function() if (equip.Trinket13:IsInRange("target")) then return equip.Trinket13 end end,
            -- function() if (settings.Burst) then return spells.Berserk end end,
            function() if (self.MyHealthPercentDeficit >= 50 and not player.Buffs:Applied(spells.FrenziedRegeneration.Buff)) then return spells.FrenziedRegeneration end end,
            function() if (settings.Burst) then return spells.Maul end end,
            function() if (player.Buffs:Remains(spells.Ironfur.Buff) < 0.30 or self.RageDeficit <= 19) then return spells.Ironfur end end,
            function() return spells.Mangle end,
            function() return spells.Thrash end,
            function() if (not settings.AOE and target.Debuffs:Remains(spells.Moonfire.Debuff) < 4.8) then return spells.Moonfire end end,
            function() return spells.Swipe end,
        }
    return rotation:RunPriorityList(baseList)
end

local utilityList
function rotation:Utility()
    local settings = self.Settings
    local player = self.Player
    local target = self.Player.Target
    local mouseover = self.Player.Mouseover
    local function CanDispel()
        if (self.MouseoverIsFriend) then
            return mouseover.Debuffs:HasDispelable(self.DispellableTypes)
        end
        if (self.MouseoverIsEnemy) then
            return mouseover.Buffs:HasPurgeable()
        end
        return false
    end

    utilityList = utilityList or
        {
            function()
                if (settings.Dispel and spells.RemoveCorruption:IsInRange("mouseover") and CanDispel() and self.ManaPercent > 6.5) then
                    if (self.MouseoverIsFriend) then return spells.RemoveCorruption end
                    if (self.MouseoverIsEnemy) then return spells.Soothe end
                end
            end,
        }
    return rotation:RunPriorityList(utilityList)
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
    self.InRange40 = spells.Moonfire:IsInRange("target")
    self.Rage, self.RageDeficit = player:Resource(Enum.PowerType.Rage)
    self.ManaPercent = player:ResourcePercent(Enum.PowerType.Mana)
    self.MyHealthPercent, self.MyHealthPercentDeficit = player:HealthPercent()
    self.MyHealAbsorb = player:HealAbsorb()
    self.GcdReadyIn = player:GCDReadyIn()
    self.CastingEndsIn = player:CastingEndsIn()
    self.ActionAdvanceWindow = self.Settings.ActionAdvanceWindow
    self.InInstance = player:InInstance()
    self.InCombatWithTarget = player:InCombatWithTarget()
    self.CanAttackTarget = player:CanAttackTarget()
    self.CanDotTarget = player:CanDotTarget()
    self.MouseoverIsFriend, self.MouseoverIsEnemy = UnitIsFriend("player", "mouseover"), UnitIsEnemy("player", "mouseover")
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
    spells.FrenziedRegeneration.Key = "1"
    spells.Ironfur.Key = "2"
    spells.Swipe.Key = "3"
    spells.Mangle.Key = "4"
    spells.Thrash.Key = "5"
    spells.Moonfire.Key = "6"
    spells.Berserk.Key = "7"
    spells.ConvokeTheSpirits.Key = "9"
    spells.Maul.Key = "0"
    spells.Soothe.Key = "F6"
    spells.RemoveCorruption.Key = "F6"

    local equip = addon.Player.Equipment
    equip.Trinket13.Key = "F11"
end

addon:AddRotation("DRUID", 3, rotation)