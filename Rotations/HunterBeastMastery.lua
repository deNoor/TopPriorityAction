local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@type table<string,Spell>
local spells = {
    AutoShot = addon.Common.Spells.AutoShot,
    AutoAttack = addon.Common.Spells.AutoAttack,
    MendPet = {
        Id = 136,
    },
    Exhilaration = {
        Id = 109304,
    },
    KillCommand = {
        Id = 34026,
    },
    CobraShot = {
        Id = 193455,
        CobraSting = 392296,
    },
    BarbedShot = {
        Id = 217200,
        Buff = 246851,
        Debuff = 217200,
        PetBuff = 272790,
    },
    MultiShot = {
        Id = 2643,
        Buff = 268877,
    },
    BestialWrath = {
        Id = 19574,
    },
    CallOfTheWild = {
        Id = 359844,
    },
    KillShot = {
        Id = 53351,
    },
    CounterShot = {
        Id = 147362,
    },
    TranquilizingShot = {
        Id = 19801,
    },
    Misdirection = {
        Id = 34477,
    },
    HuntersMark = {
        Id = 257284,
        Debuff = 257284,
    },
    DireBeast = {
        Id = 120679,
    },
    DeathChakram = {
        Id = 375891,
    },
    Bloodshed = {
        Id = 321530,
    },
}

local cmds = {
    Kick = {
        Name = "kick",
    },
    PetFailed = {
        Name = "petfailed",
    },
}

---@type table<string,Item>
local items = addon.Common.Items

---@type Rotation
local rotation = {
    Name                    = "Hunter-BeastMastery",
    Spells                  = spells,
    Items                   = items,
    Cmds                    = cmds,
    RangeChecker            = spells.AutoShot,
    -- locals
    InRange                 = false,
    Focus                   = 0,
    FocusDeficit            = 0,
    NowCasting              = 0,
    CastingEndsIn           = 0,
    CCUnlockIn              = 0,
    ActionAdvanceWindow     = 0,
    MyHealthPercent         = 0,
    MyHealthPercentDeficit  = 0,
    MyHealAbsorb            = 0,
    FullGCDTime             = 0,
    HavePet                 = false,
    PetHealthPercent        = 0,
    PetHealthPercentDeficit = 0,
    InInstance              = false,
    InCombatWithTarget      = false,
    CanAttackTarget         = false,
    CanAttackMouseover      = false,
    CanDotTarget            = false,
    WorthyTarget            = false,
}

---@type TricksMacro
local tricksMacro

function rotation:SelectAction()
    self:Refresh()
    local playerBuffs = self.Player.Buffs
    local targetDebuffs = self.Player.Target.Debuffs
    self:Utility()
    if (self.CanAttackTarget and self.HavePet and (not self.InInstance or self.InCombatWithTarget)) then
        if (self.InRange) then
            self:AutoAttack()
            self:SingleTarget()
        end
    end
end

local GetAuraDataBySpellName, max = C_UnitAuras.GetAuraDataBySpellName, max
local singleTargetList
function rotation:SingleTarget()
    local settings = self.Settings
    local player = self.Player
    local pet = player.Pet
    local target = self.Player.Target
    local equip = player.Equipment
    singleTargetList = singleTargetList or
        {
            function() if (self.WorthyTarget and target:HealthPercent() > 80 and not GetAuraDataBySpellName("target", spells.HuntersMark.Name, "HARMFUL")) then return spells.HuntersMark end end,
            function() if (pet.Buffs:Remains(spells.BarbedShot.PetBuff) < max(self.FullGCDTime, 0.75)) then return spells.BarbedShot end end,
            function() if (self.Settings.AOE and self.Focus >= 40 and player.Buffs:Remains(spells.MultiShot.Buff) < max(self.FullGCDTime, 0.75)) then return spells.MultiShot end end,
            function() if (not self.CmdBus:Find(cmds.PetFailed.Name) and (self.Focus >= 30 or player.Buffs:Applied(spells.CobraShot.CobraSting)) and spells.KillCommand:ActiveCharges() > 1) then return spells.KillCommand end end,
            function() if (settings.Burst and not self.CmdBus:Find(cmds.PetFailed.Name)) then return spells.Bloodshed end end,
            function() if (settings.Burst) then return spells.BestialWrath end end,
            function() if (settings.Burst) then return spells.CallOfTheWild end end,
            function() if (settings.Burst) then return spells.DeathChakram end end,
            function() return spells.DireBeast end,
            function() if (spells.BarbedShot:ActiveCharges() > 1) then return spells.BarbedShot end end,
            function() if (not self.CmdBus:Find(cmds.PetFailed.Name) and (self.Focus >= 30 or player.Buffs:Applied(spells.CobraShot.CobraSting))) then return spells.KillCommand end end,
            function() return spells.BarbedShot end,
            function() return spells.KillShot end,
            function() if (not self.CmdBus:Find(cmds.PetFailed.Name)) then return spells.KillCommand end end,
            function() if (spells.KillCommand:ReadyIn() > 1 and self.Focus > 50) then return spells.CobraShot end end,
        }
    return rotation:RunPriorityList(singleTargetList)
end

