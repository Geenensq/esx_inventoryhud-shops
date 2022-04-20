ESX = nil
local hasAlreadyEnteredMarker = false
local lastZone, currentAction, shopId

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent("esx:getSharedObject", function(obj)
            ESX = obj
        end)
        Citizen.Wait(0)
    end
end)

AddEventHandler('esx_inventoryhud_shops:hasEnteredMarker', function(zone)
    currentAction = 'shop_menu'
    currentActionData = {}
end)

AddEventHandler('esx_inventoryhud_shops:hasExitedMarker', function(zone)
    ESX.UI.Menu.CloseAll()
    currentAction = nil
end)

-- Create Blips
Citizen.CreateThread(function()
    for k, v in ipairs(Config.Shops) do
        local type = v.type
        local hidden = v.hidden
        local sprite
        local title
        local color

        if not hidden then
            if type == 'shop' then
                sprite = 59
                title = 'Supérette'
                color = 25
            elseif type == 'weapon' then
                title = 'Armurerie'
                sprite = 110
                color = 64
            elseif type == 'weed' then
                title = 'Magasin de culture'
                sprite = 140
                color = 25
            elseif type == 'hunt' then
                title = 'Revente abatoir'
                sprite = 442
                color = 27
            elseif type == 'others' then
                title = 'Quincaillerie'
                sprite = 59
                color = 17
            elseif type == 'apple' then
                title = 'Apple'
                sprite = 76
                color = 0
            elseif type == 'ferm' then
                title = 'Revente ferme'
                sprite = 417
                color = 33
            elseif type == 'chicken' then
                title = 'Revente Cluckin\'Bell'
                sprite = 89
                color = 81
            elseif type == 'parachute' then
                title = 'Saut en parachute'
                sprite = 94
                color = 25
            end

            local blip = AddBlipForCoord(v.coords)
            SetBlipSprite(blip, sprite)
            SetBlipColour(blip, color)
            SetBlipAsShortRange(blip, true)
            SetBlipScale(blip, 0.7)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(title)
            EndTextCommandSetBlipName(blip)
        end
    end
end)

-- Enter / Exit marker events & draw markers
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1)
        local playerCoords, isInMarker, currentZone, letSleep = GetEntityCoords(PlayerPedId()), false, nil, true

        for k, v in pairs(Config.Shops) do
            local distance = #(playerCoords - v.coords)

            if distance < Config.DrawDistance then
                letSleep = false
                DrawText3Ds(v.coords.x, v.coords.y, v.coords.z, "~r~[E]~s~ pour Acheter/Vendre des produits")
                if distance < Config.MarkerSize.x then
                    isInMarker, currentZone = true, k
                    shopId = v.id
                end
            end
        end

        if (isInMarker and not hasAlreadyEnteredMarker) or (isInMarker and lastZone ~= currentZone) then
            hasAlreadyEnteredMarker, lastZone = true, currentZone
            TriggerEvent('esx_inventoryhud_shops:hasEnteredMarker', currentZone)
        end

        if not isInMarker and hasAlreadyEnteredMarker then
            hasAlreadyEnteredMarker = false
            TriggerEvent('esx_inventoryhud_shops:hasExitedMarker', currentZone)
        end

        if letSleep then
            Citizen.Wait(500)
        end
    end
end)

-- Key controls
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if currentAction then
            if IsControlJustReleased(0, 38) then
                if currentAction == 'shop_menu' then
                    openStoreMenu()
                end
                currentAction = nil
            end
        else
            Citizen.Wait(500)
        end
    end
end)

function openStoreMenu()
    TriggerEvent("mythic_progbar:client:progress", {
        name = "Open_Trunk",
        duration = 500,
        label = 'Ouverture du magasin',
        useWhileDead = false,
        canCancel = true,
        controlDisables = {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true
        }
    }, function(status)
        if not status then
            local items
            local jobBuy = nil
            local stocksForShop

            ESX.TriggerServerCallback('esx_inventoryhud_shops:getStockItem', function(result)
                stocksForShop = result

                for k, v in pairs(Config.Shops) do
                    if Config.Shops[k].id == shopId then
                        items = Config.Shops[k].items

                        for i, v in ipairs(items) do
                            items[i].stock = stocksForShop[items[i].name] or 0;
                        end

                        if Config.Shops[k].jobBuy then
                            jobBuy = Config.Shops[k].jobBuy
                        end
                    end
                end

                TriggerEvent("esx_inventoryhud:openShop", 'custom', items, shopId, jobBuy)

            end, shopId)
        end
    end
    )

end

-- Function for 3D text:
function DrawText3Ds(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    SetTextScale(0.32, 0.32)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 255)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
    local factor = (string.len(text)) / 500
    DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 0, 0, 0, 80)
end



