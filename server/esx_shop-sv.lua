ESX = nil

TriggerEvent("esx:getSharedObject", function(obj)
    ESX = obj
end)

RegisterServerEvent("esx_inventoryhud_shops:sellItemShop")
AddEventHandler("esx_inventoryhud_shops:sellItemShop", function(itemName, itemCount, shopId, itemType, playerId)
    local _source = source
    local XPlayer = ESX.GetPlayerFromId(source)
    local maxStock = 0
    local itemFound = false
    local priceItem

    if itemType == 'item_standard' then
        if XPlayer.getInventoryItem(itemName).count >= itemCount then
        else
            TriggerClientEvent('mythic_notify:client:SendAlert', _source, { type = 'error', text = 'Vous n\'en avez pas assez sur vous.', })
            return
        end
    end

    MySQL.Async.fetchAll("SELECT * FROM shop_inventory WHERE shop = @shop", { ['@shop'] = shopId }, function(data)
        if data[1].data ~= nil then
            local currentStock = json.decode(data[1].data)
            for k, v in pairs(Config.Shops) do
                if Config.Shops[k].id == shopId then
                    items = Config.Shops[k].items
                    for k2, v2 in pairs(items) do
                        if items[k2].name == itemName then
                            itemFound = true
                            maxStock = items[k2].maxStock
                            priceItem = items[k2].price
                        end
                    end
                end
            end

            if itemFound then
                if currentStock[itemName] + itemCount <= maxStock then
                    currentStock[itemName] = currentStock[itemName] + itemCount

                    MySQL.Sync.execute("UPDATE shop_inventory SET data = @data WHERE shop = @shop", {
                        ['@data'] = json.encode(currentStock),
                        ['@shop'] = shopId
                    })
                    local money = ESX.Math.Round(priceItem / 100 * 70)
                    if itemType == 'item_standard' then
                        XPlayer.removeInventoryItem(itemName, itemCount)
                    else
                        XPlayer.removeWeapon(itemName)
                    end

                    local xp = 1 * itemCount

                    XPlayer.addMoney(money * itemCount)
                    TriggerClientEvent('mythic_notify:client:SendAlert', _source, { type = 'success', text = 'Produit vendu à la boutique.', })
                    TriggerEvent('BattlePass-Server:AddXP', xp,  playerId)
                else
                    TriggerClientEvent('mythic_notify:client:SendAlert', _source, { type = 'error', text = 'Le magasin à deja trop de stock pour ce produit.', })
                end
            else
                TriggerClientEvent('mythic_notify:client:SendAlert', _source, { type = 'error', text = 'Le magasin ne rachète pas cet objet.', })
            end
        end
    end)
end)

RegisterServerEvent("esx_inventoryhud_shops:getStockItem")
AddEventHandler("esx_inventoryhud_shops:getStockItem", function(shopId, cb)
    MySQL.Async.fetchAll("SELECT * FROM shop_inventory WHERE shop = @shop", { ['@shop'] = shopId }, function(data)
        if data[1].data ~= nil then
            local currentStock = json.decode(data[1].data)
            cb(currentStock)
        end
    end)
end)

RegisterServerEvent("esx_inventoryhud_shops:decrementStockItem")
AddEventHandler("esx_inventoryhud_shops:decrementStockItem", function(shopId, item, amount)
    MySQL.Async.fetchAll("SELECT * FROM shop_inventory WHERE shop = @shop", { ['@shop'] = shopId }, function(data)
        if data[1].data ~= nil then
            local currentStock = json.decode(data[1].data)
            currentStock[item] = currentStock[item] - amount
            MySQL.Sync.execute("UPDATE shop_inventory SET data = @data WHERE shop = @shop", {
                ['@data'] = json.encode(currentStock),
                ['@shop'] = shopId
            })
        end
    end)
end)

ESX.RegisterServerCallback("esx_inventoryhud_shops:getStockItem", function(source, cb, shopId)
    MySQL.Async.fetchAll("SELECT * FROM shop_inventory WHERE shop = @shop", { ['@shop'] = shopId }, function(data)
        if data[1].data ~= nil then
            local currentStock = json.decode(data[1].data)
            cb(currentStock)
        end
    end)
end)
