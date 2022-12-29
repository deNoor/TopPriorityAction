local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class Convenience
---@field ThanksBye fun(self:Convenience)

---@type Convenience
local Convenience = {}

local NewTicker, DoEmote = C_Timer.NewTicker, DoEmote
local thankByeEmotes = { "THANK", "BYE", }
function Convenience:ThanksBye()
    local i = 1
    NewTicker(
        2,
        function()
            DoEmote(thankByeEmotes[i], "player")
            i = i + 1
        end,
        #thankByeEmotes)
end

-- attach to addon
addon.Convenience = Convenience
