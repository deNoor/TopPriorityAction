local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction
local pairs, ipairs, min, max = pairs, ipairs, min, max

---@type table<string,Spell>
local spells = {
    DrainLife = {
        Id = 234153,
    },
    ShadowBolt = {
        Id = 686,
    },
    HandOfGuldan = {
        Id = 105174,
    },
    Demonbolt = {
        Id = 264178,
    },
    DemonicCore = {
        Id = 267102,
        Buff = 264173,
    },
    CallDreadstalkers = {
        Id = 104316,
        TimeLeft = 0.0,
    },
    DemonicCalling = {
        Id = 205145,
        Buff = 205146,
    },
    Implosion = {
        Id = 196277,
    },
    DemonicStrength = {
        Id = 267171,
    },
    SummonDemonicTyrant = {
        Id = 265187,
    },
    SummonVilefiend = {
        Id = 264119,
    },
    SummonFelguard = {
        Id = 30146,
    },
    PowerSiphon = {
        Id = 264130,
    },
    GrimoireFelguard = {
        Id = 111898,
    },
    Guillotine = {
        Id = 386833,
    },
    CommandDemon = {
        Id = 119898,
    },
    HealthFunnel = {
        Id = 755,
    },
    PactOfGluttony = {
        Id = 386689,
    },
}

