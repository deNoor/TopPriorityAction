local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction
local pairs, ipairs = pairs, ipairs

---@type table<string,Spell>
local spells = {
    SinisterStrike = {
        Id = 1752,
    },
    Kick = {
        Id = 1766,
    },
    PistolShot = {
        Id = 185763,
        Opportunity = 195627,
    },
    HiddenOpportunity = {
        Id = 383281,
    },
    Ambush = {
        Id = 8676,
        Audacity = 386270,
    },
    Eviscerate = {
        Id = 196819,
    },
    Dispatch = {
        Id = 2098,
    },
    SummarilyDispatched = {
        Id = 381990,
        Buff = 386868,
    },
    SliceAndDice = {
        Id = 315496,
        Buff = 315496,
        Pandemic = 18 * 0.3,
    },
    RollTheBones = {
        Id = 315508,
        Pandemic = 30 * 0.3,
        TrueBearing = 193359,
        SkullAndCrossbones = 199603,
        Broadside = 193356,
        RuthlessPrecision = 193357,
        BuriedTreasure = 199600,
        GrandMelee = 193358,
    },
    KeepItRolling = {
        Id = 381989,
    },
    Shiv = {
        Id = 5938,
    },
    AdrenalineRush = {
        Id = 13750,
        Buff = 13750,
    },
    LoadedDice = {
        Id = 256170,
        Buff = 256171,
    },
    Stealth = {
        Id = 1784,
        Buff1 = 1784,
        Buff2 = 115191,
    },
    Vanish = {
        Id = 1856,
        Buff = 11327,
    },
    BladeFlurry = {
        Id = 13877,
        Buff = 13877,
    },
    KillingSpree = {
        Id = 51690,
    },
    BladeRush = {
        Id = 271877,
    },
    Sepsis = {
        Id = 385408,
    },
    GhostlyStrike = {
        Id = 196937,
        Debuff = 196937,
    },
    BetweenTheEyes = {
        Id = 315341,
        Buff = 315341,
    },
    ImprovedBetweenTheEyes = {
        Id = 235484,
    },
    DeftManeuvers = {
        Id = 381878,
    },
    UnderhandedUpperHand = {
        Id = 424044,
    },
    Crackshot = {
        Id = 423703,
    },
    GreenskinsWickers = {
        Id = 386823,
        Buff = 394131,
    },
    FanTheHammer = {
        Id = 381846,
    },
    TakeThemBySurprise = {
        Id = 382742,
        Buff = 385907,
    },
    SwiftSlasher = {
        Id = 381988,
    },
    ImprovedAdrenalineRush = {
        Id = 395422,
    },
    Subterfuge = {
        Id = 108208,
        Buff = 115192,
    },
    ImprovedAmbush = {
        Id = 381620,
    },
    CrimsonVial = {
        Id = 185311,
    },
    Feint = {
        Id = 1966,
        Buff = 1966,
    },
    TricksOfTheTrade = {
        Id = 57934,
    },
    ThistleTea = {
        Id = 381623,
        Buff = 381623,
    },
    ColdBlood = {
        Id = 382245,
        Buff = 382245,
    },
    EchoingReprimand = {
        Id = 385616,
        Buff3 = 323559,
        Buff4 = 323560,
        Buff5 = 354838,
    },
    KidneyShot = {
        Id = 408,
    },
}

