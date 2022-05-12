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
    Timestamp = 0, -- updated by framework on Pulse call.
    EmptySpell = nil, -- updated by framework on init.
    Player = addon.Player, -- updated by framework on init.
}

function feralRotation:Pulse()
    self:Refresh()
    
    return self.EmptySpell
end

function feralRotation:Refresh()
    local player = self.Player
    local timestamp = self.Timestamp
    player.Buffs:Refresh(timestamp)
    player.Debuffs:Refresh(timestamp)
    player.Target.Buffs:Refresh(timestamp)
    player.Target.Debuffs:Refresh(timestamp)
end

addon.Player.Buffs = addon.Initializer.NewAuraCollection("player", "PLAYER|HELPFUL")
addon.Player.Debuffs = addon.Initializer.NewAuraCollection("player", "HARMFUL")
addon.Player.Target.Buffs = addon.Initializer.NewAuraCollection("target", "HELPFUL")
addon.Player.Target.Debuffs = addon.Initializer.NewAuraCollection("target", "PLAYER|HARMFUL")

addon.WowClass:AddRotation("DRUID", 2, spells, feralRotation)
