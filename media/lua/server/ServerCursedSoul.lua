local function returnCursedSoulFromContainer(container, item)
    if not item or item:getFullType() ~= "CursedSoul.CursedSoul" then return end
    local player = nil
    for i=0, getOnlinePlayers():size()-1 do
        local pl = getOnlinePlayers():get(i)
        if pl and pl:getInventory() and not pl:getInventory():contains(item) then
            player = pl
            break
        end
    end
    if player then
        if container:contains(item) then
            container:Remove(item)
        end
        player:getInventory():AddItem(item)
        if player.setWornItem then
            player:setWornItem(item:getBodyLocation(), item)
        end
    end
end

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

local function removeNearbyCursedSouls(player)
    local cell = getCell()
    if not cell then return end
    local px, py, pz = player:getX(), player:getY(), player:getZ()
    local radius = 10
    for x = math.floor(px - radius), math.ceil(px + radius) do
        for y = math.floor(py - radius), math.ceil(py + radius) do
            local sq = cell:getGridSquare(x, y, pz)
            if sq then
                -- Remove items from ground
                local floorItems = sq.getWorldObjects and sq:getWorldObjects()
                if floorItems and floorItems.size then
                    for i = floorItems:size()-1, 0, -1 do
                        local obj = floorItems:get(i)
                        if obj and obj.getItem and obj:getItem() and obj:getItem().getFullType and obj:getItem():getFullType() == "CursedSoul.CursedSoul" then
                            obj:removeFromWorld()
                            obj:removeFromSquare()
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

Events.OnTick.Add(function()
    local players = getOnlinePlayers and getOnlinePlayers()
    if players and players.size then
        for i = 0, players:size() - 1 do
            local player = players:get(i)
            if player and not player:isDead() then
                removeAllCursedSoulInContainersNearby(player)
                removeNearbyCursedSouls(player)
            end
        end
    end
end)

Events.OnPlayerDeath.Add(function(playerObj)
    if not playerObj or not playerObj:getXp() then return end
    local xp = playerObj:getXp()
    local xpTable = {}
    for i=0, PerkFactory.PerkList:size()-1 do
        local perk = PerkFactory.PerkList:get(i)
        local perkType = perk:getType()
        xpTable[perkType] = xp:getXP(perkType)
    end
    local modData = ModData.getOrCreate("CursedSoul_SavedXP")
    modData.savedXP = xpTable
    modData.xpSavedFlag = true

    -- Save weight
    if playerObj.getNutrition then
        local nutrition = playerObj:getNutrition()
        if nutrition and nutrition.getWeight then
            modData.savedWeight = nutrition:getWeight()
        end
    end

    ModData.transmit("CursedSoul_SavedXP")
end)

Events.OnCreatePlayer.Add(function(playerIndex, playerObj)
    if not playerObj or not playerObj:getInventory() then return end
    local modData = ModData.getOrCreate("CursedSoul_SavedXP")
    if modData.xpSavedFlag then
        local inv = playerObj:getInventory()
        local items = inv:getItems()
        local toRemove = {}
        for i = 0, items:size()-1 do
            local item = items:get(i)
            if item and item.getFullType and item:getFullType() == "CursedSoul.CursedSoul" then
                table.insert(toRemove, item)
            end
        end
        for _, item in ipairs(toRemove) do
            inv:Remove(item)
        end

        playerObj:getInventory():AddItem("CursedSoul.CursedSoul")
        local savedXP = modData.savedXP
        if savedXP and playerObj:getXp() then
            local xp = playerObj:getXp()
            for perkType, amount in pairs(savedXP) do
                local current = xp:getXP(perkType)
                local diff = amount - current
                if diff > 0 then
                    xp:AddXP(perkType, diff)
                end
            end
            modData.savedXP = nil
            ModData.transmit("CursedSoul_SavedXP")
        end

        -- Restore weight
        if modData.savedWeight and playerObj.getNutrition then
            local nutrition = playerObj:getNutrition()
            if nutrition and nutrition.setWeight then
                nutrition:setWeight(modData.savedWeight)
            end
            modData.savedWeight = nil
            ModData.transmit("CursedSoul_SavedXP")
        end

        -- Sync traits with weight
        if playerObj.getNutrition and playerObj.getTraits then
            local nutrition = playerObj:getNutrition()
            local traits = playerObj:getTraits()
            if nutrition and traits then
                local weight = nutrition:getWeight()
                -- Remove all weight-related traits
                traits:remove("Obese")
                traits:remove("Overweight")
                traits:remove("Underweight")
                traits:remove("Emaciated")
                -- Add trait based on weight
                if weight >= 105 then
                    traits:add("Obese")
                elseif weight >= 90 then
                    traits:add("Overweight")
                elseif weight <= 65 then
                    traits:add("Emaciated")
                elseif weight <= 75 then
                    traits:add("Underweight")
                end
            end
        end

        modData.xpSavedFlag = nil
    end
end)
