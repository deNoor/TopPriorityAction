local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class Convenience
---@field ThanksBye fun(self:Convenience, delay:number?)
---@field CreateTricksMacro fun(self:Convenience, name:string, spell:Spell):TricksMacro
---@field UserAction fun(self:Convenience):PlayerAction?
---@field EnableAutoConfirmDelete fun(self:Convenience)
---@field EnableHiddenPendingTicket fun(self:Convenience)
---@field DisableActionBarGlow fun(self:Convenience)

---@type Convenience
local Convenience = {}

local C_Timer, DoEmote, tinsert, hooksecurefunc = C_Timer, DoEmote, tinsert, hooksecurefunc
local emoteList = { "CONGRATULATE", "THANK", "BYE", }
local betweenEmotesSec = 3

local pending = false
local currentTicker = nil
local taskList = {}
for index, emote in ipairs(emoteList) do
    tinsert(taskList, function() DoEmote(emote, "player") end)
end
tinsert(taskList, function()
    if (currentTicker) then
        currentTicker:Cancel()
    end
    currentTicker = nil
    pending = false
end)

function Convenience:ThanksBye(delay)
    delay = delay or 0
    if (not pending) then
        pending = true
        C_Timer.After(delay, function()
            if (not currentTicker) then
                local i = 1
                currentTicker = C_Timer.NewTicker(
                    betweenEmotesSec,
                    function()
                        taskList[i]()
                        i = i + 1
                    end,
                    #taskList)
            end
        end)
    end
    C_Timer.After(delay + #taskList * betweenEmotesSec + 1, function() pending = false end)
end

---@class TricksMacro
---@field private Exists boolean
---@field private Name string
---@field private Spell Spell
---@field private CurrentTank string
---@field private PendingUpdate boolean
---@field Update fun(self:TricksMacro)

function Convenience:CreateTricksMacro(name, spell)
    local InCombatLockdown, GetMacroInfo, CreateMacro, EditMacro, GetNumGroupMembers, UnitExists, UnitGroupRolesAssigned, UnitNameUnmodified, pcall, UNKNOWNOBJECT = InCombatLockdown, GetMacroInfo, CreateMacro, EditMacro, GetNumGroupMembers, UnitExists, UnitGroupRolesAssigned, UnitNameUnmodified, pcall, UNKNOWNOBJECT
    local tricksMacro = { Exists = false, Name = name, Spell = spell, CurrentTank = "", PendingUpdate = false, }
    function tricksMacro:Update()
        if (InCombatLockdown()) then
            self.PendingUpdate = true
        else
            if (not tricksMacro.Exists) then
                if (not GetMacroInfo(self.Name)) then
                    if (not pcall(CreateMacro, self.Name, "INV_Misc_QuestionMark", "#showtooltip " .. (self.Spell.Name or ""), true)) then
                        addon.Helper.Print("Failed to create", self.Name, "macro")
                    else
                        addon.Helper.Print("Created macro", self.Name)
                        self.Exists = true
                    end
                else
                    self.Exists = true
                end
            end
            if (self.Exists and self.Spell.Known) then
                if (GetNumGroupMembers() > 0) then
                    for i = 1, 4 do
                        local unit = "party" .. i
                        if (UnitExists(unit) and UnitGroupRolesAssigned(unit) == "TANK") then
                            local tankName = UnitNameUnmodified(unit)
                            if (tankName and tankName ~= UNKNOWNOBJECT and tankName ~= self.CurrentTank) then
                                local spellName = self.Spell.Name
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

    return tricksMacro
end

function Convenience:UserAction()
    local cmdBus = addon.CmdBus
    local customKeyCommand = addon.Common.Commands.CustomKey
    local userKeyCommand = cmdBus:Find(customKeyCommand.Name)
    if (userKeyCommand and userKeyCommand.Arg1) then
        return userKeyCommand.Arg1
    end
    return nil
end

function Convenience:EnableAutoConfirmDelete()
    local InCombatLockdown = InCombatLockdown
    local cmdBus = addon.CmdBus
    local customKeyCommand = addon.Common.Commands.CustomKey
    local enterKey = addon.Common.PlayerActions.EnterKey
    local attachToPopupWindow = function(window)
        hooksecurefunc(window, "OnUpdate", function(dialog)
            if (not InCombatLockdown()) then
                if (dialog.button1:IsEnabled()) then
                    cmdBus:Add(customKeyCommand.Name, 0.1, enterKey)
                end
            end
        end)
        hooksecurefunc(window, "OnHide", function(dialog)
            cmdBus:Remove(customKeyCommand.Name)
        end)
        window.enterClicksFirstButton = true
    end
    local popupIds = {
        "DELETE_ITEM",
        "DELETE_QUEST_ITEM",
        "DELETE_GOOD_ITEM",
        "DELETE_GOOD_QUEST_ITEM"
    }
    for _, id in ipairs(popupIds) do
        attachToPopupWindow(StaticPopupDialogs[id])
    end
end

function Convenience:EnableHiddenPendingTicket()
    HelpOpenWebTicketButton:HookScript("OnShow", function(frame) frame:Hide() end)
    TicketStatusFrame:HookScript("OnShow", function(frame) frame:Hide() end)
end

local GetActionInfo = GetActionInfo
local noGlowActionTypes = addon.Helper.ToHashSet({ "spell", "macro", })
function Convenience:DisableActionBarGlow()
    hooksecurefunc("ActionButton_ShowOverlayGlow", function(button)
        local spellType, id, subType = GetActionInfo(button.action)
        if (noGlowActionTypes[spellType]) then
            if button.SpellActivationAlert and button.SpellActivationAlert.animOut then
                button.SpellActivationAlert.animOut:OnFinished()
            end
        end
    end)
end

-- attach to addon
addon.Convenience = Convenience