local cmds = {
    Kidney = {
        Name = "kidney",
    },
    Feint = {
        Name = "feint",
    },
    Kick = {
        Name = "kick",
    },
    CombatStealth = {
        Name = "combatstealth",
    },
    PistolShot = {
        Name = "pistolshot",
    },
    KeepItRolling = {
        Name = "keepitrolling",
    },
    RollTheBones = {
        Name = "rollthebones",
    },
    AdrenalineRush = {
        Name = "adrenalinerush",
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
    Name                   = "Rogue-Outlaw",
    Spells                 = spells,
    Items                  = items,
    Cmds                   = cmds,
    RangeChecker           = spells.SinisterStrike,
    ComboFinisher          = 6,
    ComboKidney            = 4,
    ReducedComboWaste      = true,
    -- locals
    InStealth              = false,
    InStealthStance        = false,
    StealthBuffs           = false,
    InRange                = false,
    InChallenge            = false,
    InRaidFight            = false,
    InInstance             = false,
    Energy                 = 0,
    EnergyDeficit          = 0,
    Combo                  = 0,
    ComboDeficit           = 0,
    FanTheHammerTicks      = 0,
    ComboFinisherAllowed   = false,
    ComboEchoing           = false,
    ComboHolding           = false,
    NowCasting             = 0,
    CastingEndsIn          = 0,
    CCUnlockIn             = 0,
    ActionAdvanceWindow    = 0,
    MyHealthPercent        = 0,
    MyHealthPercentDeficit = 0,
    MyHealAbsorb           = 0,
    InCombatWithTarget     = false,
    CanAttackTarget        = false,
    CanAttackMouseover     = false,
    CanDotTarget           = false,
    WorthyTarget           = false,
    NanoBursting           = false,
    ShortBursting          = false,
    CombatStealthSent      = false,
    DFS4Set                = false,
}

---@type TricksMacro
local tricksMacro

local UnitInVehicle = UnitInVehicle
function rotation:SelectAction()
    self:Refresh()
    local playerBuffs = self.Player.Buffs
    local targetDebuffs = self.Player.Target.Debuffs
    if (not UnitInVehicle("player")) then
        self:Utility()
    end
    if ((not self.InInstance or self.InCombatWithTarget)) then
        if (self.CanAttackTarget and self.InRange and self.InStealth) then
            self:StealthOpener()
        end
        if (self.CanAttackTarget and self.InRange) then
            self:AutoAttack()
            self:SingleTarget()
        end
    end
end

local stealthOpenerList
function rotation:StealthOpener()
    local settings = self.Settings
    local player = self.Player
    local target = self.Player.Target
    stealthOpenerList = stealthOpenerList or
        {
            function() if (spells.KeepItRolling.Known) then return self:KeepItRolling() end end,
            function() return self:SliceAndDice() end,
            function() if (settings.Burst and not player.Buffs:Applied(spells.AdrenalineRush.Buff) and (not spells.ImprovedAdrenalineRush.Known or (self.Combo < 4 and self.GcdReadyIn <= 0.1))) then return spells.AdrenalineRush end end,
            function() if (spells.RollTheBones.Known) then return self:RollTheBones() end end,
            function() if (spells.Crackshot.Known and self.ComboFinisherAllowed) then return self:BetweenTheEyes() end end,
            function() if (not spells.Crackshot.Known and player.Buffs:Applied(spells.Ambush.Audacity)) then return spells.SinisterStrike end end,
            function() if (not spells.Crackshot.Known) then return spells.Ambush end end,
            function() if (not spells.Crackshot.Known) then return self.EmptyAction end end,
        }
    return rotation:RunPriorityList(stealthOpenerList)
end

local singleTargetList
function rotation:SingleTarget()
    local settings = self.Settings
    local player = self.Player
    local target = self.Player.Target
    local mouseover = player.Mouseover
    local equip = player.Equipment
    singleTargetList = singleTargetList or
        {
            function() if (spells.KeepItRolling.Known) then return self:KeepItRolling() end end,
            function() if (settings.Burst and not player.Buffs:Applied(spells.AdrenalineRush.Buff) and (not spells.ImprovedAdrenalineRush.Known or (self.Combo < 4 and self.GcdReadyIn <= 0.1))) then return spells.AdrenalineRush end end,
            function() if (spells.RollTheBones.Known) then return self:RollTheBones() end end,
            function() return self:AwaitCombatStealth() end,
            function() if (settings.AOE and not player.Buffs:Applied(spells.BladeFlurry.Buff)) then return spells.BladeFlurry end end,
            function() if (not self.ComboHolding and not self.StealthBuffs) then return self:UseTrinket() end end,
            function() if (spells.BladeRush.Known and settings.AOE and player.Buffs:Applied(spells.BladeFlurry.Buff) and not self.ShortBursting) then return spells.BladeRush end end,
            function() if (not self.ComboHolding) then return self:SliceAndDice() end end,
            function() if (spells.ThistleTea.Known and settings.Burst and self.Energy < 50 and not player.Buffs:Applied(spells.ThistleTea.Buff) and not self.ComboHolding) then return spells.ThistleTea end end,
            function() if (target.Buffs:HasPurgeable() and not self.ShortBursting) then return spells.Shiv end end,
            function() if (not self.ComboFinisherAllowed and spells.GhostlyStrike.Known and settings.Burst and self.WorthyTarget and not target.Debuffs:Applied(spells.GhostlyStrike.Debuff)) then return spells.GhostlyStrike end end,
            function() if (not self.ComboFinisherAllowed and settings.AOE and spells.DeftManeuvers.Known) then return spells.BladeFlurry end end,
            function() if (not self.ComboFinisherAllowed and spells.ImprovedAdrenalineRush.Known and settings.Burst and self.ShortBursting and self.Combo < 3 and self.GcdReadyIn < 0.2) then return spells.AdrenalineRush end end,
            function() if (not self.ComboFinisherAllowed and spells.EchoingReprimand.Known and settings.Burst) then return spells.EchoingReprimand end end,
            function() if (not self.ComboFinisherAllowed and spells.BladeRush.Known and not player.Buffs:Applied(spells.PistolShot.Opportunity) and self.Energy < 45) then return spells.BladeRush end end,
            function() if (not self.ComboFinisherAllowed and spells.HiddenOpportunity.Known and self.ShortBursting and (self.Energy < 45 or (player.Buffs:Applied(spells.RollTheBones.Broadside) and self.Combo < 2))) then return self:PistolShot() end end,
            function() if (not self.ComboFinisherAllowed and player.Buffs:Applied(spells.Ambush.Audacity)) then return spells.SinisterStrike end end,
            function() if (not self.ComboFinisherAllowed and spells.HiddenOpportunity.Known) then return spells.Ambush end end,
            function() if (not self.ComboFinisherAllowed and (spells.HiddenOpportunity.Known or ((self.Combo < (player.Buffs:Applied(spells.RollTheBones.Broadside) and 2 or 4)) or player.Buffs:Stacks(spells.PistolShot.Opportunity) > 3))) then return self:PistolShot() end end,
            function() if (not self.ComboFinisherAllowed and not spells.Crackshot.Known and spells.HiddenOpportunity.Known and settings.Burst and settings.Dispel and not self.ShortBursting --[[ and self.InInstance ]] and not self.ComboHolding and spells.Vanish:ReadyIn() <= self.GcdReadyIn) then return self:AwaitedVanish(85) end end,
            function() if (not self.ComboFinisherAllowed) then return spells.SinisterStrike end end,

            function() if (spells.KillingSpree.Known and settings.Burst and self.ComboFinisherAllowed and not self.ShortBursting) then return spells.KillingSpree end end,
            function() if (self.ComboFinisherAllowed) then return self:BetweenTheEyes() end end,
            function() if (spells.Crackshot.Known and settings.Burst and settings.Dispel and not self.ShortBursting --[[ and self.InInstance ]] and self.ComboFinisherAllowed and spells.Vanish:ReadyIn() <= self.GcdReadyIn and spells.BetweenTheEyes:ReadyIn() <= self.GcdReadyIn and player.Buffs:Applied(spells.SliceAndDice.Buff) and player.Buffs:Applied(spells.AdrenalineRush.Buff)) then return self:AwaitedVanish(85) end end,
            function() if (self.ComboFinisherAllowed) then return spells.Dispatch end end,
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
            function() if (not self.ShortBursting and self.CmdBus:Find(cmds.Feint.Name) and not player.Buffs:Applied(spells.Feint.Buff)) then return spells.Feint end end,
            function() if (not self.ShortBursting and (self.MyHealthPercentDeficit > 65 or self.MyHealAbsorb > 0 or player.Debuffs:Applied(gashFrenzyId))) then return spells.CrimsonVial end end,
            function() if (self.CmdBus:Find(cmds.Kick.Name) and not self.InStealth and not self.CombatStealthSent and ((self.CanAttackMouseover and spells.Kick:IsInRange("mouseover") and mouseover:CanKick()) or (not self.CanAttackMouseover and self.CanAttackTarget and spells.Kick:IsInRange("target") and target:CanKick()))) then return spells.Kick end end,
            function() if (self.CmdBus:Find(cmds.Kidney.Name) and not self.InStealth and not self.CombatStealthSent and ((self.CanAttackMouseover and spells.KidneyShot:IsInRange("mouseover")) or (not self.CanAttackMouseover and self.CanAttackTarget and spells.KidneyShot:IsInRange("target")))) then return self:KidneyOnCommand() end end,
            function() if (not self.InStealthStance) then return self:AutoStealth() end end,
            function() if (self.DFS4Set and (self.InChallenge or self.InRaidFight) and spells.RollTheBones.Known) then return self:RollTheBones() end end,
            function() if ((self.InChallenge or self.InRaidFight) and player.Buffs:Remains(items.RaidRune.Buff) < 60 * 5) then return items.RaidRune end end,
        }
    return rotation:RunPriorityList(utilityList)
end

local autoAttackList
function rotation:AutoAttack()
    autoAttackList = autoAttackList or
        {
            function() if (not self.StealthBuffs and not self.CombatStealthSent and self.GcdReadyIn > self.ActionAdvanceWindow and not spells.AutoAttack:IsQueued()) then return spells.AutoAttack end end,
        }
    return rotation:RunPriorityList(autoAttackList)
end

---@return Spell?
function rotation:AutoStealth()
    if (self.InChallenge or self.Settings.Stealth) then
        return spells.Stealth
    end
end

function rotation:ExpectCombatStealth()
    self.CmdBus:Add(self.Cmds.CombatStealth.Name, 0.4)
end

function rotation:AwaitedVanish(energy)
    if (self.Energy >= energy and self.GcdReadyIn < 0.05 and not self.InStealthStance) then
        return spells.Vanish
    else
        return self.EmptyAction
    end
end

function rotation:AwaitCombatStealth()
    if (self.CombatStealthSent and not self.InStealthStance) then return self.EmptyAction end
end

function rotation:SliceAndDice()
    if (self.Combo > 4 and self.Player.Buffs:Remains(spells.SliceAndDice.Buff) < 12) then
        return spells.SliceAndDice
    end
    return nil
end

function rotation:PistolShot()
    if (spells.FanTheHammer.Known) then
        if (self.CmdBus:Find(self.Cmds.PistolShot.Name)) then
            return nil
        end
        if (self.Player.Buffs:Stacks(spells.PistolShot.Opportunity) > 0) then
            return spells.PistolShot
        end
        return nil
    end
    if (self.Player.Buffs:Applied(spells.PistolShot.Opportunity)) then
        return spells.PistolShot
    end
    return nil
end

function rotation:BetweenTheEyes()
    local player = self.Player
    local buffs = self.Player.Buffs
    if (spells.Crackshot.Known) then
        if ((self.InStealthStance and (self.ShortBursting or self.StealthBuffs)) or (self.InRaidFight and spells.Vanish:ReadyIn() > 45)) then
            return spells.BetweenTheEyes
        end
        return nil
    end
    if (spells.GreenskinsWickers.Known or (spells.ImprovedBetweenTheEyes.Known and not spells.SummarilyDispatched.Known) or (buffs:Remains(spells.BetweenTheEyes.Buff) < 3)) then
        return spells.BetweenTheEyes
    end
    return nil
end

function rotation:KillingSpreeSoon()
    return spells.KillingSpree.Known and spells.KillingSpree:ReadyIn() <= self.GcdReadyIn
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

local max, min = max, min
local dice = {
    Broadside = false,          -- 1 combo gen
    SkullAndCrossbones = false, -- 25% Double SS
    TrueBearing = false,        -- CDR
    RuthlessPrecision = false,  -- crit
    BuriedTreasure = false,     -- energy regen
    GrandMelee = false,         -- damage and flurry damage
}
local kirMode = false
---@return Spell?
function rotation:RollTheBones()
    if (self.NanoBursting or self.CombatStealthSent) then
        return nil
    end
    if (self.CmdBus:Find(self.Cmds.KeepItRolling.Name)) then
        return nil
    end

    local rtb = spells.RollTheBones
    local buffs = self.Player.Buffs
    local longestRemains = 0
    local totalCount = 0
    local rtbRemains = 0
    local rtbCount = 0
    for name, _ in pairs(dice) do
        local id = rtb[name] or addon.Helper.Print("RollTheBones buff id is missing for", name)
        local aura = buffs:Find(id)
        if (aura and buffs:Applied(id)) then
            totalCount = totalCount + 1
            longestRemains = max(longestRemains, aura.Remains)
            dice[name] = true
            if (aura.FullDuration > 20) then
                dice[name] = true
                rtbCount = rtbCount + 1
                rtbRemains = max(rtbRemains, aura.Remains)
            end
        else
            dice[name] = false
        end
    end

    local possibleMin = 1 + ((self.DFS4Set and totalCount > 0) and 1 or 0) + (buffs:Applied(spells.LoadedDice.Buff) and 1 or 0)

    local reroll = function()
        local minDuration = 2
        local refreshDuration = 3
        local stealthCdIn = 2
        if (longestRemains < ((self.ShortBursting or self.CombatStealthSent) and refreshDuration or minDuration)) then
            return true
        end
        if (self.ShortBursting or totalCount > 4) then
            return false
        end
        if (possibleMin > totalCount) then
            return true
        end
        if (longestRemains < refreshDuration + 6.3 and (self.StealthBuffs or (self.Settings.Burst and not self.CombatStealthSent and
                (spells.Vanish:ReadyIn() < stealthCdIn)))) then
            return true
        end
        if (spells.KeepItRolling.Known and longestRemains < 39 and kirMode and (not spells.LoadedDice.Known or buffs:Applied(spells.LoadedDice.Buff))) then
            return true
        end
        return false
    end

    if (reroll()) then
        return rtb
    end
    return nil
end

---@return Spell?
function rotation:KeepItRolling()
    if (self.CmdBus:Find(self.Cmds.RollTheBones.Name)) then
        return nil
    end
    local rtb = spells.RollTheBones
    local buffs = self.Player.Buffs
    local count = 0
    for name, _ in pairs(dice) do
        local id = rtb[name] or addon.Helper.Print("RollTheBones buff id is missing for", name)
        local aura = buffs:Find(id)
        if (aura and buffs:Applied(id)) then
            count = count + 1
        end
    end
    local desiredMin = 3 + (self.DFS4Set and 1 or 0);
    if (count >= desiredMin) then
        return spells.KeepItRolling
    end
    return nil
end

function rotation:KidneyOnCommand()
    local readyIn = spells.KidneyShot:ReadyIn()
    if (readyIn < 2) then
        if (self.Combo < self.ComboKidney) then
            self.ComboHolding = true
            self.ComboFinisherAllowed = false
            return nil
        end
        return (readyIn > self.ActionAdvanceWindow) and self.EmptyAction or spells.KidneyShot
    end
end

---@param perComboDuration number
---@param baseDuration number?
---@return number
function rotation:ComboPandemic(perComboDuration, baseDuration)
    baseDuration = baseDuration or perComboDuration
    return (baseDuration + perComboDuration * self.Combo) * 0.3
end

local max, min = max, min
---@return boolean
function rotation:FinisherAllowed()
    if (self.ComboEchoing) then
        return true
    end
    local comboMax = self.Combo + self.ComboDeficit
    local comboFinisher = max(5, min(self.ComboFinisher, comboMax))
    if (spells.Crackshot.Known) then
        if (self.InStealthStance) then
            comboFinisher = 5
        elseif (self.ReducedComboWaste and spells.HiddenOpportunity.Known) then
            local buffs = self.Player.Buffs
            if (buffs:Applied(spells.Ambush.Audacity) or buffs:Applied(spells.PistolShot.Opportunity)) then
                comboFinisher = 5
            end
        else
            comboFinisher = comboFinisher
        end
    end
    return self.Combo >= comboFinisher
end

local echoBuffs = {
    [3] = spells.EchoingReprimand.Buff3,
    [4] = spells.EchoingReprimand.Buff4,
    [5] = spells.EchoingReprimand.Buff5,
}
---@return boolean
function rotation:ComboEcho()
    if (not spells.EchoingReprimand.Known) then
        return false
    end
    local combo = self.Combo
    if (3 <= combo and combo <= 5) then
        local buffId = echoBuffs[combo] or addon.Helper.Print("EchoingReprimand buff id is missing for", combo)
        return self.Player.Buffs:Applied(buffId)
    end
    return false
end

local max, min = max, min
function rotation:Predictions()
    if (spells.Vanish:IsQueued()) then
        self:ExpectCombatStealth()
    end
    if (spells.FanTheHammer.Known and self.CmdBus:Find(self.Cmds.PistolShot.Name)) then
        local maxCombo = self.Combo + self.ComboDeficit
        local incCombo = (self.FanTheHammerTicks * (self.Player.Buffs:Applied(spells.RollTheBones.Broadside) and 2 or 1))
        self.Combo = min(self.Combo + incCombo, maxCombo)
        self.ComboDeficit = maxCombo - self.Combo
    end
    if (spells.ImprovedAdrenalineRush.Known and (spells.AdrenalineRush:IsQueued() or self.CmdBus:Find(self.Cmds.AdrenalineRush.Name))) then
        local maxCombo = self.Combo + self.ComboDeficit
        self.Combo = maxCombo
        self.ComboDeficit = 0
    end
end

function rotation:BuffAppliedByGcdEnd(auraId)
    local buffs = self.Player.Buffs
    return buffs:Find(auraId).Remains > self.GcdReadyIn
end

function rotation:ShortBurstEffects()
    local player = self.Player
    return (player.Buffs:Applied(spells.Subterfuge.Buff) and rotation:BuffAppliedByGcdEnd(spells.Subterfuge.Buff))
end

function rotation:NanoBurstEffects()
    local player = self.Player
    return player.Buffs:Applied(spells.Vanish.Buff) and rotation:BuffAppliedByGcdEnd(spells.Vanish.Buff)
end

local GetShapeshiftForm = GetShapeshiftForm
function rotation:StealthStance()
    local stance = GetShapeshiftForm(true)
    return (stance and (stance == 1 or stance == 2))
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
    self.Energy, self.EnergyDeficit = player:Resource(Enum.PowerType.Energy)
    self.Combo, self.ComboDeficit = player:Resource(Enum.PowerType.ComboPoints)
    self.ComboHolding = false
    self.MyHealthPercent, self.MyHealthPercentDeficit = player:HealthPercent()
    self.MyHealAbsorb = player:HealAbsorb()
    self.NowCasting, self.CastingEndsIn = player:NowCasting()
    self.InInstance = player:InInstance()
    self:UpdateChallenge()
    self.InCombatWithTarget = player.Target:InCombatWithMe()
    self.CanAttackTarget, self.CanAttackMouseover = player.Target:CanAttack(), player.Mouseover:CanAttack()
    self.CanDotTarget = player.Target:CanDot()
    self.WorthyTarget = player.Target:IsWorthy()
    self.InStealth = IsStealthed()
    self.InStealthStance = self:StealthStance()
    self.StealthBuffs = player.Buffs:Applied(spells.Stealth.Buff1) or player.Buffs:Applied(spells.Stealth.Buff2)
    self:Predictions()
    self.NanoBursting = rotation:NanoBurstEffects()
    self.ShortBursting = self.NanoBursting or self:ShortBurstEffects()
    self.ComboEchoing = self:ComboEcho()
    self.ComboFinisherAllowed = self:FinisherAllowed()
    spells.SliceAndDice.Pandemic = self:ComboPandemic(6)
    self.CombatStealthSent = self.CmdBus:Find(cmds.CombatStealth.Name) ~= nil
    self.DFS4Set = player.Equipment:ActiveSetBonus(setBonus.DFS4.SetId, 4) or player.Equipment:ActiveSetBonus(setBonus.DFAmir.SetId, 4)
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
    tricksMacro = addon.Convenience:CreateTricksMacro("TricksNamed", spells.TricksOfTheTrade)
    tricksMacro:Update()
end

function rotation:CreateLocalEventTracker()
    local frameHandlers = {}

    local IsStealthed = IsStealthed
    function frameHandlers.UPDATE_STEALTH(event, ...)
        self.Stealthed = IsStealthed()
    end

    function frameHandlers.UPDATE_SHAPESHIFT_FORM(event, ...)
        self.InStealthStance = self:StealthStance()
    end

    local spellSentHandlers = {
        [spells.Vanish.Id] = function()
            self:ExpectCombatStealth()
        end,
        [spells.Stealth.Id] = function()
            self:ExpectCombatStealth()
        end,
        [spells.AdrenalineRush.Id] = function()
            if (spells.ImprovedAdrenalineRush.Known) then
                self.CmdBus:Add(self.Cmds.AdrenalineRush.Name, 0.2)
            end
        end,
        [spells.KeepItRolling.Id] = function()
            self.CmdBus:Add(self.Cmds.KeepItRolling.Name, 0.2)
        end,
        [spells.RollTheBones.Id] = function()
            self.CmdBus:Add(self.Cmds.RollTheBones.Name, 0.2)
        end,
    }
    function frameHandlers.UNIT_SPELLCAST_SENT(event, unit, target, castGUID, spellID)
        if (unit == "player") then
            local spellHandler = spellSentHandlers[spellID]
            if (spellHandler) then
                spellHandler()
            end
        end
    end

    local min = min
    local spellSucceededHandlers = {
        [spells.PistolShot.Id] = function()
            if (spells.FanTheHammer.Known) then
                if (not self.CmdBus:Find(self.Cmds.PistolShot.Name)) then
                    self.FanTheHammerTicks = min(self.Player.Buffs:Stacks(spells.PistolShot.Opportunity), 2)
                    self.CmdBus:Add(self.Cmds.PistolShot.Name, 0.7)
                else
                    if (self.FanTheHammerTicks > 0) then
                        self.FanTheHammerTicks = self.FanTheHammerTicks - 1
                    else
                        self.CmdBus:Remove(self.Cmds.PistolShot.Name)
                    end
                end
            end
        end,
        [spells.KeepItRolling.Id] = function()
            kirMode = true
        end,
        [spells.RollTheBones.Id] = function()
            kirMode = false
        end,
    }
    function frameHandlers.UNIT_SPELLCAST_SUCCEEDED(event, unit, castGUID, spellID)
        if (unit == "player") then
            local spellHandler = spellSucceededHandlers[spellID]
            if (spellHandler) then
                spellHandler()
            end
        end
    end

    function frameHandlers.GROUP_ROSTER_UPDATE(event, ...)
        tricksMacro:Update()
    end

    function frameHandlers.PLAYER_REGEN_ENABLED(event, ...)
        if (tricksMacro.PendingUpdate) then
            tricksMacro:Update()
        end
    end

    return addon.Initializer.NewEventTracker(frameHandlers):RegisterEvents()
end

function rotation:SetLayout()
    local spells = self.Spells
    spells.SliceAndDice.Key = "1"
    spells.PistolShot.Key = "2"
    spells.SinisterStrike.Key = "3"
    -- spells.Ambush.Key = spells.SinisterStrike.Key
    spells.Eviscerate.Key = "4"
    spells.Dispatch.Key = spells.Eviscerate.Key
    spells.BetweenTheEyes.Key = "5"
    spells.RollTheBones.Key = "6"
    spells.AdrenalineRush.Key = "7"
    spells.BladeFlurry.Key = "8"
    spells.BladeRush.Key = "9"
    spells.CrimsonVial.Key = "0"
    spells.Feint.Key = "-"
    spells.GhostlyStrike.Key = "="

    spells.KillingSpree.Key = "num1"
    spells.Vanish.Key = "num2"
    spells.Stealth.Key = "num3"
    spells.Kick.Key = "num4"
    spells.KidneyShot.Key = "num5"
    spells.Ambush.Key = "num6"
    spells.EchoingReprimand.Key = spells.Ambush.Key
    spells.KeepItRolling.Key = "num7"

    spells.AutoAttack.Key = "num+"

    local equip = addon.Player.Equipment
    equip.Trinket14.Key = "num0"
    equip.Trinket13.Key = "num-"

    local items = self.Items
    items.RaidRune.Key = "num8"
    items.Healthstone.Key = "num9"
end

addon:AddRotation("ROGUE", 2, rotation)
