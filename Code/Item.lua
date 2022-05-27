local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class Item : Action
---@field EquipLoc string

local max, pairs, ipairs = max, pairs, ipairs

---@type Item
local Item = {}

---@param item Item
---@return Item
local function NewItem(item)
    local item = item or addon.Helper:Throw({ "attempt to initialize nil player item" })
    if (item.Id < 1) then
        addon.Helper:Throw({ "attempt to initialize empty player item", item.Id, })
    end
    item.Type = "Item"
    for name, func in pairs(Item) do -- add functions directly, direct lookup might be faster than metatable lookup
        if (type(func) == "function") then
            item[name] = func
        end
    end
    return item
end

local strlen, GetItemInfo = strlen, GetItemInfo
function addon:UpdateKnownItems()
    local items = self.Rotation.Items
    for key, item in pairs(items) do
        local name, link, quality, level, minLevel, type, subType, stackCount, equipLoc, texture, sellPrice, classID, subclassID = GetItemInfo(item.Id)
        item.Name = name
        item.EquipLoc = strlen(equipLoc) > 1 and equipLoc or nil -- https://wowpedia.fandom.com/wiki/Enum.InventoryType
        -- item.Known = IsSpellKnownOrOverridesKnown(item.Id)
        -- local cooldownMS, gcdMS = GetSpellBaseCooldown(item.Id)
        -- item.NoGCD = gcdMS == 0
        -- item.HasCD = cooldownMS > 0
        -- item.ChargesBased = (GetSpellCharges(item.Id)) ~= nil
    end
end

function Spell:IsAvailable()
    return false -- self.Known -- todo:
end

-- attach to addon
addon.Initializer.NewItem = NewItem