local utilityList
function rotation:Utility()
    local settings = self.Settings
    local player = self.Player
    local target = player.Target
    local mouseover = player.Mouseover
    utilityList = utilityList or
        {
            function() if (self.MyHealthPercentDeficit > 55) then return items.Healthstone end end,
            function() if (self.CmdBus:Find(cmds.Kick.Name) and ((self.CanAttackMouseover and spells.CounterShot:IsInRange("mouseover") and mouseover:CanKick()) or (not self.CanAttackMouseover and self.CanAttackTarget and spells.CounterShot:IsInRange("target") and target:CanKick()))) then return spells.CounterShot end end,
            function() if (self.HavePet and self.PetHealthPercentDeficit > 40) then return spells.MendPet end end,
            function() if (self.MyHealthPercentDeficit > 65) then return spells.Exhilaration end end,
            function() if (settings.Dispel and ((self.CanAttackMouseover and spells.TranquilizingShot:IsInRange("mouseover") and mouseover.Buffs:HasPurgeable()) or (not self.CanAttackMouseover and self.CanAttackTarget and spells.TranquilizingShot:IsInRange("target") and target.Buffs:HasPurgeable()))) then return spells.TranquilizingShot end end,
        }
    return rotation:RunPriorityList(utilityList)
end

local autoAttackList
function rotation:AutoAttack()
    autoAttackList = autoAttackList or
        {
            function() if (not spells.AutoShot:IsAutoRepeat()) then return spells.AutoShot end end,
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
    local timestamp = addon.Timestamp
    player.Buffs:Refresh(timestamp)
    player.Debuffs:Refresh(timestamp)
    player.Pet.Buffs:Refresh(timestamp)
    -- player.Pet.Debuffs:Refresh(timestamp)
    player.Target.Buffs:Refresh(timestamp)
    player.Target.Debuffs:Refresh(timestamp)
    player.Mouseover.Buffs:Refresh(timestamp)

    self.InRange = self.RangeChecker:IsInRange()
    self.Focus, self.FocusDeficit = player:Resource(Enum.PowerType.Focus)
    self.MyHealthPercent, self.MyHealthPercentDeficit = player:HealthPercent()
    self.MyHealAbsorb = player:HealAbsorb()
    self.HavePet = player.Pet:Exists()
    self.PetHealthPercent, self.PetHealthPercentDeficit = player.Pet:HealthPercent()
    self.NowCasting, self.CastingEndsIn = player:NowCasting()
    self.FullGCDTime = player:FullGCDTime()
    self.ActionAdvanceWindow = self.Settings.ActionAdvanceWindow
    self.InInstance = player:InInstance()
    self.WorthyTarget = player.Target:IsWorthy()
    self.InCombatWithTarget = player.Target:InCombatWithMe()
    self.CanAttackTarget, self.CanAttackMouseover = player.Target:CanAttack(), player.Mouseover:CanAttack()
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
    tricksMacro = addon.Convenience:CreateTricksMacro("MisdirectNamed", spells.Misdirection)
    tricksMacro:Update()
    self:SetLayout()
end

function rotation:CreateLocalEventTracker()
    local frameHandlers = {}

    function frameHandlers.GROUP_ROSTER_UPDATE(event, ...)
        tricksMacro:Update()
    end

    function frameHandlers.PLAYER_REGEN_ENABLED(event, ...)
        if (tricksMacro.PendingUpdate) then
            tricksMacro:Update()
        end
    end

    local petAbilities = addon.Helper.ToHashSet({
        spells.KillCommand.Id,
        spells.Bloodshed.Id,
    })
    function frameHandlers.UNIT_SPELLCAST_FAILED(event, ...)
        local unit, castGUID, spellID = ...
        if (unit == "player" and petAbilities[spellID]) then
            self.CmdBus:Add(cmds.PetFailed.Name, 2)
        end
    end

    function frameHandlers.UI_ERROR_MESSAGE(event, ...)
        local errorType, message = ...
    end

    return addon.Initializer.NewEventTracker(frameHandlers):RegisterEvents()
end

function rotation:SetLayout()
    local spells = self.Spells
    spells.KillShot.Key = "1"
    spells.BarbedShot.Key = "2"
    spells.CobraShot.Key = "3"
    spells.KillCommand.Key = "4"
    spells.DireBeast.Key = "5"
    spells.CallOfTheWild.Key = "6"
    spells.BestialWrath.Key = "7"
    spells.MultiShot.Key = "8"
    spells.DeathChakram.Key = "9"
    spells.Bloodshed.Key = "0"

    -- spells.CounterShot.Key = "F7"
    spells.HuntersMark.Key = "num1"
    spells.CounterShot.Key = "num4"
    spells.TranquilizingShot.Key = "num5"
    spells.MendPet.Key = "num6"
    spells.Exhilaration.Key = "num7"
    spells.AutoShot.Key = "num+"

    local equip = addon.Player.Equipment
    equip.Trinket14.Key = "num0"
    equip.Trinket13.Key = "num-"

    local items = self.Items
    items.RaidRune.Key = "num8"
    items.Healthstone.Key = "num9"
end

addon:AddRotation("HUNTER", 1, rotation)
