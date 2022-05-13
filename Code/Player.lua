local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class Player
---@field Talents integer[]
---@field DetectTalents fun(self:Player)
---@field Buffs AuraCollection
---@field Debuffs AuraCollection
---@field Target Target

---@class Target
---@field Buffs AuraCollection
---@field Debuffs AuraCollection

---@type Player
local Player = {
    Rotation = nil,
    Buffs = nil,
    Debuffs = nil,
    Target = {
        Buffs = nil,
        Debuffs = nil,
    },
    Talents = {},
}

function Player:DetectTalents()
    wipe(self.Talents)
    local specGroupIndex = GetActiveSpecGroup()
    for tier = 1, MAX_TALENT_TIERS do
        for column = 1, NUM_TALENT_COLUMNS do
            local talentID, name, texture, selected, available, spellID = GetTalentInfo(tier, column, specGroupIndex)
            if (selected) then
                self.Talents[talentID] = true
            end
        end
    end
    for slotN, talentID in ipairs(C_SpecializationInfo.GetAllSelectedPvpTalentIDs()) do
        self.Talents[talentID] = true
    end
end

addon.Player = Player
