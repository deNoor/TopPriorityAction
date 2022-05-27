local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@type table<string,Spell>
local spells = {
    TigersFury = {
        Id = 5217,
        Buff = 5217,
    },
    Rake = {
        Id = 1822,
        Debuff = 155722,
    },
    Shred = {
        Id = 5221,
    },
    FerociousBite = {
        Id = 22568,
    },
    Rip = {
        Id = 1079,
        Debuff = 1079,
    },
    Berserk = {
        Id = 106951,
        Buff = 106951,
    },
    Thrash = {
        Id = 106832,
        Debuff = 106830,
    },
    Swipe = {
        Id = 213764,
    },
    -- talents
    BrutalSlash = {
        Id = 202028,
        TalentId = 21711,
    },
    PrimalWrath = {
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
    Regrowth = {
        Id = 8936,
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
    Soothe = {
        Id = 2908,
    },
    RemoveCorruption = {
        Id = 2782,
    },
    -- Procs
    OmenOfClarity = {
        Id = 16864,
        Buff = 135700, -- Clear casting
    },
    PredatorySwiftness = {
        Id = 16974,
        Buff = 69369,
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
local feralRotation = {
    -- framework dependencies
    Timestamp      = 0,
    Settings       = nil,
    PauseTimestamp = 0,
    EmptyAction    = addon.Initializer.Empty.Action,
    Player         = addon.Player,

    -- instance fields, init nils in Activate
    LocalEvents      = nil, ---@type EventTracker
    RangeChecker     = nil, ---@type Spell
    ComboCap         = 4,
    DispellableTypes = addon.Helper:ToHashSet({ "Curse", "Poison", }),

    -- locals
    SelectedAction         = nil,
    CurrentPriorityList    = nil, ---@type (fun():Spell|Item)[]
    Stealhed               = IsStealthed(), -- UPDATE_STEALTH, IsStealthed()
    InRange                = false,
    Energy                 = 0,
    EnergyDeficit          = 0,
    Combo                  = 0,
    ComboDeficit           = 0,
    ManaPercent            = 0,
    GcdReadyIn             = 0,
    CastingEndsIn          = 0,
    CCUnlockIn             = 0,
    ActionAdvanceWindow    = 0,
    MyHealthPercent        = 0,
    MyHealthPercentDeficit = 0,
    InInstance             = false,
    InCombatWithTarget     = false,
    CanAttackTarget        = false,
    CanDotTarget           = false,
    LastCastSent           = 0,
    MouseoverIsFriend      = false,
    MouseoverIsEnemy       = false,
}

---@return Action?
function feralRotation:RunPriorityList()
    if (self.SelectedAction) then
        return self
    end
    for i, func in ipairs(self.CurrentPriorityList) do
        ---@type Action
        local action = func()
        if (action) then
            -- if (action == self.EmptyAction) then -- todo: remove block?
            --     self.SelectedAction = action
            --     return self
            -- end
            if (action:IsAvailable()) then
                local usable, noMana = action:IsUsableNow()
                if (usable or noMana) then
                    self.SelectedAction = noMana and self.EmptyAction or action
                    return self
                end
            end
        end
    end
    return self
end

function feralRotation:Pulse()
    if self:ShouldNotRun() then
        return self.EmptyAction
    end

    self.SelectedAction = nil
    self:Refresh()
    local now = self.Timestamp
    local playerBuffs = self.Player.Buffs
    local targetDebuffs = self.Player.Target.Debuffs
    if (playerBuffs:Applied(spells.CatForm.Buff)
        and self.InRange
        and self.CanAttackTarget
        and (not self.InInstance or self.InCombatWithTarget)
        -- and self.GcdReadyIn <= self.ActionAdvanceWindow
        and self.CastingEndsIn <= self.ActionAdvanceWindow
        )
    then
        self:Utility():RunPriorityList()
        if (self.Stealhed) then
            self:StealthOpener():RunPriorityList()
        end
        if (not self.Settings.AOE) then
            self:SingleTarget():RunPriorityList()
        else
            self:Aoe():RunPriorityList()
        end
    end
    self:ReduceActionSpam():WaitForOpportunity()
    return self.SelectedAction or self.EmptyAction
end

function feralRotation:ReduceActionSpam()
    local action = self.SelectedAction
    if (action and action:IsQueued()) then
        self.SelectedAction = self.EmptyAction
    end
    return self
end

function feralRotation:WaitForOpportunity()
    local action = self.SelectedAction
    local switch = {
        Empty = function() end,
        Spell = function()
            local spell = action ---@type Spell
            if (not spell.NoGCD and self.GcdReadyIn > self.ActionAdvanceWindow) then
                self.SelectedAction = self.EmptyAction
            end
        end,
        EquipItem = function()
            local item = action ---@type EquipItem|Item
            if (self.CastingEndsIn > 0) then
                self.SelectedAction = self.EmptyAction
            end
        end,
        Item = function()
            local item = action ---@type EquipItem|Item
            if (self.CastingEndsIn > 0) then
                self.SelectedAction = self.EmptyAction
            end
        end,
    }
    if (action) then
        local case = switch[action.Type]
        if (case) then
            case()
        else
            addon.Helper:Print({ "Indefined swith label", action.Type })
        end
    end
    return self
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
    local equip = player.Equipment
    singleTargetList = singleTargetList or
        {
            function() return spells.AdaptiveSwarm
            end,
            function() if (self.EnergyDeficit > 55) then return spells.TigersFury end
            end,
            function() if (equip.Trinket13:IsInRange("target")) then return equip.Trinket13 end
            end,
            function() if (settings.Burst) then return spells.ConvokeTheSpirits end
            end,
            function() if (settings.Burst) then return spells.Berserk end
            end,
            function() if (self.CanDotTarget and self.Combo >= self.ComboCap and target.Debuffs:Remains(spells.Rip.Debuff) < 7.2) then return spells.Rip end
            end,
            function() if (self.Combo >= self.ComboCap) then return spells.FerociousBite --[[ if (self.Energy > 50) then return spells.FerociousBite else return self.EmptyAction end ]] end
            end,
            function() if (self.CanDotTarget and target.Debuffs:Remains(spells.Rake.Debuff) < 4.5) then return spells.Rake end
            end,
            function() if (player.Buffs:Applied(spells.OmenOfClarity.Buff)) then return spells.Shred end
            end,
            function() if (player.Talents[spells.BrutalSlash.TalentId]) then return spells.BrutalSlash end
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
            function() return spells.AdaptiveSwarm
            end,
            function() if (self.EnergyDeficit > 55) then return spells.TigersFury end
            end,
            function() if (settings.Burst) then return spells.ConvokeTheSpirits end
            end,
            function() if (settings.Burst) then return spells.Berserk end
            end,
            function() if (player.Talents[spells.PrimalWrath.TalentId] and self.Combo >= self.ComboCap) then return spells.PrimalWrath end
            end,
            function() if (self.CanDotTarget and self.Combo >= self.ComboCap and target.Debuffs:Remains(spells.Rip.Debuff) < 7.2) then return spells.Rip end
            end,
            function() if (self.Combo >= self.ComboCap) then return spells.FerociousBite --[[ if (self.Energy > 50) then return spells.FerociousBite else return self.EmptyAction end ]] end
            end,
            function() if (self.CanDotTarget and target.Debuffs:Remains(spells.Rake.Debuff) < 4.5) then return spells.Rake end
            end,
            function() if (target.Debuffs:Remains(spells.Thrash.Debuff) < 4.5) then return spells.Thrash end
            end,
            function() if (player.Talents[spells.BrutalSlash.TalentId]) then return spells.BrutalSlash else return spells.Swipe end
            end,
            function() return spells.Thrash -- dump energy when Slash is out ouf charges
            end,
        }
    self.CurrentPriorityList = aoeList
    return self
end

local utilityList
function feralRotation:Utility()
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
            function() if (self.MyHealthPercentDeficit > 15 and player.Buffs:Remains(spells.PredatorySwiftness.Buff) > self.GcdReadyIn + 0.5 and not spells.Regrowth:IsQueued()) then return spells.Regrowth end
            end,
            function() if (settings.Dispel and spells.RemoveCorruption:IsInRange("mouseover") and CanDispel() and self.ManaPercent > 6.5) then
                    if (self.MouseoverIsFriend) then return spells.RemoveCorruption end
                    if (self.MouseoverIsEnemy) then return spells.Soothe end
                end
            end,
        }
    self.CurrentPriorityList = utilityList
    return self
end

local UnitIsFriend, UnitIsEnemy = UnitIsFriend, UnitIsEnemy
function feralRotation:Refresh()
    local player = self.Player
    local timestamp = self.Timestamp
    player.Buffs:Refresh(timestamp)
    player.Debuffs:Refresh(timestamp)
    player.Target.Buffs:Refresh(timestamp)
    player.Target.Debuffs:Refresh(timestamp)
    player.Mouseover.Buffs:Refresh(timestamp)
    player.Mouseover.Debuffs:Refresh(timestamp)

    self.InRange = self.RangeChecker:IsInRange("target")
    self.Energy, self.EnergyDeficit = player:Resource(3)
    self.Combo, self.ComboDeficit = player:Resource(4)
    self.ManaPercent = player:ResourcePercent(0)
    self.MyHealthPercent, self.MyHealthPercentDeficit = player:HealthPercent()
    self.GcdReadyIn = player:GCDReadyIn()
    self.CastingEndsIn = player:CastingEndsIn()
    self.ActionAdvanceWindow = self.Settings.ActionAdvanceWindow
    self.InInstance = player:InInstance()
    self.InCombatWithTarget = player:InCombatWithTarget()
    self.CanAttackTarget = player:CanAttackTarget()
    self.CanDotTarget = player:CanDotTarget()
    self.MouseoverIsFriend, self.MouseoverIsEnemy = UnitIsFriend("player", "mouseover"), UnitIsEnemy("player", "mouseover")
end

function feralRotation:SetLayout()
    local spells = self.Spells
    spells.TigersFury.Key = "1"
    spells.Rake.Key = "2"
    spells.Shred.Key = "3"
    spells.FerociousBite.Key = "4"
    spells.Rip.Key = "5"
    spells.AdaptiveSwarm.Key = "6"
    spells.ConvokeTheSpirits.Key = "6"
    spells.Berserk.Key = "7"
    spells.Thrash.Key = "8"
    spells.Swipe.Key = "9"
    spells.BrutalSlash.Key = "9"
    spells.PrimalWrath.Key = "0"
    spells.Regrowth.Key = "-"
    spells.Soothe.Key = "F6"
    spells.RemoveCorruption.Key = "F6"

    local equip = addon.Player.Equipment
    equip.Trinket13.Key = "F11"
end

function feralRotation:Dispose()
    self.LocalEvents:Dispose()
end

function feralRotation:Activate()
    addon.Player.Buffs = addon.Initializer.NewAuraCollection("player", "PLAYER|HELPFUL")
    addon.Player.Debuffs = addon.Initializer.NewAuraCollection("player", "HARMFUL")
    addon.Player.Target.Buffs = addon.Initializer.NewAuraCollection("target", "HELPFUL")
    addon.Player.Target.Debuffs = addon.Initializer.NewAuraCollection("target", "PLAYER|HARMFUL")
    addon.Player.Mouseover.Buffs = addon.Initializer.NewAuraCollection("mouseover", "HELPFUL")
    addon.Player.Mouseover.Debuffs = addon.Initializer.NewAuraCollection("mouseover", "RAID|HARMFUL")

    local handlers = {}
    local IsStealthed = IsStealthed
    function handlers.UPDATE_STEALTH(event, eventArgs)
        self.Stealhed = IsStealthed()
    end

    function handlers.UNIT_SPELLCAST_SENT(event, eventArgs)
        if (eventArgs[1] == "player") then
            self.LastCastSent = self.Timestamp
        end
    end

    addon.Initializer.NewEquipment()
    self.LocalEvents = addon.Initializer.NewEventTracker(handlers):RegisterEvents()
    self.RangeChecker = spells.Rake
    self:SetLayout()
end

addon:AddRotation("DRUID", 2, spells, items, feralRotation)
