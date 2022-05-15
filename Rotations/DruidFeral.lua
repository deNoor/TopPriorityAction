local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

local spells = {
    TigersFury = {
        Key = "1",
        Id = 5217,
        Buff = 5217,
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
        Id = 106832,
        Debuff = 106830,
    },
    Swipe = {
        Key = "9",
        Id = 213764,
    },
    -- talents
    BrutalSlash = {
        Key = "9",
        Id = 202028,
        TalentId = 21711,
    },
    PrimalWrath = {
        Key = "0",
        Id = 285381,
        TalentId = 22370,
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

    -- instance fields, init in Activate
    LocalEvents = nil, ---@type EventTracker
    RangeChecker = nil, ---@type Spell
    ComboCap = 4,

    -- locals
    CurrentPriorityList = nil, ---@type (fun():Spell)[]
    Stealhed            = IsStealthed(), -- UPDATE_STEALTH, IsStealthed()
    InRange             = false,
    Energy              = 0,
    EnergyDeficit       = 0,
    Combo               = 0,
    ComboDeficit        = 0,
    GcdReadyIn          = 0,
    CastingEndsIn       = 0,
    CCUnlockIn          = 0,
    SpellQueueWindow    = 0,
    InInstance          = false,
    InCombatWithTarget  = false,
    CanAttackTarget     = false,
    CanDotTarget        = false,
}

---@return Spell?
function feralRotation:RunPriorityList()
    for i, func in ipairs(self.CurrentPriorityList) do
        ---@type Spell
        local action = func()
        if (action) then
            if (action == self.EmptySpell) then
                return action
            end
            if (action:IsKnown()) then
                local usable, noMana = action:IsUsableNow()
                if (usable or noMana) then
                    return noMana and self.EmptySpell or action
                end
            end
        end
    end
    return nil
end

function feralRotation:Pulse()
    if not self.RangeChecker.Name or self:ShouldNotRun() then
        return self.EmptySpell
    end

    local selectedAction = nil

    self:Refresh()
    local now = self.Timestamp
    local playerBuffs = self.Player.Buffs
    local targetDebuffs = self.Player.Target.Debuffs
    if (playerBuffs:Applied(spells.CatForm.Buff)
        and self.InRange
        and self.CanAttackTarget
        and (not self.InInstance or self.InCombatWithTarget)
        and self.GcdReadyIn <= self.SpellQueueWindow
        and self.CastingEndsIn <= self.SpellQueueWindow
        )
    then
        if (not self.Settings.AOE) then
            selectedAction = self.Stealhed and self:StealthOpener():RunPriorityList() or self:SingleTarget():RunPriorityList()
        else
            selectedAction = self.Stealhed and self:StealthOpener():RunPriorityList() or self:Aoe():RunPriorityList()
        end
    end
    return selectedAction or self.EmptySpell
end

local stealthOpenerList
function feralRotation:StealthOpener()
    stealthOpenerList = stealthOpenerList or
        {
            function() return spells.Rake
            end,
        }
    self.CurrentPriorityList = stealthOpenerList
    return self
end

local singleTargetList
function feralRotation:SingleTarget()
    local settings = self.Settings
    local player = self.Player
    local target = self.Player.Target
    singleTargetList = singleTargetList or
        {
            function() if (self.EnergyDeficit > 55) then return spells.TigersFury end
            end,
            function() if (settings.Burst) then return spells.Berserk end
            end,
            function() if (self.CanDotTarget and self.Combo >= self.ComboCap and target.Debuffs:Remains(spells.Rip.Debuff) < 7.2) then return spells.Rip end
            end,
            function() if (self.Combo >= self.ComboCap) then if (self.Energy > 50) then return spells.FerociousBite else return self.EmptySpell end end
            end,
            function() if (player.Buffs:Applied(spells.ClearCasting.Buff)) then return spells.Shred end
            end,
            function() if (self.CanDotTarget and target.Debuffs:Remains(spells.Rake.Debuff) < 4.5) then return spells.Rake end
            end,
            function() if (self.Talents[spells.BrutalSlash.TalentId]) then return spells.BrutalSlash end
            end,
            function() return spells.Shred
            end,
        }
    self.CurrentPriorityList = singleTargetList
    return self
end

local aoeList
function feralRotation:Aoe()
    local settings = self.Settings
    local player = self.Player
    local target = self.Player.Target
    aoeList = aoeList or
        {
            function() if (self.EnergyDeficit > 55) then return spells.TigersFury end
            end,
            function() if (settings.Burst) then return spells.Berserk end
            end,
            function () if (self.Talents[spells.PrimalWrath.TalentId] and self.Combo >= self.ComboCap) then return spells.PrimalWrath end
            end,
            function() if (self.CanDotTarget and self.Combo >= self.ComboCap and target.Debuffs:Remains(spells.Rip.Debuff) < 7.2) then return spells.Rip end
            end,
            function() if (self.Combo >= self.ComboCap) then if (self.Energy > 50) then return spells.FerociousBite else return self.EmptySpell end end
            end,
            function() if (self.CanDotTarget and target.Debuffs:Remains(spells.Rake.Debuff) < 4.5) then return spells.Rake end
            end,
            function() if (target.Debuffs:Remains(spells.Thrash.Debuff) < 4.5) then return spells.Thrash end
            end,
            function() if (self.Talents[spells.BrutalSlash.TalentId]) then return spells.BrutalSlash else return spells.Swipe end
            end,
            function() return spells.Thrash -- dump energy when Slash is out ouf charges
            end,
        }
    self.CurrentPriorityList = aoeList
    return self
end

function feralRotation:Refresh()
    local player = self.Player
    local timestamp = self.Timestamp
    player.Buffs:Refresh(timestamp)
    player.Debuffs:Refresh(timestamp)
    player.Target.Buffs:Refresh(timestamp)
    player.Target.Debuffs:Refresh(timestamp)

    self.InRange = self.RangeChecker:IsInRange()
    self.Energy, self.EnergyDeficit = player:Resource(3)
    self.Combo, self.ComboDeficit = player:Resource(4)
    self.GcdReadyIn = player:GCDReadyIn()
    self.CastingEndsIn = player:CastingEndsIn()
    self.SpellQueueWindow = addon.SavedSettings.Instance.SpellQueueWindow
    self.InInstance = player:InInstance()
    self.InCombatWithTarget = player:InCombatWithTarget()
    self.CanAttackTarget = player:CanAttackTarget()
    self.CanDotTarget = player:CanDotTarget()
end

function feralRotation:Dispose()
    self.LocalEvents:Dispose()
end

function feralRotation:Activate()
    addon.Player.Buffs = addon.Initializer.NewAuraCollection("player", "PLAYER|HELPFUL")
    addon.Player.Debuffs = addon.Initializer.NewAuraCollection("player", "HARMFUL")
    addon.Player.Target.Buffs = addon.Initializer.NewAuraCollection("target", "HELPFUL")
    addon.Player.Target.Debuffs = addon.Initializer.NewAuraCollection("target", "PLAYER|HARMFUL")

    local handlers = {}
    local IsStealthed = IsStealthed
    function handlers.UPDATE_STEALTH(event, eventArgs)
        self.Stealhed = IsStealthed()
    end
    self.LocalEvents = addon.Initializer.NewEventTracker(handlers):RegisterEvents()
    self.RangeChecker = spells.Rake
    addon.Shared.RangeCheckSpell = self.RangeChecker
end

addon:AddRotation("DRUID", 2, spells, feralRotation)
