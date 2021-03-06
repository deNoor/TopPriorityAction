local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class Equipment
---@field Trinket13 EquipItem
---@field Trinket14 EquipItem

local pairs, ipairs = pairs, ipairs

local Equipment = {
    Trinket13 = INVSLOT_TRINKET1,
    Trinket14 = INVSLOT_TRINKET2,
}

---@class EquipItem : Action
---@field SlotId integer
---@field Active boolean
---@field SpellId integer
---@field SpellName string

---@type EquipItem
local EquipItem = {}

---@param inventorySlotId integer @INVSLOT_
---@return EquipItem
local function NewEquipItem(inventorySlotId)
    if (not (inventorySlotId and type(inventorySlotId) == "number" and INVSLOT_AMMO <= inventorySlotId and inventorySlotId <= INVSLOT_TABARD)) then
        addon.Helper.Throw({ "attempt to initialize invalid inventory slot", inventorySlotId })
    end
    local equipItem = { SlotId = inventorySlotId, Type = "EquipItem", } ---@type EquipItem
    addon.Helper.AddVirtualMethods(equipItem, EquipItem)
    return equipItem
end

function EquipItem:IsAvailable()
    return self.Active
end

local max, GetItemCooldown = max, GetItemCooldown
function EquipItem:ReadyIn()
    local now = addon.Rotation.Timestamp
    local start, duration, enabled = GetItemCooldown(self.Id)
    if start then
        return max(0, start + duration - now) -- seconds
    end
end

local IsUsableItem = IsUsableItem
function EquipItem:IsUsableNow()
    local usable, noMana = IsUsableItem(self.Id)
    if (usable) then
        local onCD = self:ReadyIn() > addon.Rotation.Settings.ActionAdvanceWindow
        usable = not onCD
    end
    return usable, noMana
end

local IsItemInRange = IsItemInRange
function EquipItem:IsInRange(unit)
    unit = unit or "target"
    return IsItemInRange(self.Id, unit) ~= false
end

local IsCurrentItem = IsCurrentItem
function EquipItem:IsQueued()
    return IsCurrentItem(self.Id)
end

local function SetDefaults(equipItem)
    equipItem.Id = -1
    equipItem.Active = false
    equipItem.SpellId = -1
    equipItem.SpellName = ""
end

local GetInventoryItemID, GetItemSpell = GetInventoryItemID, GetItemSpell
function addon:UpdateEquipment()
    local equipment = addon.Player.Equipment ---@type table<string,EquipItem>
    for key, equipItem in pairs(equipment) do
        SetDefaults(equipItem)
        addon.DataQuery.OnEqupItemLoaded(equipItem.SlotId, function()
            local itemId = GetInventoryItemID("player", equipItem.SlotId)
            if (itemId and itemId > 0) then
                equipItem.Id = itemId
                local name, link, quality, level, minLevel, type, subType, stackCount, equipLoc, icon, sellPrice, classID, subclassID = GetItemInfo(itemId)
                equipItem.Name = name
                equipItem.Icon = icon
                local spellName, spellId = GetItemSpell(itemId)
                if (spellId) then
                    equipItem.Active = true
                    equipItem.SpellId = spellId
                    equipItem.SpellName = spellName
                end
            end
        end)
    end
end

local function NewEquipment()
    addon.Player.Equipment = addon.Player.Equipment or {}
    local equipment = addon.Player.Equipment
    wipe(equipment)
    for key, value in pairs(Equipment) do
        if (type(value) == "number") then
            local slotId = value
            equipment[key] = NewEquipItem(slotId)
        end
    end
end

-- attach to addon
addon.Initializer.NewEquipment = NewEquipment
