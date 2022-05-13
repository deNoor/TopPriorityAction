local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@type table<string, Spell>
local spells = {
    TigersFury = {
        Key = "1",
        Id = 5217,
        Buff = 5217,
        NoGCD = true,
    },
    Rake = {
        Key = "2",
        Id = 1822,
        Debuff = 155722,
    },
    Shred = {
        Key = "3",
        Id = 5221,
    },
    FerociousBite = {
        Key = "4",
        Id = 22568,
    },
    Rip = {
        Key = "5",
        Id = 1079,
        Debuff = 1079,
    },
    Berserk = {
        Key = "7",
        Id = 106951,
        Buff = 106951,
    },
    Thrash = {
        Key = "8",
        Id = 106830,
        Debuff = 106830,
    },
    Swipe = {
        Key = "9",
        Id = 106785,
    },
    -- talents
    BrutalSlash = {
        Key = "0",
        Id = 0,
    },
    PrimalWrath = {
        Key = "0",
        Id = 0,
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
    -- CC and utility spells
    Maim = {
        Id = 22570,
        Debuff = 203123,
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
    -- Procs
    ClearCasting = {
        Id = 135700,
        Buff = 135700,
    },
}
---@type Rotation
local feralRotation = {
    -- framework dependencies
    Timestamp = 0,
    Settings = nil,
    EmptySpell = nil,
    Player = addon.Player,
    PauseTimestamp = 0,

    -- instance fields
    LocalEvents = addon.Initializer.NewEventTracker(),
    RangeChecker = (GetSpellInfo(spells.Rake.Id)),

    -- locals
    Stealhed = IsStealthed(), -- UPDATE_STEALTH, IsStealthed()
    WowClass = addon.WowClass,
    InRange = false,
    GcdReadyIn = 0,
    SpellQueueWindow = 0,
    InInstance = false,
    InCombat = false,
    CanFight = false,
    CanDot = false,
}

local IsSpellInRange = IsSpellInRange
function feralRotation:CheckInRange()
    self.InRange = (IsSpellInRange(self.RangeChecker, "target")) or false
    return self.InRange
end

function feralRotation:Pulse()
    if self:ShouldNotRun() then
        return self.EmptySpell
    end

    local selectedAction = nil

    self:Refresh()
    local now = self.Timestamp
    local playerBuffs = self.Player.Buffs
    local targetDebuffs = self.Player.Target.Debuffs
    if (playerBuffs:Applied(spells.CatForm)
        and self.InRange
        and self.CanFight
        and (not self.InInstance or self.InCombat)
        and self.GcdReadyIn < self.SpellQueueWindow)
    then
        if (not self.Settings.AOE) then
            selectedAction = self:StealthOpener() or self:SingleTarget()
        else
            selectedAction = self:Aoe()
        end
    end

    -- print("running feral")
    return selectedAction or self.EmptySpell
end

function feralRotation:StealthOpener()
    if(self.Stealhed) then
        -- return spells.Rake
    end
end

function feralRotation:SingleTarget()
    if (self.GcdReadyIn < self.SpellQueueWindow) then

    end
end

function feralRotation:Aoe()

end

local IsSpellInRange, GetInstanceInfo, UnitAffectingCombat, UnitCanAttack, UnitClassification, UnitIsDead = IsSpellInRange, GetInstanceInfo, UnitAffectingCombat, UnitCanAttack, UnitClassification, UnitIsDead
local instanceTypes = { "raid", "party", "pvp", "arena", }
local goodUnitClassifications = { "worldboss", "rareelite", "elite", "rare", "normal", }
function feralRotation:Refresh()
    local player = self.Player
    local timestamp = self.Timestamp
    player.Buffs:Refresh(timestamp)
    player.Debuffs:Refresh(timestamp)
    player.Target.Buffs:Refresh(timestamp)
    player.Target.Debuffs:Refresh(timestamp)

    self.InRange = IsSpellInRange(self.RangeChecker, "target") or false
    self.GcdReadyIn = self.WowClass:GCDReadyIn()
    self.SpellQueueWindow = addon.SavedSettings.Instance.SpellQueueWindow
    self.InInstance = instanceTypes[(select(2, GetInstanceInfo()))] ~= nil
    self.InCombat = (UnitAffectingCombat("player") or UnitAffectingCombat("target"))
    self.CanFight = UnitCanAttack("player", "target") and not UnitIsDead("target")
    self.CanDot = goodUnitClassifications[UnitClassification("target")] ~= nil
end

function feralRotation:Dispose()
    self.LocalEvents:Dispose()
end

function feralRotation:Activate()
    local handlers = self.LocalEvents.Handlers
    local IsStealthed = IsStealthed
    function handlers.UPDATE_STEALTH(event, eventArgs)
        self.Stealhed = IsStealthed()
    end

    self.LocalEvents:RegisterEvents()
end

addon.Player.Buffs = addon.Initializer.NewAuraCollection("player", "PLAYER|HELPFUL")
addon.Player.Debuffs = addon.Initializer.NewAuraCollection("player", "HARMFUL")
addon.Player.Target.Buffs = addon.Initializer.NewAuraCollection("target", "HELPFUL")
addon.Player.Target.Debuffs = addon.Initializer.NewAuraCollection("target", "PLAYER|HARMFUL")

addon.WowClass:AddRotation("DRUID", 2, spells, feralRotation)
