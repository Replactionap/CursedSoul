local function tryWearCursedSoul()
    local player = getPlayer()
    if not player or player:isDead() then
        Events.OnPlayerUpdate.Remove(tryWearCursedSoul)
        return
    end

    local inv = player.getInventory and player:getInventory()
    if not inv or not inv.FindAndReturn then
        Events.OnPlayerUpdate.Remove(tryWearCursedSoul)
        return
    end

    local item = inv:FindAndReturn("CursedSoul.CursedSoul")
    if item and player.getWornItem and not player:getWornItem(item:getBodyLocation()) then
        print("[CursedSoul] Надеваем аксессуар напрямую через setWornItem")
        player:setWornItem(item:getBodyLocation(), item)
    end
    Events.OnPlayerUpdate.Remove(tryWearCursedSoul)
end

local function giveCursedSoul()
    local player = getPlayer()
    if not player or player:isDead() then
        Events.OnPlayerUpdate.Remove(giveCursedSoul)
        return
    end

    local inv = player.getInventory and player:getInventory()
    if not inv or not inv.AddItem or not inv.FindAndReturn then
        Events.OnPlayerUpdate.Remove(giveCursedSoul)
        return
    end

    if not inv:FindAndReturn("CursedSoul.CursedSoul") then
        print("[CursedSoul] Добавляем предмет в инвентарь")
        inv:AddItem("CursedSoul.CursedSoul")
    end
    Events.OnPlayerUpdate.Add(tryWearCursedSoul)
    Events.OnPlayerUpdate.Remove(giveCursedSoul)
end

Events.OnPlayerUpdate.Add(giveCursedSoul)

Events.OnCreatePlayer.Add(function(playerIndex, player)
    if not player or player:isDead() then return end
    local inv = player.getInventory and player:getInventory()
    if not inv or not inv.AddItem or not inv.FindAndReturn then return end
    if not inv:FindAndReturn("CursedSoul.CursedSoul") then
        inv:AddItem("CursedSoul.CursedSoul")
    end
end)

local function removeNearbyCursedSouls(player)
    local cell = getCell()
    if not cell then return end
    local px, py, pz = player:getX(), player:getY(), player:getZ()
    local radius = 10
    for x = math.floor(px - radius), math.ceil(px + radius) do
        for y = math.floor(py - radius), math.ceil(py + radius) do
            local sq = cell:getGridSquare(x, y, pz)
            if sq then
                local floorItems = sq:getWorldObjects()
                if floorItems and floorItems.size then
                    for i = floorItems:size()-1, 0, -1 do
                        local obj = floorItems:get(i)
                        if obj and obj.getItem and obj:getItem() and obj:getItem().getFullType and obj:getItem():getFullType() == "CursedSoul.CursedSoul" then
                            obj:removeFromWorld()
                            obj:removeFromSquare()
                            if obj.transmitRemoveItemFromSquare then
                                obj:transmitRemoveItemFromSquare()
                            end
                        end
                    end
                end
                local containerObjs = sq.getObjects and sq:getObjects()
                if containerObjs and containerObjs.size then
                    for i = containerObjs:size()-1, 0, -1 do
                        local obj = containerObjs:get(i)
                        if obj and obj.getItem and obj:getItem() and obj:getItem().getFullType and obj:getItem():getFullType() == "CursedSoul.CursedSoul" then
                            obj:removeFromWorld()
                            obj:removeFromSquare()
                        end
                    end
                end
                if sq.getContainers then
                    local containers = sq:getContainers()
                    if containers and containers.size then
                        for c = 0, containers:size() - 1 do
                            local container = containers:get(c)
                            if container and container.getItems and container.Remove then
                                local items = container:getItems()
                                local toRemove = {}
                                for i = 0, items:size() - 1 do
                                    local it = items:get(i)
                                    if it and it.getFullType and it:getFullType() == "CursedSoul.CursedSoul" then
                                        table.insert(toRemove, it)
                                    end
                                end
                                for _, it in ipairs(toRemove) do
                                    print("[CursedSoul][DEBUG] Removing CursedSoul from container (getContainers) at square (" .. x .. "," .. y .. "," .. pz .. ")")
                                    container:Remove(it)
                                end
                            end
                        end
                    end
                end
                if containerObjs and containerObjs.size then
                    for i = 0, containerObjs:size() - 1 do
                        local obj = containerObjs:get(i)
                        if obj and obj.getContainer then
                            local container = obj:getContainer()
                            if container and container.getItems and container.Remove then
                                local items = container:getItems()
                                local toRemove = {}
                                for j = 0, items:size() - 1 do
                                    local it = items:get(j)
                                    if it and it.getFullType and it:getFullType() == "CursedSoul.CursedSoul" then
                                        table.insert(toRemove, it)
                                    end
                                end
                                for _, it in ipairs(toRemove) do
                                    print("[CursedSoul][DEBUG] Removing CursedSoul from IsoObject container at square (" .. x .. "," .. y .. "," .. pz .. ")")
                                    container:Remove(it)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

