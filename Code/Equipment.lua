local addonName, TopPriorityAction = ...
local _G = _G
---@type TopPriorityAction
local addon = TopPriorityAction

---@class Equipment
---@field private SetBonuses table<integer,integer> @setID, count
---@field ActiveSetBonus fun(self:Equipment, setId:integer, count:integer):boolean
---@field Trinket13 EquipItem
---@field Trinket14 EquipItem

local wipe, pairs, ipairs = wipe, pairs, ipairs

local equipmentSlotIds = {
    Head = INVSLOT_HEAD,
    Neck = INVSLOT_NECK,
    Shoulder = INVSLOT_SHOULDER,
    Chest = INVSLOT_CHEST,
    Waist = INVSLOT_WAIST,
    Legs = INVSLOT_LEGS,
    Feet = INVSLOT_FEET,
    Wrist = INVSLOT_WRIST,
    Hand = INVSLOT_HAND,
    Ring11 = INVSLOT_FINGER1,
    Ring12 = INVSLOT_FINGER2,
    Trinket13 = INVSLOT_TRINKET1,
    Trinket14 = INVSLOT_TRINKET2,
    Back = INVSLOT_BACK,
}

---@type Equipment
local Equipment = {
    SetBonuses = {}
}

function Equipment:ActiveSetBonus(setId, count)
    local setCount = self.SetBonuses[setId]
    return setCount ~= nil and setCount >= count
end

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
        addon.Helper.Throw("attempt to initialize invalid inventory slot", inventorySlotId)
    end
    local equipItem = { SlotId = inventorySlotId, Type = "EquipItem", } ---@type EquipItem
    addon.Helper.AddVirtualMethods(equipItem, EquipItem)
    return equipItem
end

function EquipItem:IsAvailable()
    return self.Active
end

local max, GetItemCooldown = max, C_Container.GetItemCooldown
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
        local onCD = self:ReadyIn() > addon.Rotation.GcdReadyIn
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
    equipItem.Name = ""
    equipItem.Icon = -1
    equipItem.Active = false
    equipItem.SpellId = -1
    equipItem.SpellName = ""
end

local GetInventoryItemID, GetItemSpell = GetInventoryItemID, GetItemSpell
function addon:UpdateEquipment()
    local equipment = addon.Player.Equipment ---@type table<string,EquipItem>
    wipe(equipment.SetBonuses)
    for name, slotId in pairs(equipmentSlotIds) do
        local equipItem = equipment[name]
        SetDefaults(equipItem)
        addon.DataQuery.OnEqupItemLoaded(equipItem.SlotId, function()
            local itemId = GetInventoryItemID("player", equipItem.SlotId)
            if (itemId and itemId > 0) then
                equipItem.Id = itemId
                local name, link, quality, level, minLevel, type, subType, stackCount, equipLoc, icon, sellPrice, classID, subclassID, bindType, expacID, setID = GetItemInfo(itemId)
                equipItem.Name = name
                equipItem.Icon = icon
                local spellName, spellId = GetItemSpell(itemId)
                if (spellId) then
                    equipItem.Active = true
                    equipItem.SpellId = spellId
                    equipItem.SpellName = spellName
                end
                if (setID) then
                    local currentSetCount = equipment.SetBonuses[setID] or 0
                    equipment.SetBonuses[setID] = currentSetCount + 1
                end
            end
        end)
    end
end

local function NewEquipment()
    local equipment = {}
    for name, slotId in pairs(equipmentSlotIds) do
        if (type(slotId) == "number") then
            equipment[name] = NewEquipItem(slotId)
        end
    end
    addon.Helper.AddVirtualMethods(equipment, Equipment)
    for key, value in pairs(Equipment) do
        local memberType = type(value)
        if (memberType ~= "function") then
            equipment[key] = memberType == "table" and {} or value
        end
    end
    return equipment
end

-- attach to addon
addon.Initializer.NewEquipment = NewEquipment
