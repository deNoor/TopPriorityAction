local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class Convenience
---@field ThanksBye fun(self:Convenience, delay:number?)

---@type Convenience
local Convenience = {}

local C_Timer, DoEmote, tinsert = C_Timer, DoEmote, tinsert
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

-- attach to addon
addon.Convenience = Convenience
