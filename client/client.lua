local menuOpen = false
local menuData = nil

RegisterNetEvent('fearx-tpmenu:client:openMenu', function()
    if menuOpen then return end
    
    TriggerServerEvent('fearx-tpmenu:server:requestData')
end)

RegisterNetEvent('fearx-tpmenu:client:receiveData', function(data)
    menuData = data
    menuOpen = true
    
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openMenu',
        data = data
    })
end)

RegisterNUICallback('closeMenu', function(data, cb)
    menuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'closeMenu'
    })
    cb('ok')
end)

RegisterNUICallback('teleport', function(data, cb)
    if not data.category or not data.locationName then
        cb('error')
        return
    end
    
    TriggerServerEvent('fearx-tpmenu:server:requestTeleport', data.category, data.locationName)
    
    menuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'closeMenu'
    })
    
    cb('ok')
end)

RegisterNetEvent('fearx-tpmenu:client:executeTeleport', function(coords)
    local playerPed = PlayerPedId()
    
    DoScreenFadeOut(500)
    Wait(500)
    
    SetEntityCoords(playerPed, coords.x, coords.y, coords.z, false, false, false, true)
    
    Wait(500)
    
    DoScreenFadeIn(500)
end)

RegisterNetEvent('fearx-tpmenu:client:notify', function(message, type)
    if GetResourceState('es_extended') == 'started' then
        local ESX = exports['es_extended']:getSharedObject()
        if type == 'error' then
            ESX.ShowNotification(message, 'error')
        else
            ESX.ShowNotification(message, 'success')
        end
    elseif GetResourceState('qb-core') == 'started' or GetResourceState('qbx-core') == 'started' then
        local QBCore = nil
        if GetResourceState('qbx-core') == 'started' then
            QBCore = exports['qbx-core']:GetCoreObject()
        else
            QBCore = exports['qb-core']:GetCoreObject()
        end
        if type == 'error' then
            QBCore.Functions.Notify(message, 'error')
        else
            QBCore.Functions.Notify(message, 'success')
        end
    else
        SetNotificationTextEntry('STRING')
        AddTextComponentString(message)
        DrawNotification(false, true)
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        if menuOpen then
            if IsControlJustPressed(0, 322) or IsControlJustPressed(0, 177) then
                menuOpen = false
                SetNuiFocus(false, false)
                SendNUIMessage({
                    action = 'closeMenu'
                })
            end
        else
            Wait(500)
        end
    end
end)

print('^2[TPMENU]^0 Client initialized successfully')
