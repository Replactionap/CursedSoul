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

CursedSoulDebug = true

CursedSoulTimestamp = os.time()

local function isFirstTimePlayer(playerObj)
    if not playerObj then
        if CursedSoulDebug then
            print("[CursedSoul][FirstLogin] playerObj is nil")
        end
        return false, {}
    end
    
    local playerName = "unknown"
    if playerObj.getUsername then
        playerName = tostring(playerObj:getUsername()) or "unknown"
    end
    
    local reasons = {}
    
    
    if playerObj.getHoursSurvived then
        local success, hoursSurvived = pcall(function() return playerObj:getHoursSurvived() end)
        if success and hoursSurvived then
            if CursedSoulDebug then
                print("[CursedSoul][FirstLogin] " .. playerName .. " - Hours survived: " .. tostring(hoursSurvived))
            end
            if hoursSurvived >= 0.01 then
                table.insert(reasons, "Hours survived >= 0.1 (" .. tostring(hoursSurvived) .. ")")
                if CursedSoulDebug then
                    print("[CursedSoul][FirstLogin] " .. playerName .. " is existing player - reason: Hours survived")
                end
                return false, reasons
            end
        end
    end
    
    if playerObj.getZombieKills then
        local success, zombieKills = pcall(function() return playerObj:getZombieKills() end)
        if success and zombieKills then
            if CursedSoulDebug then
                print("[CursedSoul][FirstLogin] " .. playerName .. " - Zombie kills: " .. tostring(zombieKills))
            end
            if zombieKills > 0 then
                table.insert(reasons, "Zombie kills > 0 (" .. tostring(zombieKills) .. ")")
                if CursedSoulDebug then
                    print("[CursedSoul][FirstLogin] " .. playerName .. " is existing player - reason: Zombie kills")
                end
                return false, reasons
            end
        end
    end

    
    if CursedSoulDebug then
        print("[CursedSoul][FirstLogin] " .. playerName .. " is NEW player - all checks passed")
    end
    return true, {}
end

local function restoreCursedSoulXP(playerObj, modData, currentStartXP)
    if not playerObj or not playerObj:getXp() then return end
    local xp = playerObj:getXp()
    if type(modData.lastLifeGainedXP) == "table" then
        for perkType, gained in pairs(modData.lastLifeGainedXP) do
            if gained > 0 then
                local perk = Perks.FromString(perkType)
                if perk then
                    local base = currentStartXP[perkType] or 0
                    local current = xp:getXP(perk)
                    if current < base + gained then
                        xp:AddXP(perk, (base + gained) - current, false, false, true)
                    end
                end
            end
        end
    end
end

local function onPlayerCreatedRestoreXP(playerObj, modData, currentStartXP)
    local ticks = 0
    Events.OnTick.Add(function()
        ticks = ticks + 1
        if ticks >= 2 then
            restoreCursedSoulXP(playerObj, modData, currentStartXP)
            return true
        end
    end)
end

local CursedSoulZombieKillsQueue = {}

local function tryRestoreZombieKills()
    for playerOnlineIndex, data in pairs(CursedSoulZombieKillsQueue) do
        local playerObj = getSpecificPlayer(playerOnlineIndex)
        if playerObj and playerObj.setZombieKills and not playerObj:isDead() then
            playerObj:setZombieKills(data.kills)
            CursedSoulZombieKillsQueue[playerOnlineIndex] = nil
            if CursedSoulDebug then
                print("[CursedSoul][DEBUG] Restored zombie kills for player index " .. tostring(playerOnlineIndex) .. ": " .. tostring(data.kills))
            end
        end
    end
end

Events.OnTick.Add(tryRestoreZombieKills)

local function getPlayerUniqueID(playerObj)
    if playerObj and playerObj.getUsername then
        return tostring(playerObj:getUsername())
    end
    return "unknown"
end

