local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class Item : Action
---@field Active boolean
---@field SpellId integer
---@field SpellName string

local pairs, ipairs = pairs, ipairs

---@type Item
local Item = {}

---@param item Item
---@return Item
local function NewItem(item)
    local item = item or addon.Helper.Throw("attempt to initialize nil player item")
    if (item.Id < 1) then
        addon.Helper.Throw("attempt to initialize empty player item", item.Id)
    end
    item.Type = "Item"
    addon.Helper.AddVirtualMethods(item, Item)
    return item
end

local function SetDefaults(item)
    item.Name = ""
    item.Icon = -1
    item.Active = false
    item.SpellId = -1
    item.SpellName = ""
end

function addon:UpdateKnownItems()
    local items = self.Rotation.Items
    for key, item in pairs(items) do
        if (item.Id > 0) then
            SetDefaults(item)
            addon.DataQuery.OnItemLoaded(item.Id, function()
                local itemId = item.Id
                if (itemId and itemId > 0) then
                    local name, link, quality, level, minLevel, type, subType, stackCount, equipLoc, icon, sellPrice, classID, subclassID = C_Item.GetItemInfo(itemId)
                    if (not name) then
                        addon.Helper.Throw(key, "GetItemInfo failed")
                    end
                    item.Name = name
                    item.Icon = icon
                    local spellName, spellId = C_Item.GetItemSpell(itemId)
                    if (spellId) then
                        item.Active = true
                        item.SpellId = spellId
                        item.SpellName = spellName
                    end
                end
            end)
        end
    end
end

function Item:IsAvailable()
    return self.Active
end

local max, GetItemCooldown = max, C_Item.GetItemCooldown
function Item:ReadyIn()
    local now = addon.Timestamp
    local start, duration, enabled = GetItemCooldown(self.Id)
    if start then
        return max(0, start + duration - now) -- seconds
    end
    addon.Helper.Throw("Item returned no cooldown", self.Id, self.Name)
end

local IsUsableItem = C_Item.IsUsableItem
function Item:IsUsableNow()
    local usable, noMana = IsUsableItem(self.Id)
    if (usable) then
        local onCD = self:ReadyIn() > (addon.Rotation.GcdReadyIn + 0.1)
        usable = not onCD
    end
    return usable, noMana
end

local IsItemInRange = C_Item.IsItemInRange
function Item:IsInRange(unit)
    unit = unit or "target"
    return IsItemInRange(self.Id, unit) ~= false
end

local IsCurrentItem = C_Item.IsCurrentItem
function Item:IsQueued()
    return IsCurrentItem(self.Id)
end

-- attach to addon
addon.Initializer.NewItem = NewItem
