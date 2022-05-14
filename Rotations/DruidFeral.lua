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
        Id = 202028,
    },
    PrimalWrath = {
        Key = "0",
        Id = 285381,
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

    -- locals
    Stealhed = IsStealthed(), -- UPDATE_STEALTH, IsStealthed()
    WowClass = addon.WowClass,
    InRange = false,
    Energy  = 0,
    EnergyDeficit = 0,
    Combo = 0,
    ComboDeficit = 0,
    GcdReadyIn = 0,
    CastingEndsIn = 0,
    CCUnlockIn = 0,
    SpellQueueWindow = 0,
    InInstance = false,
    InCombatWithTarget = false,
    CanAttackTarget = false,
    CanDotTarget = false,
}

---@param list (fun():Spell)[]
---@return Spell?
function feralRotation:RunPriorityList(list)
    for _, func in ipairs(list) do
        ---@type Spell
        local action = func()
        if(action and action == self.EmptySpell or (action:IsKnown() and action:IsUsableNow())) then
            return action
        end
    end
    return nil
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
        and self.CanAttackTarget
        and (not self.InInstance or self.InCombatWithTarget)
        and self.GcdReadyIn <= self.SpellQueueWindow
        and self.CastingEndsIn <= self.SpellQueueWindow
    )
    then
        if (not self.Settings.AOE) then
            selectedAction = self.Stealhed and self:StealthOpener():RunPriorityList() or self:SingleTarget():RunPriorityList()
        else
            selectedAction = self:Aoe():RunPriorityList()
        end
    end

    -- print("running feral")
    -- consider using CanCast or Empty here to counter most failed spams with a cheap check.
    return selectedAction or self.EmptySpell
end

function feralRotation:StealthOpener()
    return {
        function () return spells.Rake
        end,
    }
    

end

function feralRotation:SingleTarget()
    local burst = self.Settings.Burst
    local aoe = self.Settings.AOE
    local player = self.Player
    local target = self.Player.Target
    return {
        function () if (self.EnergyDeficit > 55) then return spells.TigersFury end
        end,
        function () if(burst) then return spells.Berserk end
        end,
        function () if(self.CanDotTarget and self.Combo > 4 and target.Debuffs:Remains(spells.Rip.Debuff) < 7.2) then return spells.Rip end
        end,
        function () if(self.Combo > 4) then return spells.FerociousBite end
        end,
        function () if(self.CanDotTarget and target.Debuffs:Remains(spells.Rake.Debuff) < 4.5) then return spells.Rake end
        end,
        function () return spells.BrutalSlash
        end,
        function () if(aoe and target.Debuffs:Remains(spells.Thrash.Debuff) < 3) then return spells.Thrash end
        end,
        function () if (not aoe) then return spells.Shred else return spells.Swipe end
        end,
    }
end

function feralRotation:Aoe()

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
end

addon:AddRotation("DRUID", 2, spells, feralRotation)
