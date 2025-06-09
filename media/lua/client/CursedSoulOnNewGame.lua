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
    end
end

Events.OnPlayerUpdate.Add(function()
    local player = getPlayer()
    if player and not player:isDead() then
        preventCursedSoulDropOrRemove(player)
    end
end)
