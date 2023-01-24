local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@type table<string,Spell>
local spells = {
    AutoAttack = addon.Common.Spells.AutoAttack,
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
    },
    SliceAndDice = {
        Id = 315496,
        Buff = 315496,
        Pandemic = 18 * 0.3
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
    Shiv = {
        Id = 5938,
    },
    AdrenalineRush = {
        Id = 13750,
        Buff = 13750,
        LoadedDice = 256171,
    },
    Vanish = {
        Id = 1856,
    },
    BladeFlurry = {
        Id = 13877,
        Buff = 13877,
    },
    KillingSpree = {
        Id = 51690,
    },
    Dreadblades = {
        Id = 343142,
        Debuff = 343142,
    },
    BladeRush = {
        Id = 271877,
    },
    Sepsis = {
        Id = 385408,
    },
    BetweenTheEyes = {
        Id = 315341,
    },
    GreenskinsWickers = {
        Id = 386823,
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
    SealFate = {
        Id = 14190,
    },
    ImprovedAmbush = {
        Id = 381620,
    },
    QuickDraw = {
        Id = 196938,
    },
    CrimsonVial = {
        Id = 185311,
    },
    Feint = {
        Id = 1966,
    },
    TricksOfTheTrade = {
        Id = 57934,
    },
    MarkedForDeath = {
        Id = 137619,
    },
    ThistleTea = {
        Id = 381623,
    },
    ShadowDance = {
        Id = 185313,
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
        Name = "feint"
    },
    Kick = {
        Name = "kick",
    }
}

---@type table<string,Item>
local items = addon.Common.Items

---@type Rotation
local rotation = {
    Name = "Rogue-Assassination",
    Spells = spells,
    Items = items,
    Cmds = cmds,

    RangeChecker  = spells.SinisterStrike,
    ComboFinisher = 5,
    ComboKidney   = 5,

    -- locals
    Stealhed               = IsStealthed(), -- UPDATE_STEALTH, IsStealthed()
    InRange                = false,
    Energy                 = 0,
    EnergyDeficit          = 0,
    Combo                  = 0,
    ComboDeficit           = 0,
    ComboFinisherAllowed   = false,
    ComboHolding           = false,
    GcdReadyIn             = 0,
    NowCasting             = 0,
    CastingEndsIn          = 0,
    CCUnlockIn             = 0,
    ActionAdvanceWindow    = 0,
    MyHealthPercent        = 0,
    MyHealthPercentDeficit = 0,
    MyHealAbsorb           = 0,
    InInstance             = false,
    InCombatWithTarget     = false,
    CanAttackTarget        = false,
    CanDotTarget           = false,
    TinyTarget             = false,
    ShortBursting          = false,
}

function rotation:SelectAction()
    self:Refresh()
    local playerBuffs = self.Player.Buffs
    local targetDebuffs = self.Player.Target.Debuffs
    self:Utility()
    if (self.CanAttackTarget and (not self.InInstance or self.InCombatWithTarget)) then
        if (self.InRange and self.Stealhed) then
            self:StealthOpener()
        end
        if (self.InRange) then
            self:AutoAttack()
            self:SingleTarget()
        end
    end
end

local stealthOpenerList
function rotation:StealthOpener()
    local player = self.Player
    stealthOpenerList = stealthOpenerList or
        {
            function() return self:RollTheBones() end,
            function() return self:SliceAndDice() end,
            function() return spells.Ambush end,
        }
    return rotation:RunPriorityList(stealthOpenerList)
end

local singleTargetList
function rotation:SingleTarget()
    local settings = self.Settings
    local player = self.Player
    local target = self.Player.Target
    local equip = player.Equipment
    singleTargetList = singleTargetList or
        {
            function() if (self.CmdBus:Find(cmds.Kick.Name) and target:CanKick()) then return spells.Kick end end,
            function() if (self.CmdBus:Find(cmds.Kidney.Name)) then return self:KidneyOnCommand() end end,
            function() if (settings.AOE and not self.ComboHolding and not player.Buffs:Applied(spells.BladeFlurry.Buff)) then return spells.BladeFlurry end end,
            function() if (not self.ComboHolding) then return self:UseTrinket() end end,
            function()
                if (settings.Burst and not self.ComboHolding and not self.ShortBursting and not player.Buffs:Applied(spells.AdrenalineRush.Buff))
                then return spells.KillingSpree
                end
            end,
            function() return self:RollTheBones() end,
            function() if (not self.ComboHolding) then return self:SliceAndDice() end end,
            function() if (self.Energy < 40 and not self.ComboHolding) then return spells.ThistleTea end end,
            function() if (target.Buffs:HasPurgeable() and not self.ShortBursting) then return spells.Shiv end end,
            function() if (settings.AOE and player.Buffs:Applied(spells.BladeFlurry.Buff) and not player.Buffs:Applied(spells.ShadowDance.Buff) and not player.Debuffs:Applied(spells.Dreadblades.Debuff) and not self.ShortBursting) then return spells.BladeRush end end,
            function() if (not settings.AOE and self.EnergyDeficit > 50 and not self.ShortBursting) then return spells.BladeRush end end,
            function() if (self.ComboFinisherAllowed) then return spells.BetweenTheEyes end end,
            function() if (self.ComboFinisherAllowed) then return spells.Dispatch end end,
            function() if (self.ComboDeficit > 3 and not target:IsTotem() and not self.ShortBursting) then return spells.MarkedForDeath end end,
            function() if (settings.Burst and not self.ComboHolding and (not spells.ImprovedAdrenalineRush.Known or self.ComboDeficit > 3) and not self:KillingSpreeSoon()) then return spells.AdrenalineRush end end,
            function() if (settings.Burst and not self.ComboHolding and self.ComboDeficit > 3 and not self:KillingSpreeSoon()) then return spells.Dreadblades end end,
            function() return spells.Ambush end,
            function() if (settings.Burst and not self.ComboHolding and self.InInstance and spells.Vanish:ReadyIn() <= self.GcdReadyIn and (not spells.TakeThemBySurprise.Known or not player.Buffs:Applied(spells.TakeThemBySurprise.Buff))) then return self:AwaitedVanishAmbush() end end,
            function() if (settings.Burst) then return spells.Sepsis end end,
            function() if (not settings.AOE or player.Buffs:Applied(spells.BladeFlurry.Buff)) then return spells.BladeRush end end,
            function() return self:PistolShot() end,
            function() if (settings.Burst and spells.ShadowDance.Known and spells.ShadowDance:ReadyIn() <= self.GcdReadyIn and not self:KillingSpreeSoon()) then return self:AwaitedShadowDance() end end,
            function() return spells.SinisterStrike end,
        }
    return rotation:RunPriorityList(singleTargetList)
end

local utilityList
function rotation:Utility()
    local player = self.Player
    local grievousWoundId = addon.Common.Spells.GrievousWound.Debuff
    utilityList = utilityList or
        {
            function() if (self.CmdBus:Find(cmds.Feint.Name)) then return spells.Feint end end,
            function() if (not self.ShortBursting and (self.MyHealthPercentDeficit > 35 or self.MyHealAbsorb > 0 or player.Debuffs:Applied(grievousWoundId))) then return spells.CrimsonVial end end,
            function() if (self.MyHealthPercentDeficit > 55) then return items.Healthstone end end,
        }
    return rotation:RunPriorityList(utilityList)
end

local autoAttackList
function rotation:AutoAttack()
    local
    autoAttackList = autoAttackList or
        {
            function() if (not spells.AutoAttack:IsQueued()) then return spells.AutoAttack end end,
        }
    return rotation:RunPriorityList(autoAttackList)
end

function rotation:AwaitedVanishAmbush()
    if (self.GcdReadyIn < 0.01 and self.Energy > 50) then
        return spells.Vanish
    else
        return self.EmptyAction
    end
end

function rotation:AwaitedShadowDance()
    if (self.Energy > 80 and self.GcdReadyIn < 0.05) then
        return spells.ShadowDance
    else
        return self.EmptyAction
    end
end

function rotation:SliceAndDice()
    if (self.Player.Buffs:Applied(spells.RollTheBones.GrandMelee)) then
        return nil
    end
    if (spells.SwiftSlasher.Known) then
        if (self.Player.Buffs:Remains(spells.SliceAndDice.Buff) < spells.SliceAndDice.Pandemic) then
            if (self.ComboDeficit > 0) then
                self.ComboFinisherAllowed = false
                return nil
            else
                return spells.SliceAndDice
            end
        end
        return nil
    end
    if (self.ComboFinisherAllowed and self.Player.Buffs:Remains(spells.SliceAndDice.Buff) < spells.SliceAndDice.Pandemic) then
        return spells.SliceAndDice
    end
    return nil
end

function rotation:PistolShot()
    if (spells.FanTheHammer.Known) then
        local stacks = self.Player.Buffs:Stacks(spells.PistolShot.Opportunity)
        if (self.Combo < 3 and stacks > 0 or stacks > 3) then
            return spells.PistolShot
        end
        return nil
    end
    if (self.Player.Buffs:Applied(spells.PistolShot.Opportunity)) then
        return spells.PistolShot
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
    133642, -- +stats
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

local activeRtb = {
    TrueBearing = false, -- CDR
    SkullAndCrossbones = false, -- 25% Double SS
    Broadside = false, -- 1 combo gen
    RuthlessPrecision = false, -- crit
    BuriedTreasure = false, -- energy regen
    GrandMelee = false, -- SnD increase and leech
}
---@return Spell?
function rotation:RollTheBones()
    if (self.ShortBursting) then
        return nil
    end

    if (spells.SwiftSlasher.Known and not self.Player.Buffs:Applied(spells.SliceAndDice.Buff)) then
        return nil
    end

    local rtb = spells.RollTheBones
    local buffs = self.Player.Buffs
    local inPandemic = false
    local count = 0
    for name, _ in pairs(activeRtb) do
        local id = rtb[name] or addon.Helper.Print("RollTheBones buff id is missing for", name)
        local aura = buffs:Find(id)
        if (aura and aura.FullDuration > 20 and aura.Remains > self.ActionAdvanceWindow) then
            activeRtb[name] = true
            count = count + 1
            inPandemic = inPandemic or aura.Remains < rtb.Pandemic
        else
            activeRtb[name] = false
        end
    end

    local reroll = function()
        if (count > 2) then
            return false
        elseif (activeRtb.TrueBearing or activeRtb.SkullAndCrossbones) then
            return false
        elseif (count > 1 and not (activeRtb.GrandMelee and activeRtb.BuriedTreasure)) then
            return false
        else
            return true
        end
    end

    if (reroll()) then
        return rtb
    end
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

---@param initialDuration number
---@return number
function rotation:ComboPandemic(initialDuration)
    return initialDuration * (1 + self.Combo) * 0.3
end

local max = max
---@return boolean
function rotation:FinisherAllowed()
    local comboFinisher = self.ComboFinisher
    if (spells.SummarilyDispatched.Known) then
        comboFinisher = 5
    elseif (spells.GreenskinsWickers.Known and spells.BetweenTheEyes:ReadyIn() <= self.GcdReadyIn) then
        comboFinisher = 5
    elseif (self.Player.Buffs:Applied(spells.RollTheBones.Broadside)) then
        comboFinisher = max(4, comboFinisher - 1)
    end
    return self.Combo >= comboFinisher
end

function rotation:ShortBurstEffects()
    local player = self.Player
    return player.Buffs:Applied(spells.ShadowDance.Buff) or player.Debuffs:Applied(spells.Dreadblades.Debuff) or player.Buffs:Applied(spells.Subterfuge.Buff)
end

local InCombatLockdown, GetMacroInfo, CreateMacro, EditMacro, GetNumGroupMembers, UnitExists, UnitGroupRolesAssigned, UnitNameUnmodified, pcall, UNKNOWNOBJECT = InCombatLockdown, GetMacroInfo, CreateMacro, EditMacro, GetNumGroupMembers, UnitExists, UnitGroupRolesAssigned, UnitNameUnmodified, pcall, UNKNOWNOBJECT
local tricksMacro = { Exists = false, Name = "TricksNamed", CurrentTank = "", PendingUpdate = false, }
function tricksMacro:Update()
    local spell = spells.TricksOfTheTrade
    if (InCombatLockdown()) then
        self.PendingUpdate = true
    else
        if (not tricksMacro.Exists) then
            if (not GetMacroInfo(self.Name)) then
                if (not pcall(CreateMacro, self.Name, "INV_Misc_QuestionMark", "#showtooltip " .. spell.Name, true)) then
                    addon.Helper.Print("Failed to create" .. self.Name .. "macro")
                else
                    self.Exists = true
                end
            else
                self.Exists = true
            end
        end
        if (self.Exists and spell.Known) then
            if (GetNumGroupMembers() > 0) then
                for i = 1, 4 do
                    local unit = "party" .. i
                    if (UnitExists(unit) and UnitGroupRolesAssigned(unit) == "TANK") then
                        local tankName = UnitNameUnmodified(unit)
                        if (tankName and tankName ~= UNKNOWNOBJECT and tankName ~= self.CurrentTank) then
                            local spellName = spell.Name
                            local macroText = "#showtooltip " .. spellName .. "\n/cast [@" .. tankName .. "] " .. spellName
                            if (pcall(EditMacro, self.Name, nil, nil, macroText)) then
                                self.CurrentTank = tankName
                                addon.Helper.Print(spellName, "on", tankName)
                            end
                            break;
                        end
                    end
                end
            end
        end
        self.PendingUpdate = false
    end
end

function rotation:Refresh()
    local player = self.Player
    local timestamp = self.Timestamp
    player.Buffs:Refresh(timestamp)
    player.Debuffs:Refresh(timestamp)
    player.Target.Buffs:Refresh(timestamp)
    player.Target.Debuffs:Refresh(timestamp)

    self.InRange = self.RangeChecker:IsInRange()
    self.Energy, self.EnergyDeficit = player:Resource(Enum.PowerType.Energy)
    self.Combo, self.ComboDeficit = player:Resource(Enum.PowerType.ComboPoints)
    self.ComboFinisherAllowed = self:FinisherAllowed()
    self.ComboHolding = false
    self.MyHealthPercent, self.MyHealthPercentDeficit = player:HealthPercent()
    self.MyHealAbsorb = player:HealAbsorb()
    self.GcdReadyIn = player:GCDReadyIn()
    self.NowCasting, self.CastingEndsIn = player:NowCasting()
    self.ActionAdvanceWindow = 50 / 1000
    self.InInstance = player:InInstance()
    self.InCombatWithTarget = player.Target:InCombatWithMe()
    self.CanAttackTarget = player.Target:CanAttack()
    self.CanDotTarget = player.Target:CanDot()
    self.TinyTarget = player.Target:IsTiny()
    self.ShortBursting = self:ShortBurstEffects()

    spells.SliceAndDice.Pandemic = self:ComboPandemic(6)
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
    tricksMacro:Update()
    self:SetLayout()
end

function rotation:CreateLocalEventTracker()
    local frameHandlers = {}

    local IsStealthed = IsStealthed
    function frameHandlers.UPDATE_STEALTH(event, ...)
        self.Stealhed = IsStealthed()
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
    spells.Eviscerate.Key = "4"
    spells.Dispatch.Key = spells.Eviscerate.Key
    spells.BetweenTheEyes.Key = "5"
    spells.RollTheBones.Key = "6"
    spells.AdrenalineRush.Key = "7"
    spells.BladeFlurry.Key = "8"
    spells.BladeRush.Key = "9"
    spells.Sepsis.Key = spells.BladeRush.Key

    spells.ThistleTea.Key = "s-1"
    spells.ShadowDance.Key = spells.ThistleTea.Key
    spells.MarkedForDeath.Key = "s-2"
    spells.Ambush.Key = "s-3"
    spells.KillingSpree.Key = "s-4"
    spells.Dreadblades.Key = spells.KillingSpree.Key
    spells.Shiv.Key = "s-6"
    spells.Feint.Key = "s-7"
    spells.KidneyShot.Key = "s-8"
    spells.Vanish.Key = "s-9"


    spells.Kick.Key = "F7"
    spells.CrimsonVial.Key = "F11"
    spells.AutoAttack.Key = "F12"

    local equip = addon.Player.Equipment
    equip.Trinket14.Key = "s-0"
    equip.Trinket13.Key = "s--"

    local items = self.Items
    items.Healthstone.Key = "s-="
end

addon:AddRotation("ROGUE", 2, rotation)
