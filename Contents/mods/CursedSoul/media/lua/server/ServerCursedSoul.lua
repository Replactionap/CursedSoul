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

-- Вспомогательная функция для подсчета элементов в таблице
local function getTableLength(t)
    if not t or type(t) ~= "table" then return 0 end
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

-- Вспомогательная функция для глубокого копирования таблицы
local function deepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepCopy(orig_key)] = deepCopy(orig_value)
        end
        setmetatable(copy, deepCopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

-- Безопасное сохранение данных в ModData
local function safeModDataSave(key, data)
    local modData = ModData.getOrCreate(key)
    for k, v in pairs(data) do
        modData[k] = v
    end
    ModData.add(key, modData)
    if isServer() then
        ModData.transmit(key)
    end
end

-- Безопасное получение данных из ModData
local function safeModDataGet(key)
    local modData = ModData.get(key)
    if not modData then
        modData = ModData.create(key)
    end
    return modData
end

local function restoreCursedSoulXP(playerObj, modData, currentStartXP)
    if not playerObj or not playerObj:getXp() then return end
    local xp = playerObj:getXp()
    if type(modData.lastLifeGainedXP) == "table" then
        for perkType, gained in pairs(modData.lastLifeGainedXP) do
            if gained > 0 then
                local base = currentStartXP[perkType] or 0
                local current = xp:getXP(perkType)
                if current < base + gained then
                    xp:AddXP(perkType, (base + gained) - current, false, false, true)
                end
            end
        end
    end
end

local function onPlayerCreatedRestoreXP(playerObj, modData, currentStartXP)
    local ticks = 0
    local tickHandler
    tickHandler = function()
        ticks = ticks + 1
        if ticks >= 5 then -- Увеличил задержку для стабильности
            restoreCursedSoulXP(playerObj, modData, currentStartXP)
            Events.OnTick.Remove(tickHandler)
            return true
        end
    end
    Events.OnTick.Add(tickHandler)
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

-- Инициализация при загрузке игры
Events.OnGameStart.Add(function()
    if CursedSoulDebug then
        print("[CursedSoul][DEBUG] Game started, checking ModData...")
    end
    
    local modData = safeModDataGet("CursedSoul_SavedXP")
    
    if CursedSoulDebug then
        print("[CursedSoul][DEBUG] ModData exists: " .. tostring(modData ~= nil))
        if modData then
            print("[CursedSoul][DEBUG] xpSavedFlag: " .. tostring(modData.xpSavedFlag))
            print("[CursedSoul][DEBUG] needsResurrection: " .. tostring(modData.needsResurrection))
            print("[CursedSoul][DEBUG] savedXP exists: " .. tostring(modData.savedXP ~= nil))
            print("[CursedSoul][DEBUG] currentStartXP exists: " .. tostring(modData.currentStartXP ~= nil))
            print("[CursedSoul][DEBUG] savedStartXP exists: " .. tostring(modData.savedStartXP ~= nil))
            print("[CursedSoul][DEBUG] lastLifeGainedXP exists: " .. tostring(modData.lastLifeGainedXP ~= nil))
            print("[CursedSoul][DEBUG] xpInitialized: " .. tostring(modData.xpInitialized))
            
            -- ДЕТАЛЬНЫЙ ВЫВОД СОДЕРЖИМОГО ModData
            if modData.currentStartXP then
                print("[CursedSoul][DEBUG] currentStartXP entries: " .. tostring(getTableLength(modData.currentStartXP)))
            end
            
            if modData.savedStartXP then
                print("[CursedSoul][DEBUG] savedStartXP entries: " .. tostring(getTableLength(modData.savedStartXP)))
                if getTableLength(modData.savedStartXP) == 0 then
                    print("[CursedSoul][DEBUG] savedStartXP is EMPTY!")
                end
            end
            
            if modData.lastLifeGainedXP then
                print("[CursedSoul][DEBUG] lastLifeGainedXP entries: " .. tostring(getTableLength(modData.lastLifeGainedXP)))
            end
        end
    end

    if not modData.currentStartXP or modData.needsResurrection then
        local xp = playerObj:getXp()
        local currentStartXP = {}
        for i=0, PerkFactory.PerkList:size()-1 do
            local perk = PerkFactory.PerkList:get(i)
            local perkType = perk:getType()
            currentStartXP[perkType] = xp:getXP(perkType)
        end

        modData.currentStartXP = {}
        for k, v in pairs(currentStartXP) do
            modData.currentStartXP[k] = v
        end
        modData.savedStartXP = {}
        for k, v in pairs(currentStartXP) do
            modData.savedStartXP[k] = v
        end
        ModData.transmit("CursedSoul_SavedXP")

        if modData.needsResurrection then
            onPlayerCreatedRestoreXP(playerObj, modData, currentStartXP)
            modData.needsResurrection = nil
            ModData.transmit("CursedSoul_SavedXP")
        end
    end

    -- Обрабатываем воскрешение
    if modData.needsResurrection then
        if CursedSoulDebug then
            print("[CursedSoul][DEBUG] Player needs resurrection, restoring XP...")
        end
        
        local startXPForRestore = modData.currentStartXP or {}
        onPlayerCreatedRestoreXP(playerObj, modData, startXPForRestore)
        
        safeModDataSave("CursedSoul_SavedXP", {
            needsResurrection = nil
        })
    end

    -- Восстановление убийств зомби
    if not modData.xpInitialized then
        if modData.savedZombieKills then
            CursedSoulZombieKillsQueue[playerIndex] = { kills = modData.savedZombieKills }
            if CursedSoulDebug then
                print("[CursedSoul][DEBUG] Queued zombie kills for restoration: " .. tostring(modData.savedZombieKills))
            end
        end
        
        safeModDataSave("CursedSoul_SavedXP", {
            xpInitialized = true,
            savedZombieKills = nil
        })
    end

    -- Основная логика восстановления после смерти
    if modData.xpSavedFlag and type(modData.savedXP) == "table" and type(modData.currentStartXP) == "table" then
        if CursedSoulDebug then
            print("[CursedSoul][DEBUG] Restoring player after death...")
        end
        
        -- Удаляем существующие CursedSoul предметы
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

        -- Добавляем новый CursedSoul предмет
        playerObj:getInventory():AddItem("CursedSoul.CursedSoul")
        
        if CursedSoulDebug then
            print("[CursedSoul][DEBUG] Added CursedSoul item to inventory")
        end

        -- Восстанавливаем вес
        if modData.savedWeight and playerObj.getNutrition then
            local nutrition = playerObj:getNutrition()
            if nutrition and nutrition.setWeight then
                nutrition:setWeight(modData.savedWeight)
                if CursedSoulDebug then
                    print("[CursedSoul][DEBUG] Restored weight: " .. tostring(modData.savedWeight))
                end
            end
        end

        -- Обновляем черты характера в зависимости от веса
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
                if CursedSoulDebug then
                    print("[CursedSoul][DEBUG] Updated weight traits for weight: " .. tostring(weight))
                end
            end
        end
        
        -- Очищаем флаги восстановления
        safeModDataSave("CursedSoul_SavedXP", {
            savedXP = nil,
            xpSavedFlag = nil,
            savedWeight = nil
        })
    end
    
    if CursedSoulDebug then
        print("[CursedSoul][DEBUG] Delayed resurrection check completed")
        -- Перезагружаем данные для финальной проверки
        modData = safeModDataGet("CursedSoul_SavedXP")
        print("[CursedSoul][DEBUG] Final currentStartXP exists: " .. tostring(modData.currentStartXP ~= nil))
        if modData.currentStartXP then
            print("[CursedSoul][DEBUG] Final currentStartXP entries: " .. tostring(getTableLength(modData.currentStartXP)))
        end
    end
end

Events.OnCreatePlayer.Add(function(playerIndex, playerObj)
    if not playerObj or not playerObj:getInventory() then return end
    
    if CursedSoulDebug then
        print("[CursedSoul][DEBUG] Player created, index: " .. tostring(playerIndex))
        print("[CursedSoul][DEBUG] Scheduling delayed resurrection check...")
    end
    
    -- Планируем отложенную проверку после загрузки всех данных
    local ticks = 0
    local delayedCheckHandler
    delayedCheckHandler = function()
        ticks = ticks + 1
        if ticks >= 15 then -- Увеличил задержку для стабильности
            handlePlayerResurrection(playerIndex, playerObj)
            Events.OnTick.Remove(delayedCheckHandler)
        end
    end
    Events.OnTick.Add(delayedCheckHandler)
end)

Events.OnPlayerDeath.Add(function(playerObj)
    if not playerObj or not playerObj:getXp() then return end
    
    if CursedSoulDebug then
        print("[CursedSoul][DEBUG] Player died, saving data...")
    end
    
    local xp = playerObj:getXp()
    local xpTable = {}
    for i=0, PerkFactory.PerkList:size()-1 do
        local perk = PerkFactory.PerkList:get(i)
        -- Use string key for perk type
        local perkType = perk:getType():toString()
        xpTable[perkType] = xp:getXP(perk)
    end
    -- Debug print to verify XP table
    if CursedSoulDebug then
        print("[CursedSoul][DEBUG] Saved XP on death:")
        for k, v in pairs(xpTable) do
            print("  " .. tostring(k) .. " = " .. tostring(v))
        end
    end
    
    local modData = safeModDataGet("CursedSoul_SavedXP")
    
    -- Подготавливаем данные для сохранения
    local dataToSave = {
        savedXP = deepCopy(xpTable),
        xpSavedFlag = true,
        needsResurrection = true,
        lastLifeGainedXP = {},
        xpInitialized = nil -- Сбрасываем флаг инициализации
    }

    -- Вычисляем полученный в текущей жизни XP
    local startXP = modData.currentStartXP or {}
    for perkType, deathAmount in pairs(xpTable) do
        local startAmount = startXP[perkType] or 0
        local gained = deathAmount - startAmount
        dataToSave.lastLifeGainedXP[perkType] = gained > 0 and gained or 0
    end

    -- Сохраняем вес
    if playerObj.getNutrition then
        local nutrition = playerObj:getNutrition()
        if nutrition and nutrition.getWeight then
            dataToSave.savedWeight = nutrition:getWeight()
        end
    end

    -- Сохраняем убийства зомби
    if playerObj.getZombieKills then
        local kills = playerObj:getZombieKills()
        dataToSave.savedZombieKills = kills
        if CursedSoulDebug then
            print("[CursedSoul][DEBUG] Saving zombie kills: " .. tostring(kills))
        end
    end

    -- Сохраняем текущий стартовый XP для следующей жизни
    if modData.currentStartXP and type(modData.currentStartXP) == "table" and getTableLength(modData.currentStartXP) > 0 then
        dataToSave.savedStartXP = deepCopy(modData.currentStartXP)
        if CursedSoulDebug then
            print("[CursedSoul][DEBUG] Saved currentStartXP to savedStartXP, entries: " .. tostring(getTableLength(dataToSave.savedStartXP)))
        end
    else
        if CursedSoulDebug then
            print("[CursedSoul][DEBUG] WARNING: currentStartXP is missing or invalid, initializing from current XP")
        end
        -- Если currentStartXP отсутствует, инициализируем его текущими значениями
        dataToSave.savedStartXP = deepCopy(xpTable)
    end
    
    -- Сохраняем все данные одним вызовом
    safeModDataSave("CursedSoul_SavedXP", dataToSave)
    
    if CursedSoulDebug then
        print("[CursedSoul][DEBUG] Player death data saved successfully")
        print("[CursedSoul][DEBUG] - xpSavedFlag: true")
        print("[CursedSoul][DEBUG] - needsResurrection: true")
        print("[CursedSoul][DEBUG] - savedXP entries: " .. tostring(getTableLength(dataToSave.savedXP)))
        print("[CursedSoul][DEBUG] - savedStartXP entries: " .. tostring(getTableLength(dataToSave.savedStartXP)))
        print("[CursedSoul][DEBUG] - lastLifeGainedXP entries: " .. tostring(getTableLength(dataToSave.lastLifeGainedXP)))
    end
end)