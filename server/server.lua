local ESX, QBCore = nil, nil
local Framework = nil

CreateThread(function()
    if Config.Framework == 'auto' then
        local success = pcall(function()
            ESX = exports['es_extended']:getSharedObject()
        end)
        
        if success and ESX then
            Framework = 'esx'
            print('^2[TPMENU]^0 ESX Framework detected')
            return
        end
        
        success = pcall(function()
            QBCore = exports['qbx-core']:GetCoreObject()
        end)
        
        if success and QBCore then
            Framework = 'qbox'
            print('^2[TPMENU]^0 QBox Framework detected')
            return
        end
        
        success = pcall(function()
            QBCore = exports['qb-core']:GetCoreObject()
        end)
        
        if success and QBCore then
            Framework = 'qb'
            print('^2[TPMENU]^0 QB-Core Framework detected')
            return
        end
        
        print('^3[TPMENU]^0 No framework detected, running in standalone mode')
    else
        Framework = Config.Framework
        if Framework == 'esx' then
            ESX = exports['es_extended']:getSharedObject()
        elseif Framework == 'qb' or Framework == 'qbox' then
            if Framework == 'qbox' then
                QBCore = exports['qbx-core']:GetCoreObject()
            else
                QBCore = exports['qb-core']:GetCoreObject()
            end
        end
        print('^2[TPMENU]^0 Framework set to: ' .. Framework)
    end
end)

local function GetPlayerIdentifier(source)
    if Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        return xPlayer and xPlayer.identifier or nil
    elseif Framework == 'qb' or Framework == 'qbox' then
        local Player = QBCore.Functions.GetPlayer(source)
        return Player and Player.PlayerData.citizenid or nil
    end
    return nil
end

local function IsPlayerAdmin(source)
    if Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return false end
        
        local playerGroup = xPlayer.getGroup()
        for _, group in ipairs(Config.AdminGroups) do
            if playerGroup == group then
                return true
            end
        end
        return false
        
    elseif Framework == 'qb' or Framework == 'qbox' then
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return false end
        
        local permission = Player.PlayerData.job.name
        if Framework == 'qbox' then
            for _, group in ipairs(Config.AdminGroups) do
                if QBCore.Functions.HasPermission(source, group) then
                    return true
                end
            end
        else
            for _, group in ipairs(Config.AdminGroups) do
                if QBCore.Functions.HasPermission(source, group) then
                    return true
                end
            end
        end
        return false
    end
    
    return IsPlayerAceAllowed(source, 'tpmenu.admin')
end

local function GetPlayerInfo(source)
    local playerName = GetPlayerName(source)
    local playerRole = 'Citizen'
    
    if Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            playerName = xPlayer.getName()
            playerRole = xPlayer.getGroup()
        end
    elseif Framework == 'qb' or Framework == 'qbox' then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
            playerRole = Player.PlayerData.job.label or 'Unemployed'
        end
    end
    
    return {
        name = playerName,
        role = playerRole,
        isAdmin = IsPlayerAdmin(source)
    }
end

RegisterCommand(Config.Command, function(source, args, rawCommand)
    TriggerClientEvent('fearx-tpmenu:client:openMenu', source)
end, false)

RegisterNetEvent('fearx-tpmenu:server:requestData', function()
    local source = source
    local playerInfo = GetPlayerInfo(source)
    local isAdmin = IsPlayerAdmin(source)
    
    local locations = {
        general = Config.Locations.general,
        jobs = Config.Locations.jobs,
        gangs = Config.Locations.gangs,
        admin = isAdmin and Config.Locations.admin or {}
    }
    
    TriggerClientEvent('fearx-tpmenu:client:receiveData', source, {
        playerInfo = playerInfo,
        locations = locations,
        isAdmin = isAdmin
    })
end)

RegisterNetEvent('fearx-tpmenu:server:requestTeleport', function(category, locationName)
    local source = source
    local isAdmin = IsPlayerAdmin(source)
    
    if category == 'admin' and not isAdmin then
        TriggerClientEvent('fearx-tpmenu:client:notify', source, 'You do not have permission to teleport to this location!', 'error')
        return
    end
    
    local locations = Config.Locations[category]
    if not locations then
        TriggerClientEvent('fearx-tpmenu:client:notify', source, 'Invalid category!', 'error')
        return
    end
    
    local targetLocation = nil
    for _, loc in ipairs(locations) do
        if loc.name == locationName then
            targetLocation = loc
            break
        end
    end
    
    if not targetLocation then
        TriggerClientEvent('fearx-tpmenu:client:notify', source, 'Location not found!', 'error')
        return
    end
    
    TriggerClientEvent('fearx-tpmenu:client:executeTeleport', source, targetLocation.coords)
    TriggerClientEvent('fearx-tpmenu:client:notify', source, 'Teleporting to ' .. locationName .. '...', 'success')
    
    print(string.format('^2[TPMENU]^0 %s teleported to %s (%s)', GetPlayerName(source), locationName, category))
end)

ExecuteCommand('add_ace group.admin tpmenu.admin allow')
ExecuteCommand('add_ace group.mod tpmenu.admin allow')

print('^2[TPMENU]^0 Server initialized successfully')
