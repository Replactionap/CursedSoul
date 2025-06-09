-- (Удалите весь код, файл можно оставить пустым или удалить)

local function returnCursedSoulFromContainer(container, item)
    if not item or item:getFullType() ~= "CursedSoul.CursedSoul" then return end
    local player = nil
    -- Найти игрока, которому принадлежит предмет (по онлайну)
    for i=0, getOnlinePlayers():size()-1 do
        local pl = getOnlinePlayers():get(i)
        if pl and pl:getInventory() and not pl:getInventory():contains(item) then
            player = pl
            break
        end
    end
    if player then
        -- Удалить из контейнера и вернуть игроку
        if container:contains(item) then
            container:Remove(item)
        end
        player:getInventory():AddItem(item)
        if player.setWornItem then
            player:setWornItem(item:getBodyLocation(), item)
        end
    end
end

Events.OnContainerUpdate.Add(function(container)
    if not container then return end
    for i=0, container:getItems():size()-1 do
        local item = container:getItems():get(i)
        returnCursedSoulFromContainer(container, item)
    end
end)

-- Удаляет все CursedSoul из контейнеров в радиусе 5 клеток вокруг игрока
local function removeAllCursedSoulInContainersNearby(player)
    local square = player.getCurrentSquare and player:getCurrentSquare()
    if not square then return end
    for dx = -5, 5 do
        for dy = -5, 5 do
            local checkSquare = getCell() and getCell():getGridSquare(square:getX() + dx, square:getY() + dy, square:getZ())
            if checkSquare and checkSquare.getContainers then
                local containers = checkSquare:getContainers()
                if containers then
                    for c = 0, containers:size() - 1 do
                        local container = containers:get(c)
                        if container and container.getItems and container.DoRemoveItem then
                            local containerItems = container:getItems()
                            local toRemove = {}
                            for i = 0, containerItems:size() - 1 do
                                local it = containerItems:get(i)
                                if it and it.getFullType and it:getFullType() == "CursedSoul.CursedSoul" then
                                    table.insert(toRemove, it)
                                end
                            end
                            for _, it in ipairs(toRemove) do
                                container:DoRemoveItem(it)
                            end
                        end
                    end
                end
            end
        end
    end
end

Events.OnPlayerUpdate.Add(function(player)
    if player and not player:isDead() then
        removeAllCursedSoulInContainersNearby(player)
    end
end)
