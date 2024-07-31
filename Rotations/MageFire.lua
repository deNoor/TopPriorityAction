local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@type table<string,Spell>
local spells = {
    Frostbolt = {
        Id = 116,
    },
    Counterspell = {
        Id = 2139,
    },
    Fireball = {
        Id = 133,
    },
    Scorch = {
        Id = 2948,
    },
    FireBlast = {
        Id = 319836,
    },
    FireBlastPro = {
        Id = 108853,
    },
    Pyroblast = {
        Id = 11366,
    },
    Flamestrike = {
        Id = 2120,
    },
    PhoenixFlames = {
        Id = 257541,
    },
    ShiftingPower = {
        Id = 382440,
    },
    BlazingBarrier = {
        Id = 235313,
        Buff = 235313,
    },
    HotStreak = {
        Id = 195283,
        Semi = 48107,
        Full = 48108,
    },
    HeatShimmer = {
        Id = 457735,
        Buff = 458964,
    },
}

local cmds = {
    Kick = {
        Name = "kick",
    },
    StoppedMoving = {
        Name = "stroppedmoving",
    },
}

local setBonus = {
    DFAmir = {
        SetId = 1566,
    },
    DFS4 = {
        SetId = 1600,
    },
}

---@type table<string,Item>
local items = addon.Common.Items

---@type Rotation
local rotation = {
    Name                   = "Mage-Fire",
    Spells                 = spells,
    Items                  = items,
    Cmds                   = cmds,
    RangeChecker           = spells.Frostbolt,
    -- locals
    InRange                = false,
    InChallenge            = false,
    InRaidFight            = false,
    InInstance             = false,
    Mana                   = 0,
    ManaDeficit            = 0,
    NowCasting             = 0,
    CastingEndsIn          = 0,
    CCUnlockIn             = 0,
    ActionAdvanceWindow    = 0,
    MyHealthPercent        = 0,
    MyHealthPercentDeficit = 0,
    TargetHealthPercent    = 0,
    MyHealAbsorb           = 0,
    FullGCDTime            = 0,
    InCombatWithTarget     = false,
    CanAttackTarget        = false,
    CanAttackMouseover     = false,
    CanDotTarget           = false,
    WorthyTarget           = false,
}

local UnitInVehicle = UnitInVehicle
function rotation:SelectAction()
    self:Refresh()
    local playerBuffs = self.Player.Buffs
    local targetDebuffs = self.Player.Target.Debuffs
    if (not UnitInVehicle("player")) then
        self:Utility()
    end
    if ((not self.InInstance or self.InCombatWithTarget)) then
        if (self.CanAttackTarget and self.InRange) then
            self:SingleTarget()
        end
    end
end

local max = max
local singleTargetList
function rotation:SingleTarget()
    local settings = self.Settings
    local player = self.Player
    local target = self.Player.Target
    local mouseover = player.Mouseover
    local equip = player.Equipment
    singleTargetList = singleTargetList or
        {
            function() if (not settings.AOE and player.Buffs:Applied(spells.HotStreak.Full)) then return spells.Pyroblast end end,
            function() if (settings.AOE and player.Buffs:Applied(spells.HotStreak.Full) and self.CanAttackMouseover and self.RangeChecker:IsInRange("mouseover")) then return spells.Flamestrike end end,
            function() if (player.Buffs:Applied(spells.HotStreak.Semi)) then return spells.FireBlast end end,
            -- function() if (settings.Burst and not player.IsMoving) then return spells.ShiftingPower end end,
            function() if (not player.Buffs:Applied(spells.BlazingBarrier.Buff)) then return spells.BlazingBarrier end end,
            function() return spells.PhoenixFlames end,
            function() if (self.TargetHealthPercent <= 30 or player.Buffs:Applied(spells.HeatShimmer.Buff)) then return spells.Scorch end end,
            function() if (not player.IsMoving) then return spells.Fireball end end,
            function() return spells.Scorch end,
            -- function () return spells. end,
        }
    return rotation:RunPriorityList(singleTargetList)
end

local utilityList
function rotation:Utility()
    local player = self.Player
    local target = self.Player.Target
    local mouseover = player.Mouseover
    local gashFrenzyId = addon.Common.Spells.GashFrenzy.Debuff
    utilityList = utilityList or
        {
            function() if (self.MyHealthPercentDeficit > 78) then return items.Healthstone end end,
            function() if (self.CmdBus:Find(cmds.Kick.Name) and ((self.CanAttackMouseover and spells.Counterspell:IsInRange("mouseover") and mouseover:CanKick()) or (not self.CanAttackMouseover and self.CanAttackTarget and spells.Counterspell:IsInRange("target") and target:CanKick()))) then return spells.Counterspell end end,
        }
    return rotation:RunPriorityList(utilityList)
end