local cmds = {
    Kick = {
        Name = "kick",
    },
    PetFailed = {
        Name = "petfailed",
    },
    ImpFailed = {
        Name = "impfailed",
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
items.DemonicHealthstone = {
    Id = 224464,
}

---@type Rotation
local rotation = {
    Name                    = "Warlock-Demonology",
    Spells                  = spells,
    Items                   = items,
    Cmds                    = cmds,
    RangeChecker            = spells.DrainLife,
    -- locals
    InRange                 = false,
    InChallenge             = false,
    InRaidFight             = false,
    InInstance              = false,
    Mana                    = 0,
    ManaDeficit             = 0,
    Shards                  = 0,
    ShardsDeficit           = 0,
    NowCasting              = 0,
    CastingEndsIn           = 0,
    CCUnlockIn              = 0,
    ActionAdvanceWindow     = 0,
    MyHealthPercent         = 0,
    MyHealthPercentDeficit  = 0,
    PetHealthPercent        = 0,
    PetHealthPercentDeficit = 0,
    TargetHealthPercent     = 0,
    MyHealAbsorb            = 0,
    FullGCDTime             = 0,
    InCombatWithTarget      = false,
    CanAttackTarget         = false,
    CanAttackMouseover      = false,
    CanDotTarget            = false,
    WorthyTarget            = false,
    HavePet                 = false,
    PetIsJammed             = false,
    ImpIsJammed             = false,
    Imps                    = 0,
    TwoSecCastTime          = 2.0,
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
        if (self.CanAttackTarget and self.InRange and self.HavePet and self.PetHealthPercent > 0) then
            self:SingleTarget()
        end
    end
end

local singleTargetList
function rotation:SingleTarget()
    local settings = self.Settings
    local player = self.Player
    local target = self.Player.Target
    local mouseover = player.Mouseover
    local equip = player.Equipment
    local totems = player.Totems
    singleTargetList = singleTargetList or
        {
            function() if (not player.IsMoving and settings.Burst) then return self:SummonDemonicTyrant() end end,
            function() if (settings.Burst and (not spells.SummonVilefiend.Known or (totems:Active(spells.SummonVilefiend.Icon) or self.NowCasting == spells.SummonVilefiend.Id))) then return spells.GrimoireFelguard end end,
            function() if (not player.IsMoving and settings.Burst) then return spells.SummonVilefiend end end,
            function() if ((not player.IsMoving or player.Buffs:Applied(spells.DemonicCalling.Buff)) and settings.Burst) then return spells.CallDreadstalkers end end,
            function() if (not self.PetIsJammed and settings.Burst) then return spells.DemonicStrength end end,
            function() if (not self.PetIsJammed and settings.Burst) then return spells.Guillotine end end,
            function() if (not self.ImpIsJammed and self.Imps >= 2 and player.Buffs:Stacks(spells.DemonicCore.Buff) <= 2) then return spells.PowerSiphon end end,
            function() if (not self.ImpIsJammed and settings.AOE and self.Imps >= 6) then return spells.Implosion end end,
            function() if (not player.IsMoving and self.Shards >= 3) then return spells.HandOfGuldan end end,
            function() if (self.ShardsDeficit >= 2 and player.Buffs:Applied(spells.DemonicCore.Buff)) then return spells.Demonbolt end end,
            function() if (not player.IsMoving and self.ShardsDeficit >= 1) then return spells.ShadowBolt end end,
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
            function() if (self.MyHealthPercentDeficit > 78) then return spells.PactOfGluttony.Known and items.DemonicHealthstone or items.Healthstone end end,
            -- function() if (self.CmdBus:Find(cmds.Kick.Name) and ((self.CanAttackMouseover and spells.Conterspell:IsInRange("mouseover") and mouseover:CanKick()) or (not self.CanAttackMouseover and self.CanAttackTarget and spells.Conterspell:IsInRange("target") and target:CanKick()))) then return spells.Conterspell end end,
            function() if (not self.PetIsJammed and not player.IsMoving and self.HavePet and self.PetHealthPercent > 0 and self.PetHealthPercentDeficit > 40) then return spells.HealthFunnel end end,
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
            if (not self.WorthyTarget) then
                return nil
            end
        end
        return burstTrinket
    end
    return nil
end

function rotation:SummonDemonicTyrant()
    local totems = self.Player.Totems
    local minDesiredTime = self.TwoSecCastTime + 0.3
    local totemCallTime = self.FullGCDTime * 2 + minDesiredTime

    local vilefiendLeft = self.NowCasting == spells.SummonVilefiend.Id and 15 or totems:Remains(spells.SummonVilefiend.Icon)
    local dreadstalkersLeft = self.NowCasting == spells.CallDreadstalkers.Id and 12 or totems:Remains(spells.CallDreadstalkers.Icon)
    local grimoireLeft = totems:Remains(spells.GrimoireFelguard.Icon)

    if (spells.SummonVilefiend.Known) then
        if (vilefiendLeft < minDesiredTime) then
            return nil
        end
        local maxWaitLeft = (grimoireLeft >= minDesiredTime and min(vilefiendLeft, grimoireLeft) or vilefiendLeft) - totemCallTime
        local grimoireSoon = spells.GrimoireFelguard.Known and grimoireLeft < minDesiredTime and spells.GrimoireFelguard:ReadyIn() <= maxWaitLeft
        local dreadstalkersSoon = spells.CallDreadstalkers.Known and dreadstalkersLeft < minDesiredTime and spells.CallDreadstalkers:ReadyIn() <= maxWaitLeft
        local summonTyrant = vilefiendLeft < 4 or not (grimoireSoon or dreadstalkersSoon)
        if (summonTyrant) then
            return spells.SummonDemonicTyrant
        end
        return nil
    elseif (spells.SummonFelguard.Known) then
        local skipGrimoire = spells.GrimoireFelguard:ReadyIn() > 60
        if (skipGrimoire) then
            if (dreadstalkersLeft >= minDesiredTime) then
                return spells.SummonDemonicTyrant
            end
            return nil
        else
            if (grimoireLeft < minDesiredTime) then
                return nil
            end
            local maxWaitLeft = grimoireLeft - totemCallTime
            local dreadstalkersSoon = spells.CallDreadstalkers.Known and dreadstalkersLeft < minDesiredTime and spells.CallDreadstalkers:ReadyIn() <= maxWaitLeft
            local summonTyrant = grimoireLeft < 4 or not dreadstalkersSoon
            if (summonTyrant) then
                return spells.SummonDemonicTyrant
            end
            return nil
        end
    elseif (spells.CallDreadstalkers.Known) then
        if (dreadstalkersLeft < minDesiredTime) then
            return nil
        end
        local summonTyrant = (self.Imps > 6 and not self.Settings.AOE) or dreadstalkersLeft < 4
        if (summonTyrant) then
            return spells.SummonDemonicTyrant
        end
        return nil
    elseif (self.Imps > 6 and not self.Settings.AOE) then
        return spells.SummonDemonicTyrant
    end
    return nil
end

function rotation:Predictions()
    local castingSpellId = self.NowCasting
    ---@param amount integer
    local function ShiftShardsCount(amount)
        local shardsMax = self.Shards + self.ShardsDeficit;
        self.Shards = min(self.Shards + amount, shardsMax)
        self.ShardsDeficit = shardsMax - self.Shards
    end
    if (castingSpellId == spells.Demonbolt.Id) then
        ShiftShardsCount(2)
    end
    if (castingSpellId == spells.ShadowBolt.Id) then
        ShiftShardsCount(1)
    end
    if (castingSpellId == spells.HandOfGuldan.Id) then
        ShiftShardsCount(-3)
    end
    if (castingSpellId == spells.CallDreadstalkers.Id) then
        ShiftShardsCount(-2)
    end
    if (castingSpellId == spells.SummonVilefiend.Id) then
        ShiftShardsCount(-1)
    end
    if (castingSpellId == spells.SummonFelguard.Id) then
        ShiftShardsCount(-1)
    end
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
    player.Totems:Refresh(timestamp)

    self.ActionAdvanceWindow = self.Settings.ActionAdvanceWindow
    self.InRange = self.RangeChecker:IsInRange()
    self.Mana, self.ManaDeficit = player:Resource(Enum.PowerType.Mana)
    self.Shards, self.ShardsDeficit = player:Resource(Enum.PowerType.SoulShards)
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
    self.HavePet = player.Pet:Exists()
    self.PetHealthPercent, self.PetHealthPercentDeficit = player.Pet:HealthPercent()
    self.Player.IsMoving = IsPlayerMoving() or self.CmdBus:Find(cmds.StoppedMoving.Name) ~= nil
    self.PetIsJammed = self.CmdBus:Find(cmds.PetFailed.Name) ~= nil
    self.ImpIsJammed = self.CmdBus:Find(cmds.ImpFailed.Name) ~= nil
    self.Imps = spells.Implosion:CastCount()
    self.TwoSecCastTime = player:HastedSpellCastTime(2)
    self:Predictions()
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

    local petAbilities = addon.Helper.ToHashSet({
        spells.DemonicStrength.Id,
        spells.HealthFunnel.Id,
        spells.Guillotine.Id,
    })
    local impAbilities = addon.Helper.ToHashSet({
        spells.Implosion.Id,
        spells.PowerSiphon.Id,
    })
    function frameHandlers.UNIT_SPELLCAST_FAILED(event, ...)
        local unit, castGUID, spellID = ...
        if (unit == "player") then
            if (petAbilities[spellID]) then
                self.CmdBus:Add(cmds.PetFailed.Name, 2)
            end
            if (impAbilities[spellID]) then
                self.CmdBus:Add(cmds.ImpFailed.Name, 2)
            end
        end
    end

    return addon.Initializer.NewEventTracker(frameHandlers):RegisterEvents()
end

function rotation:SetLayout()
    local spells = self.Spells
    spells.CallDreadstalkers.Key = "1"
    spells.ShadowBolt.Key = "2"
    spells.HandOfGuldan.Key = "3"
    spells.Demonbolt.Key = "4"
    spells.SummonVilefiend.Key = "5"
    spells.DemonicStrength.Key = "6"
    spells.SummonDemonicTyrant.Key = "7"
    spells.Implosion.Key = "8"

    spells.PowerSiphon.Key = "num1"
    spells.GrimoireFelguard.Key = "num2"
    spells.HealthFunnel.Key = "num6"

    local equip = addon.Player.Equipment
    equip.Trinket14.Key = "num0"
    equip.Trinket13.Key = "num-"

    local items = self.Items
    items.Healthstone.Key = "num9"
    items.DemonicHealthstone.Key = items.Healthstone.Key
end

addon:AddRotation("WARLOCK", 2, rotation)
