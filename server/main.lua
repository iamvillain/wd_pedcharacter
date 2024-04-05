local RSGCore = exports['rsg-core']:GetCoreObject()
local oxmysql = exports.oxmysql

-- Create character_peds table if it doesn't exist
oxmysql:query([[
    CREATE TABLE IF NOT EXISTS character_peds (
        citizenid VARCHAR(255) PRIMARY KEY,
        ped_model VARCHAR(255)
    )
]], {}, function(result)
    if result.warningStatus == 0 then
        print("character_peds table created successfully!")
    else
        print("[wd_pedchar] Table already exists, dont need to make it!")
    end
end)

local function getPlayerDiscordId(playerId)
    local identifier = GetPlayerIdentifierByType(playerId, 'discord')
    if identifier then
        return string.sub(identifier, 9)
    end
    return nil
end

local function hasPermission(discordId)
    for _, id in ipairs(Config.AllowedDiscordID) do
        if id == discordId then
            return true
        end
    end
    return false
end

local function savePedModel(citizenid, model)
    oxmysql:update("REPLACE INTO character_peds (citizenid, ped_model) VALUES (?, ?)", { citizenid, model })
end

RegisterNetEvent('wd_pedcharacter:server:checkPermission', function()
    local playerId = source
    local discordId = getPlayerDiscordId(playerId)
    if discordId and hasPermission(discordId) then
        TriggerClientEvent('wd_pedcharacter:client:openPedCharacterMenu', playerId)
    else
        RSGCore.Functions.Notify(playerId, 'You do not have permission to use this command.', 'error')
    end
end)

RegisterNetEvent('wd_pedcharacter:server:savePed', function(model)
    local playerId = source
    local Player = RSGCore.Functions.GetPlayer(playerId)
    local citizenid = Player.PlayerData.citizenid
    
    if citizenid then
        savePedModel(citizenid, model)
        RSGCore.Functions.Notify(playerId, 'Ped model saved.', 'success')
    end
end)

RegisterNetEvent('wd_pedcharacter:server:deleteSavedPed', function()
    local playerId = source
    local Player = RSGCore.Functions.GetPlayer(playerId)
    local citizenid = Player.PlayerData.citizenid
    if citizenid then
        oxmysql:update("DELETE FROM character_peds WHERE citizenid = ?", { citizenid })
        RSGCore.Functions.Notify(playerId, 'Saved ped model deleted.', 'success')
    end
end)

RegisterNetEvent('wd_pedcharacter:server:loadSavedPed', function()
    local playerId = source
    local Player = RSGCore.Functions.GetPlayer(playerId)
    local citizenid = Player.PlayerData.citizenid
    if citizenid then
        local result = MySQL.query.await("SELECT ped_model FROM character_peds WHERE citizenid = ?", { citizenid })
        if result and result[1] and result[1].ped_model then
            TriggerClientEvent('wd_pedcharacter:client:applyPedModel', playerId, result[1].ped_model)
        else
            RSGCore.Functions.Notify(playerId, 'You dont have a saved ped.', 'error')
        end
    end
end)

-- lto_pedmenu

RegisterNetEvent("fixanimals:attack")
AddEventHandler("fixanimals:attack", function(target, entity)
	TriggerClientEvent("fixanimals:attack", target, source, entity)
end)