local aoeTrinkets = addon.Helper.ToHashSet({
    198451, -- 10y healing/damage aoe
})
local burstTrinkets = addon.Helper.ToHashSet({
    158319, -- Mydas, autoattacks more damage.
    198478, -- Dance Deck.
    212683, -- Globe of Jagged Ice, stacks frost damage and explodes.
    202610, -- Bomb Dispenser, delayed fire damage.
    194308, -- Grieftorch, channeled fire damage.
    207165, -- Bandolier, melee phys+shadowflame hit.
})
local danceTrinkets = {
    [198478] = {
        382860, -- Ace
        382866, -- 7
        382867, -- 8
    }
}

---@return EquipItem?
function rotation:UseTrinket()
    local equip = self.Player.Equipment
    ---@param trinket EquipItem
    ---@return EquipItem|nil
    local function AsReadyTrinket(trinket)
        return trinket:IsAvailable() and trinket:ReadyIn() <= self.GcdReadyIn and trinket or nil
    end
    local usableTrinket = AsReadyTrinket(equip.Trinket13) or AsReadyTrinket(equip.Trinket14)
    if not usableTrinket then
        return nil
    end
    ---@param ids integer[]
    ---@return EquipItem
    local trinketFrom = function(ids)
        return ids[usableTrinket.Id] and usableTrinket
    end
    local aoeTrinket = trinketFrom(aoeTrinkets)
    if (aoeTrinket and self.Settings.AOE) then
        return aoeTrinket
    end
    local burstTrinket = trinketFrom(burstTrinkets)
    if (burstTrinket and self.Settings.Burst) then
        if (danceTrinkets[burstTrinket.Id]) then
            for index, buff in ipairs(danceTrinkets[burstTrinket.Id]) do
                if (self.Player.Buffs:Applied(buff)) then
                    return burstTrinket
                end
            end
            return nil
        end
        if (burstTrinket.Id == 194308) then
            if (self.ShortBursting or not self.WorthyTarget) then
                return nil
            end
        end
        return burstTrinket
    end
    return nil
end

function rotation:BuffAppliedByGcdEnd(auraId)
    local buffs = self.Player.Buffs
    return buffs:Find(auraId).Remains > self.GcdReadyIn
end

local C_ChallengeMode, IsEncounterInProgress = C_ChallengeMode, IsEncounterInProgress
local raidInstTypes = addon.Helper.ToHashSet({ "raid" })
local partyInstTypes = addon.Helper.ToHashSet({ "party" })
function rotation:UpdateChallenge()
    self.InChallenge = (self.Player:InInstance(partyInstTypes) and C_ChallengeMode.IsChallengeModeActive()) or false
    self.InRaidFight = (self.Player:InInstance(raidInstTypes) and IsEncounterInProgress()) or false
end

local IsPlayerMoving = IsPlayerMoving
function rotation:Refresh()
    local player = self.Player
    local timestamp = addon.Timestamp
    player.Buffs:Refresh(timestamp)
    player.Debuffs:Refresh(timestamp)
    player.Target.Buffs:Refresh(timestamp)
    player.Target.Debuffs:Refresh(timestamp)

    self.ActionAdvanceWindow = self.Settings.ActionAdvanceWindow
    self.InRange = self.RangeChecker:IsInRange()
    self.Mana, self.ManaDeficit = player:Resource(Enum.PowerType.Mana)
    self.MyHealthPercent, self.MyHealthPercentDeficit = player:HealthPercent()
    self.TargetHealthPercent = player.Target:HealthPercent()
    self.MyHealAbsorb = player:HealAbsorb()
    self.NowCasting, self.CastingEndsIn = player:NowCasting()
    self.FullGCDTime = player:FullGCDTime()
    self.InInstance = player:InInstance()
    self:UpdateChallenge()
    self.InCombatWithTarget = player.Target:InCombatWithMe()
    self.CanAttackTarget, self.CanAttackMouseover = player.Target:CanAttack(), player.Mouseover:CanAttack()
    self.CanDotTarget = player.Target:CanDot()
    self.WorthyTarget = player.Target:IsWorthy()
    self.Player.IsMoving = IsPlayerMoving() or self.CmdBus:Find(cmds.StoppedMoving.Name) ~= nil
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
    self:SetLayout()
end

function rotation:CreateLocalEventTracker()
    local frameHandlers = {}

    function frameHandlers.PLAYER_STOPPED_MOVING(event, ...)
        self.CmdBus:Add(cmds.StoppedMoving.Name, 0.2)
    end

    return addon.Initializer.NewEventTracker(frameHandlers):RegisterEvents()
end

function rotation:SetLayout()
    local spells = self.Spells
    spells.Fireball.Key = "1"
    spells.FireBlast.Key = "2"
    spells.Scorch.Key = "3"
    spells.Pyroblast.Key = "4"
    spells.PhoenixFlames.Key = "5"
    spells.Flamestrike.Key = "8"
    spells.ShiftingPower.Key = "9"

    spells.Counterspell.Key = "num4"
    spells.BlazingBarrier.Key = "num7"

    local equip = addon.Player.Equipment
    equip.Trinket14.Key = "num0"
    equip.Trinket13.Key = "num-"

    local items = self.Items
    items.Healthstone.Key = "num9"
end

addon:AddRotation("MAGE", 2, rotation)
