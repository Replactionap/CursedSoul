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

-- Удаляет все CursedSoul в радиусе 10 клеток вокруг игрока
local function removeAllCursedSoulNearby(player)
    local square = player.getCurrentSquare and player:getCurrentSquare()
    if not square then return end
    for dx = -10, 10 do
        for dy = -10, 10 do
            local checkSquare = getCell() and getCell():getGridSquare(square:getX() + dx, square:getY() + dy, square:getZ())
            if checkSquare then
                -- Удаляем с пола
                if checkSquare.getWorldObjects then
                    local worldObjects = checkSquare:getWorldObjects()
                    if worldObjects then
                        for i = worldObjects:size() - 1, 0, -1 do
                            local worldObj = worldObjects:get(i)
                            if worldObj and worldObj.getItem and worldObj.removeFromWorld and worldObj.removeFromSquare then
                                local worldItem = worldObj:getItem()
                                if worldItem and worldItem.getFullType and worldItem:getFullType() == "CursedSoul.CursedSoul" then
                                    worldObj:removeFromWorld()
                                    worldObj:removeFromSquare()
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

local function preventCursedSoulDropOrRemove(player)
    local inv = player and player:getInventory()
    if not inv then return end
    local item = inv:FindAndReturn("CursedSoul.CursedSoul")
    if item then
        -- Если предмет не надет, надеваем обратно
        if player.getWornItem and not player:getWornItem(item:getBodyLocation()) then
            player:setWornItem(item:getBodyLocation(), item)
        end
        -- Если предмет не в инвентаре, возвращаем
        if not inv:contains(item) then
            inv:AddItem(item)
            player:setWornItem(item:getBodyLocation(), item)
        end
    else
        -- Если предмета нет в инвентаре, удаляем все такие предметы вокруг
        removeAllCursedSoulNearby(player)
    end
end

local function restoreCursedSoulIfMissing(player)
    if not player or player:isDead() then return end
    local inv = player.getInventory and player:getInventory()
    if not inv then return end
    local item = inv:FindAndReturn("CursedSoul.CursedSoul")
    if not item then
        local square = player.getCurrentSquare and player:getCurrentSquare()
        local found = false
        if square then
            -- Увеличиваем радиус поиска до 5 клеток вокруг игрока
            for dx = -5, 5 do
                for dy = -5, 5 do
                    local checkSquare = getCell() and getCell():getGridSquare(square:getX() + dx, square:getY() + dy, square:getZ())
                    if checkSquare then
                        -- 1. (Удалено: удаление из контейнеров, теперь на сервере)
                        -- 2. Удаляем все CursedSoul с пола (WorldObjects)
                        if checkSquare.getWorldObjects then
                            local worldObjects = checkSquare:getWorldObjects()
                            if worldObjects then
                                for i = worldObjects:size() - 1, 0, -1 do
                                    local worldObj = worldObjects:get(i)
                                    if worldObj and worldObj.getItem and worldObj.removeFromWorld and worldObj.removeFromSquare then
                                        local worldItem = worldObj:getItem()
                                        if worldItem and worldItem.getFullType and worldItem:getFullType() == "CursedSoul.CursedSoul" then
                                            worldObj:removeFromWorld()
                                            worldObj:removeFromSquare()
                                            found = true
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        -- После удаления с пола, добавляем новый предмет в инвентарь
        if found or not inv:FindAndReturn("CursedSoul.CursedSoul") then
            item = inv:AddItem("CursedSoul.CursedSoul")
        end
        -- Надеваем, если нужно
        if item and player.getWornItem and not player:getWornItem(item:getBodyLocation()) then
            player:setWornItem(item:getBodyLocation(), item)
        end
    end
end

Events.OnPlayerUpdate.Add(function()
    local player = getPlayer()
    if player and not player:isDead() then
        preventCursedSoulDropOrRemove(player)
        restoreCursedSoulIfMissing(player)
    end
end)