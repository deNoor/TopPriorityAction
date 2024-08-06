local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@type table<string,Spell>
local spells = {
    DeathStrike = {
        Id = 49998,
    },
    DarkSuccor = {
        Id = 178819,
        Buff = 101568,
    },
    Obliterate = {
        Id = 49020,
    },
    KillingMachine = {
        Id = 51128,
        Buff = 51124,
    },
    FrostStrike = {
        Id = 49143,
    },
    UnleashedFrenzy = {
        Id = 376905,
        Buff = 376907,
    },
    IcyTalons = {
        Id = 194878,
        Buff = 194879,
    },
    HowlingBlast = {
        Id = 49184,
        Debuff = 195617,
    },
    Rime = {
        Id = 59057,
        Buff = 59052,
    },
    RemorselessWinter = {
        Id = 196770,
    },
    DeathAndDecay = {
        Id = 43265,
    },
    MindFreeze = {
        Id = 47528,
    },
    RaiseDead = {
        Id = 46585,
    },
    PillarOfFrost = {
        Id = 51271,
        Buff = 51271,
    },
    EmpowerRuneWeapon = {
        Id = 47568,
        Buff = 47568,
    },
}

local cmds = {
    Kick = {
        Name = "kick",
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
    Name                   = "DeathKnight-Frost",
    Spells                 = spells,
    Items                  = items,
    Cmds                   = cmds,
    RangeChecker           = spells.FrostStrike,
    -- locals
    InRange                = false,
    InChallenge            = false,
    InRaidFight            = false,
    InInstance             = false,
    RunicPower             = 0,
    RunicPowerDeficit      = 0,
    Runes                  = 0,
    RunesDeficit           = 0,
    NowCasting             = 0,
    CastingEndsIn          = 0,
    CCUnlockIn             = 0,
    ActionAdvanceWindow    = 0,
    MyHealthPercent        = 0,
    MyHealthPercentDeficit = 0,
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
            self:AutoAttack()
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
            function() if ((spells.UnleashedFrenzy.Known and player.Buffs:Remains(spells.UnleashedFrenzy.Buff) < max(self.FullGCDTime, 0.75)) or (spells.IcyTalons.Known and player.Buffs:Remains(spells.IcyTalons.Buff) < max(self.FullGCDTime, 0.75))) then return spells.FrostStrike end end,
            function() if (settings.AOE) then return spells.RemorselessWinter end end,
            function() if (settings.AOE) then return spells.DeathAndDecay end end,
            function() if (settings.Burst) then return spells.PillarOfFrost end end,
            function() if (settings.Burst and (not spells.PillarOfFrost.Known or player.Buffs:Applied(spells.PillarOfFrost.Buff)) and not player.Buffs:Applied(spells.EmpowerRuneWeapon.Buff)) then return spells.EmpowerRuneWeapon end end,
            function() if (settings.Burst) then return spells.RaiseDead end end,
            function() if (player.Buffs:Applied(spells.KillingMachine.Buff)) then return spells.Obliterate end end,
            function() if (target.Debuffs:Applied(spells.HowlingBlast.Debuff)) then return spells.HowlingBlast end end,
            function() if (self.Runes < 2) then return spells.FrostStrike end end,
            function() if (player.Buffs:Applied(spells.Rime.Buff)) then return spells.HowlingBlast end end,
            function() return spells.FrostStrike end,
            function() return spells.Obliterate end,
            function() if (player.Buffs:Applied(spells.DarkSuccor.Buff)) then return spells.DeathStrike end end,
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
            function() if (self.CmdBus:Find(cmds.Kick.Name) and ((self.CanAttackMouseover and spells.MindFreeze:IsInRange("mouseover") and mouseover:CanKick()) or (not self.CanAttackMouseover and self.CanAttackTarget and spells.MindFreeze:IsInRange("target") and target:CanKick()))) then return spells.MindFreeze end end,
        }
    return rotation:RunPriorityList(utilityList)
end

local autoAttackList
function rotation:AutoAttack()
    autoAttackList = autoAttackList or
        {
            function() if (self.GcdReadyIn > self.ActionAdvanceWindow and not spells.AutoAttack:IsQueued()) then return spells.AutoAttack end end,
        }
    return rotation:RunPriorityList(autoAttackList)
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

local C_ChallengeMode, IsEncounterInProgress = C_ChallengeMode, IsEncounterInProgress
local raidInstTypes = addon.Helper.ToHashSet({ "raid" })
local partyInstTypes = addon.Helper.ToHashSet({ "party" })
function rotation:UpdateChallenge()
    self.InChallenge = (self.Player:InInstance(partyInstTypes) and C_ChallengeMode.IsChallengeModeActive()) or false
    self.InRaidFight = (self.Player:InInstance(raidInstTypes) and IsEncounterInProgress()) or false
end

local IsStealthed = IsStealthed
function rotation:Refresh()
    local player = self.Player
    local timestamp = addon.Timestamp
    player.Buffs:Refresh(timestamp)
    player.Debuffs:Refresh(timestamp)
    player.Target.Buffs:Refresh(timestamp)
    player.Target.Debuffs:Refresh(timestamp)

    self.ActionAdvanceWindow = self.Settings.ActionAdvanceWindow
    self.InRange = self.RangeChecker:IsInRange()
    self.RunicPower, self.RunicPowerDeficit = player:Resource(Enum.PowerType.RunicPower)
    self.Runes, self.RunesDeficit = player:Resource(Enum.PowerType.Runes)
    self.MyHealthPercent, self.MyHealthPercentDeficit = player:HealthPercent()
    self.MyHealAbsorb = player:HealAbsorb()
    self.NowCasting, self.CastingEndsIn = player:NowCasting()
    self.FullGCDTime = player:FullGCDTime()
    self.InInstance = player:InInstance()
    self:UpdateChallenge()
    self.InCombatWithTarget = player.Target:InCombatWithMe()
    self.CanAttackTarget, self.CanAttackMouseover = player.Target:CanAttack(), player.Mouseover:CanAttack()
    self.CanDotTarget = player.Target:CanDot()
    self.WorthyTarget = player.Target:IsWorthy()
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

    return addon.Initializer.NewEventTracker(frameHandlers):RegisterEvents()
end

function rotation:SetLayout()
    local spells = self.Spells
    spells.DeathStrike.Key = "1"
    spells.FrostStrike.Key = "2"
    spells.Obliterate.Key = "3"
    spells.HowlingBlast.Key = "4"
    spells.PillarOfFrost.Key = "5"
    spells.EmpowerRuneWeapon.Key = "6"
    spells.RaiseDead.Key = "7"
    spells.DeathAndDecay.Key = "8"
    spells.RemorselessWinter.Key = "9"

    spells.MindFreeze.Key = "num4"

    spells.AutoAttack.Key = "num+"

    local equip = addon.Player.Equipment
    equip.Trinket14.Key = "num0"
    equip.Trinket13.Key = "num-"

    local items = self.Items
    items.Healthstone.Key = "num9"
end

addon:AddRotation("DEATHKNIGHT", 2, rotation)