Events.OnCreatePlayer.Add(function(playerIndex, playerObj)
    if not playerObj or not playerObj:getInventory() then return end

    local checkTimer = 0
    local firstLoginChecked = false
    local checkFirstTimeHandler
    checkFirstTimeHandler = function()
        if firstLoginChecked then
            return true
        end
        checkTimer = checkTimer + 1
        if checkTimer >= 10 then
            local isNew, reasons = isFirstTimePlayer(playerObj)
            local playerName = getPlayerUniqueID(playerObj)

            if isNew or (#reasons > 0) then
                firstLoginChecked = true

                if isNew then
                    local logMessage = "[CursedSoul][FirstLogin] New player detected: " .. playerName

                    if CursedSoulDebug then
                        print(logMessage)
                    end

                    local debugInfo = {}

                    if playerObj.getHoursSurvived then
                        debugInfo.hoursSurvived = playerObj:getHoursSurvived()
                    end

                    if playerObj.getZombieKills then
                        debugInfo.zombieKills = playerObj:getZombieKills()
                    end

                    if playerObj:getInventory() then
                        debugInfo.inventorySize = playerObj:getInventory():getItems():size()
                    end

                    if playerObj:getXp() then
                        local xp = playerObj:getXp()
                        local totalXP = 0
                        for i = 0, PerkFactory.PerkList:size() - 1 do
                            local perk = PerkFactory.PerkList:get(i)
                            totalXP = totalXP + xp:getXP(perk)
                        end
                        debugInfo.totalXP = totalXP
                    end

                    if CursedSoulDebug then
                        print("[CursedSoul][FirstLogin] Player stats - Hours: " .. tostring(debugInfo.hoursSurvived or "N/A") ..
                              ", Zombie kills: " .. tostring(debugInfo.zombieKills or "N/A") ..
                              ", Inventory items: " .. tostring(debugInfo.inventorySize or "N/A") ..
                              ", Total XP: " .. tostring(debugInfo.totalXP or "N/A"))
                    end
                else
                    print("[CursedSoul][FirstLogin] Existing player detected: " .. playerName)
                    if #reasons > 0 then
                        if CursedSoulDebug then
                            print("[CursedSoul][FirstLogin] Reasons why " .. playerName .. " is considered existing:")
                            for i, reason in ipairs(reasons) do
                                print("[CursedSoul][FirstLogin]   " .. i .. ". " .. reason)
                            end
                        end
                    end
                end
                return true
            end
        end
    end
    Events.OnTick.Add(checkFirstTimeHandler)

    -- === ERROR HANDLER FOR MODDATA ===
    local modData = ModData.getOrCreate("CursedSoul_SavedXP")
    if not modData then
        if CursedSoulDebug then
            print("[CursedSoul][ERROR] ModData CursedSoul_SavedXP is nil!")
        end
    end

    -- Время создания теперь ключ таблицы modData
    local function getCreationTimestamp(tbl)
        for k, v in pairs(tbl) do
            if type(k) == "number" then
                return k
            end
        end
        return nil
    end

    local creationTime = getCreationTimestamp(modData)
    if not creationTime then
        local now = os.time()
        modData[now] = true -- или nil, если хотите
        if CursedSoulDebug then
            print("[CursedSoul][DEBUG] Set creation timestamp as key in modData: " .. tostring(now))
        end
        ModData.transmit("CursedSoul_SavedXP")
        creationTime = now
    end

    -- Remove uniqueID usage, use modData directly
    if not modData or not modData.currentStartXP then
        local isNew, _ = isFirstTimePlayer(playerObj)
        if not isNew then
            modData = modData or {}
            modData.currentStartXP = {}
            for i=0, PerkFactory.PerkList:size()-1 do
                local perk = PerkFactory.PerkList:get(i)
                local perkType = perk:getType():toString()
                modData.currentStartXP[perkType] = 0
            end
            modData.savedStartXP = {}
            for k, v in pairs(modData.currentStartXP) do
                modData.savedStartXP[k] = v
            end
            if CursedSoulDebug then
                print("[CursedSoul][ERROR HANDLER] No modData for existing player, setting all start XP to 0")
            end
            ModData.transmit("CursedSoul_SavedXP")
        end
    end
    -- === ERROR HANDLER FOR MODDATA ===

    -- Use modData directly
    if modData.savedStartXP and not modData.currentStartXP then
        modData.currentStartXP = {}
        for k, v in pairs(modData.savedStartXP) do
            modData.currentStartXP[k] = v
        end
    end

    if not modData.currentStartXP or modData.needsResurrection then
        local xp = playerObj:getXp()
        local currentStartXP = {}
        for i=0, PerkFactory.PerkList:size()-1 do
            local perk = PerkFactory.PerkList:get(i)
            local perkType = perk:getType():toString()
            currentStartXP[perkType] = xp:getXP(perk)
        end

        modData.currentStartXP = {}
        for k, v in pairs(currentStartXP) do
            modData.currentStartXP[k] = v
        end
        modData.savedStartXP = {}
        for k, v in pairs(currentStartXP) do
            modData.savedStartXP[k] = v
        end
        if CursedSoulDebug then
            print("[CursedSoul][DEBUG] Saved currentStartXP:")
            for k, v in pairs(currentStartXP) do
                print("  " .. tostring(k) .. " = " .. tostring(v))
            end
        end
        ModData.transmit("CursedSoul_SavedXP")

        if modData.needsResurrection then
            onPlayerCreatedRestoreXP(playerObj, modData, currentStartXP)
            modData.needsResurrection = nil
            ModData.transmit("CursedSoul_SavedXP")
        end
    end

    if not modData.xpInitialized then
        if modData.savedZombieKills then
            CursedSoulZombieKillsQueue[playerIndex] = { kills = modData.savedZombieKills }
            modData.savedZombieKills = nil
            ModData.transmit("CursedSoul_SavedXP")
        end

        modData.xpInitialized = true
        ModData.transmit("CursedSoul_SavedXP")
    end

    if modData.xpSavedFlag and type(modData.savedXP) == "table" and type(modData.currentStartXP) == "table" then
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

        modData.savedXP = nil
        modData.xpSavedFlag = nil
        ModData.transmit("CursedSoul_SavedXP")

        if modData.savedWeight and playerObj.getNutrition then
            local nutrition = playerObj:getNutrition()
            if nutrition and nutrition.setWeight then
                nutrition:setWeight(modData.savedWeight)
            end
            modData.savedWeight = nil
            ModData.transmit("CursedSoul_SavedXP")
        end

        if playerObj.getNutrition and playerObj.getTraits then
            local nutrition = playerObj:getNutrition()
            local traits = playerObj:getTraits()
            if nutrition and traits then
                local weight = nutrition:getWeight()
                traits:remove("Obese")
                traits:remove("Overweight")
                traits:remove("Underweight")
                traits:remove("Emaciated")
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
    end
end)

Events.OnPlayerDeath.Add(function(playerObj)
    if not playerObj or not playerObj:getXp() then return end
    local xp = playerObj:getXp()
    local xpTable = {}
    for i=0, PerkFactory.PerkList:size()-1 do
        local perk = PerkFactory.PerkList:get(i)
        local perkType = perk:getType():toString()
        xpTable[perkType] = xp:getXP(perk)
    end
    if CursedSoulDebug then
        print("[CursedSoul][DEBUG] Saved XP on death:")
        for k, v in pairs(xpTable) do
            print("  " .. tostring(k) .. " = " .. tostring(v))
        end
    end
    local modData = ModData.getOrCreate("CursedSoul_SavedXP")
    -- Remove uniqueID usage, use modData directly
    modData.savedXP = xpTable
    modData.xpSavedFlag = true
    modData.needsResurrection = true

    modData.lastLifeGainedXP = {}
    local startXP = modData.currentStartXP or {}
    for perkType, deathAmount in pairs(xpTable) do
        local startAmount = startXP[perkType] or 0
        local gained = deathAmount - startAmount
        modData.lastLifeGainedXP[perkType] = gained > 0 and gained or 0
    end

    if playerObj.getNutrition then
        local nutrition = playerObj:getNutrition()
        if nutrition and nutrition.getWeight then
            modData.savedWeight = nutrition:getWeight()
        end
    end

    if playerObj.getZombieKills then
        local kills = playerObj:getZombieKills()
        modData.savedZombieKills = kills
        ModData.transmit("CursedSoul_SavedXP")
    end

    if modData.currentStartXP then
        modData.savedStartXP = {}
        for k, v in pairs(modData.currentStartXP) do
            modData.savedStartXP[k] = v
        end
    end
    
    modData.xpInitialized = nil
    ModData.transmit("CursedSoul_SavedXP")
end)