local function returnAndWearCursedSoul(player)
    if not player or player:isDead() then return end
    local inv = player.getInventory and player:getInventory()
    if not inv or not inv.AddItem or not inv.FindAndReturn then return end
    local item = inv:FindAndReturn("CursedSoul.CursedSoul")
    if not item then
        removeNearbyCursedSouls(player)
        print("[CursedSoul] Возвращаем предмет и надеваем")
        local newItem = inv:AddItem("CursedSoul.CursedSoul")
        if newItem and player.getWornItem and not player:getWornItem(newItem:getBodyLocation()) then
            player:setWornItem(newItem:getBodyLocation(), newItem)
        end
    else
        removeNearbyCursedSouls(player)
    end
end

local function hasCursedSoulNow()
    local player = getPlayer()
    if not player or player:isDead() then return false end
    local inv = player.getInventory and player:getInventory()
    if not inv or not inv.FindAndReturn then return false end
    return inv:FindAndReturn("CursedSoul.CursedSoul") ~= nil
end

local lastHadCursedSoul = hasCursedSoulNow()

local function checkCursedSoulDropped()
    local player = getPlayer()
    if not player or player:isDead() then return end
    local inv = player.getInventory and player:getInventory()
    if not inv or not inv.FindAndReturn then return end
    local hasCursedSoul = inv:FindAndReturn("CursedSoul.CursedSoul") ~= nil

    if lastHadCursedSoul and not hasCursedSoul then
        returnAndWearCursedSoul(player)
    end
    lastHadCursedSoul = hasCursedSoul
end

Events.OnPlayerUpdate.Add(checkCursedSoulDropped)

-- Hide "Снять" (Unequip) and "Выкинуть" (Drop) for CursedSoul
local function CursedSoul_HideContextMenuOptions(player, context, items)
    -- Flatten items (handles both single and multi selection)
    local function getAllItems(tbl)
        local result = {}
        for _, entry in ipairs(tbl) do
            if type(entry) == "table" and entry.items then
                for _, it in ipairs(entry.items) do
                    table.insert(result, it)
                end
            else
                table.insert(result, entry)
            end
        end
        return result
    end

    local allItems = getAllItems(items)
    local hasCursedSoul = false
    for _, item in ipairs(allItems) do
        local realItem = item
        if type(item) == "table" and item.getFullType then
            realItem = item
        elseif item and item.items and #item.items > 0 then
            realItem = item.items[1]
        end
        if realItem and realItem.getFullType and realItem:getFullType() == "CursedSoul.CursedSoul" then
            hasCursedSoul = true
            break
        end
    end
    if not hasCursedSoul then return end

    -- Remove "Снять" (Unequip) and "Выкинуть" (Drop) options
    for i = context.numOptions, 1, -1 do
        local opt = context.options[i]
        if opt and (opt.name == getText("ContextMenu_Unequip") or opt.name == getText("ContextMenu_Drop")) then
            context:removeOptionByName(opt.name)
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(CursedSoul_HideContextMenuOptions)

-- Автоматически надеваем CursedSoul если он есть в инвентаре, но не надет
local function autoWearCursedSoulIfNeeded()
    local player = getPlayer()
    if not player or player:isDead() then return end
    local inv = player.getInventory and player:getInventory()
    if not inv or not inv.FindAndReturn then return end
    local item = inv:FindAndReturn("CursedSoul.CursedSoul")
    if item and player.getWornItem and not player:getWornItem(item:getBodyLocation()) then
        player:setWornItem(item:getBodyLocation(), item)
    end
end

-- Добавляем автонатягивание при каждом обновлении игрока (после респавна)
Events.OnPlayerUpdate.Add(autoWearCursedSoulIfNeeded)

-- Также автонатягиваем при создании игрока (на всякий случай)
Events.OnCreatePlayer.Add(function(playerIndex, player)
    if not player or player:isDead() then return end
    local inv = player.getInventory and player:getInventory()
    if not inv or not inv.AddItem or not inv.FindAndReturn then return end
    local item = inv:FindAndReturn("CursedSoul.CursedSoul")
    if item and player.getWornItem and not player:getWornItem(item:getBodyLocation()) then
        player:setWornItem(item:getBodyLocation(), item)
    end
end)