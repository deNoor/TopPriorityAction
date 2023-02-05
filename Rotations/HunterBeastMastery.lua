local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@type table<string,Spell>
local spells = {
    AutoShot = addon.Common.Spells.AutoShot,
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
    },
    BarbedShot = {
        Id = 217200,
        Buff = 246851,
    },
    MultiShot = {
        Id = 2643,
    },
    KillShot = {
        Id = 53351,
    },
    CounterShot = {
        Id = 147362,
    },
    Misdirection = {
        Id = 34477,
    },
}

local cmds = {
    Kick = {
        Name = "kick",
    }
}

---@type table<string,Item>
local items = addon.Common.Items

---@type Rotation
local rotation = {
    Name = "Hunter-BeastMastery",
    Spells = spells,
    Items = items,
    Cmds = cmds,

    RangeChecker = spells.AutoShot,

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
    HavePet                 = false,
    PetHealthPercent        = 0,
    PetHealthPercentDeficit = 0,
    InInstance              = false,
    InCombatWithTarget      = false,
    CanAttackTarget         = false,
    CanDotTarget            = false,
}

function rotation:SelectAction()
    self:Refresh()
    local playerBuffs = self.Player.Buffs
    local targetDebuffs = self.Player.Target.Debuffs
    self:Utility()
    if (self.CanAttackTarget and (not self.InInstance or self.InCombatWithTarget)) then
        if (self.InRange) then

            -- self:AutoAttack()
            self:SingleTarget()
        end
    end
end

local singleTargetList
function rotation:SingleTarget()
    local settings = self.Settings
    local player = self.Player
    local target = self.Player.Target
    local equip = player.Equipment
    singleTargetList = singleTargetList or
        {
            function() if (self.CmdBus:Find(cmds.Kick.Name) and target:CanKick()) then return spells.CounterShot end end,
            function() return spells.KillShot end,
            function() if (self.FocusDeficit > 40) then return spells.BarbedShot end end,
            function() if (self.PetHealthPercent > 0) then return spells.KillCommand end end,
            function() if (not settings.AOE) then return spells.CobraShot else return spells.MultiShot end end,
            function() return spells.AutoShot end,
        }
    return rotation:RunPriorityList(singleTargetList)
end

local utilityList
function rotation:Utility()
    local player = self.Player
    local grievousWoundId = addon.Common.Spells.GrievousWound.Debuff
    utilityList = utilityList or
        {
            function() if (self.MyHealthPercentDeficit > 55) then return items.Healthstone end end,
            function() if (self.HavePet and self.PetHealthPercentDeficit > 50) then return spells.MendPet end end,
            function() if (self.MyHealthPercentDeficit > 65) then return spells.Exhilaration end end,
        }
    return rotation:RunPriorityList(utilityList)
end

local autoAttackList
function rotation:AutoAttack()
    autoAttackList = autoAttackList or
        {
            function() if (not spells.AutoShot:IsQueued()) then return spells.AutoShot end end,
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

local InCombatLockdown, GetMacroInfo, CreateMacro, EditMacro, GetNumGroupMembers, UnitExists, UnitGroupRolesAssigned, UnitNameUnmodified, pcall, UNKNOWNOBJECT = InCombatLockdown, GetMacroInfo, CreateMacro, EditMacro, GetNumGroupMembers, UnitExists, UnitGroupRolesAssigned, UnitNameUnmodified, pcall, UNKNOWNOBJECT
local tricksMacro = { Exists = false, Name = "MisdirectNamed", CurrentTank = "", PendingUpdate = false, }
function tricksMacro:Update()
    local spell = spells.Misdirection
    if (InCombatLockdown()) then
        self.PendingUpdate = true
    else
        if (not tricksMacro.Exists) then
            if (not GetMacroInfo(self.Name)) then
                if (not pcall(CreateMacro, self.Name, "INV_Misc_QuestionMark", "#showtooltip " .. (spell.Name or ""), true)) then
                    addon.Helper.Print("Failed to create", self.Name, "macro")
                else
                    addon.Helper.Print("Created macro", self.Name)
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
    self.Focus, self.FocusDeficit = player:Resource(Enum.PowerType.Focus)
    self.MyHealthPercent, self.MyHealthPercentDeficit = player:HealthPercent()
    self.MyHealAbsorb = player:HealAbsorb()
    self.PetHealthPercent, self.PetHealthPercentDeficit = player.Pet:HealthPercent()
    self.NowCasting, self.CastingEndsIn = player:NowCasting()
    self.ActionAdvanceWindow = self.Settings.ActionAdvanceWindow
    self.InInstance = player:InInstance()
    self.InCombatWithTarget = player.Target:InCombatWithMe()
    self.CanAttackTarget = player.Target:CanAttack()
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

    return addon.Initializer.NewEventTracker(frameHandlers):RegisterEvents()
end

function rotation:SetLayout()
    local spells = self.Spells
    spells.KillCommand.Key = "1"
    spells.KillShot.Key = "2"
    spells.CobraShot.Key = "3"
    spells.BarbedShot.Key = "4"
    spells.MultiShot.Key = "8"

    spells.CounterShot.Key = "F7"
    spells.MendPet.Key = "F10"
    spells.Exhilaration.Key = "F11"
    spells.AutoShot.Key = "F12"

    local equip = addon.Player.Equipment
    equip.Trinket14.Key = "s-0"
    equip.Trinket13.Key = "s--"

    local items = self.Items
    items.Healthstone.Key = "s-="
end

addon:AddRotation("HUNTER", 1, rotation)
