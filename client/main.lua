local RSGCore = exports['rsg-core']:GetCoreObject()
local PlayerData = {}

RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent('wd_pedcharacter:server:loadSavedPed')
end)

RegisterNetEvent('wd_pedcharacter:client:applyPedModel', function(model)
	local modelHash = GetHashKey(model)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Citizen.Wait(0)
    end
    SetPlayerModel(PlayerId(), modelHash, true)
    SetRandomOutfitVariation(PlayerId(), true)
    SetModelAsNoLongerNeeded(modelHash)

end)

local function spawnPedMenu()
    local options = {}
    for _, ped in ipairs(Config.Peds) do
        table.insert(options, {
            title = ped,
            event = 'wd_pedcharacter:client:spawnPed',
            args = ped
        })
    end
    lib.registerContext({
        id = 'wd_pedcharacter_ped_menu',
        title = 'Select Ped',
        options = options
    })
    lib.showContext('wd_pedcharacter_ped_menu')
end

local function spawnAnimalMenu()
    local options = {}
    for _, animal in ipairs(Config.Animals) do
        table.insert(options, {
            title = animal,
            event = 'wd_pedcharacter:client:spawnAnimal',
            args = animal
        })
    end
    lib.registerContext({
        id = 'wd_pedcharacter_animal_menu',
        title = 'Select Animal',
        options = options
    })
    lib.showContext('wd_pedcharacter_animal_menu')
end

local function openMainMenu()
    lib.registerContext({
        id = 'wd_pedcharacter_main_menu',
        title = 'Ped Character',
        options = {
            {
                title = 'Select Ped',
                event = 'wd_pedcharacter:client:spawnPedMenu'
            },
            {
                title = 'Select Animal',
                event = 'wd_pedcharacter:client:spawnAnimalMenu'
            },
            {
                title = 'Load Saved',
                serverEvent = 'wd_pedcharacter:server:loadSavedPed'
            },
            {
                title = 'Delete Saved',
                serverEvent = 'wd_pedcharacter:server:deleteSavedPed'
            }
        }
    })
    lib.showContext('wd_pedcharacter_main_menu')
end

AddEventHandler('wd_pedcharacter:client:spawnPedMenu', function()
    spawnPedMenu()
end)

AddEventHandler('wd_pedcharacter:client:spawnAnimalMenu', function()
    spawnAnimalMenu()
end)

RegisterNetEvent('wd_pedcharacter:client:spawnPed', function(model)
    local modelHash = GetHashKey(model)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Citizen.Wait(0)
    end
    SetPlayerModel(PlayerId(), modelHash, true)
    SetRandomOutfitVariation(PlayerId(), true)
    SetModelAsNoLongerNeeded(modelHash)

    
    lib.registerContext({
        id = 'wd_pedcharacter_save_confirmation',
        title = 'Save to Character ID?',
        options = {
            {
                title = 'Yes',
                serverEvent = 'wd_pedcharacter:server:savePed',
                args = model
            },
            {
                title = 'No',
                event = 'wd_pedcharacter:client:confirmationClosed'
            }
        }
    })
    lib.showContext('wd_pedcharacter_save_confirmation')
end)

RegisterNetEvent('wd_pedcharacter:client:spawnAnimal', function(model)
    local modelHash = GetHashKey(model)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Citizen.Wait(0)
    end
    SetPlayerModel(PlayerId(), modelHash, true)
    SetRandomOutfitVariation(PlayerId(), true)
    SetModelAsNoLongerNeeded(modelHash)
    lib.registerContext({
        id = 'wd_pedcharacter_save_confirmation',
        title = 'Save to Character ID?',
        options = {
            {
                title = 'Yes',
                serverEvent = 'wd_pedcharacter:server:savePed',
                args = model
            },
            {
                title = 'No',
                event = 'wd_pedcharacter:client:confirmationClosed'
            }
        }
    })
    lib.showContext('wd_pedcharacter_save_confirmation')
end)

RegisterNetEvent('wd_pedcharacter:client:confirmationClosed', function()
    RSGCore.Functions.Notify('Ped model not saved.', 'info')
end)

RegisterCommand('pedchar', function()
    TriggerServerEvent('wd_pedcharacter:server:checkPermission')
    RSGCore.Functions.Notify('Checking perms', 'info')
end, false)

RegisterNetEvent('wd_pedcharacter:client:openPedCharacterMenu', function()
    openMainMenu()
end)

-- lto_pedmenu

local IsAnimal = false
local IsAttacking = false

function SetControlContext(pad, context)
	Citizen.InvokeNative(0x2804658EB7D8A50B, pad, context)
end

function GetPedCrouchMovement(ped)
	return Citizen.InvokeNative(0xD5FE956C70FF370B, ped)
end

function SetPedCrouchMovement(ped, state, immediately)
	Citizen.InvokeNative(0x7DE9692C6F64CFE8, ped, state, immediately)
end

function PlayAnimation(anim)
	if not DoesAnimDictExist(anim.dict) then
		print("Invalid animation dictionary: " .. anim.dict)
		return
	end

	RequestAnimDict(anim.dict)

	while not HasAnimDictLoaded(anim.dict) do
		Citizen.Wait(0)
	end

	TaskPlayAnim(PlayerPedId(), anim.dict, anim.name, 4.0, 4.0, -1, 0, 0.0, false, false, false, "", false)

	RemoveAnimDict(anim.dict)
end

function IsPvpEnabled()
	return GetRelationshipBetweenGroups(`PLAYER`, `PLAYER`) == 5
end

function IsValidTarget(ped)
	return not IsPedDeadOrDying(ped) and not (IsPedAPlayer(ped) and not IsPvpEnabled())
end

function GetClosestPed(playerPed, radius)
	local playerCoords = GetEntityCoords(playerPed)

	local itemset = CreateItemset(true)
	local size = Citizen.InvokeNative(0x59B57C4B06531E1E, playerCoords, radius, itemset, 1, Citizen.ResultAsInteger())

	local closestPed
	local minDist = radius

	if size > 0 then
		for i = 0, size - 1 do
			local ped = GetIndexedItemInItemset(i, itemset)

			if playerPed ~= ped and IsValidTarget(ped) then
				local pedCoords = GetEntityCoords(ped)
				local distance = #(playerCoords - pedCoords)

				if distance < minDist then
					closestPed = ped
					minDist = distance
				end
			end
		end
	end

	if IsItemsetValid(itemset) then
		DestroyItemset(itemset)
	end

	return closestPed
end

function MakeEntityFaceEntity(entity1, entity2)
	local p1 = GetEntityCoords(entity1)
	local p2 = GetEntityCoords(entity2)

	local dx = p2.x - p1.x
	local dy = p2.y - p1.y

	local heading = GetHeadingFromVector_2d(dx, dy)

	SetEntityHeading(entity1, heading)
end

function GetAttackType(playerPed)
	local playerModel = GetEntityModel(playerPed)

	for _, attackType in ipairs(Config.AttackTypes) do
		for _, model in ipairs(attackType.models) do
			if playerModel == model then
				return attackType
			end
		end
	end
end

function ApplyAttackToTarget(attacker, target, attackType)
	if attackType.force > 0 then
		SetPedToRagdoll(target, 1000, 1000, 0, 0, 0, 0)
		SetEntityVelocity(target, GetEntityForwardVector(attacker) * attackType.force)
	end

	if attackType.damage > 0 then
		ApplyDamageToPed(target, attackType.damage, 1, -1, 0)
	end
end

function GetPlayerServerIdFromPed(ped)
	for _, player in ipairs(GetActivePlayers()) do
		if GetPlayerPed(player) == ped then
			return GetPlayerServerId(player)
		end
	end
end

function Attack()
	if IsAttacking then
		return
	end

	local playerPed = PlayerPedId()

	if IsPedDeadOrDying(playerPed) or IsPedRagdoll(playerPed) then
		return
	end

	local attackType = GetAttackType(playerPed)

	if attackType then
		local target = GetClosestPed(playerPed, attackType.radius)

		if target then
			IsAttacking = true

			MakeEntityFaceEntity(playerPed, target)

			PlayAnimation(attackType.animation)

			if IsPedAPlayer(target) then
				TriggerServerEvent("fixanimals:attack", GetPlayerServerIdFromPed(target), -1)
			elseif NetworkGetEntityIsNetworked(target) and not NetworkHasControlOfEntity(target) then
				TriggerServerEvent("fixanimals:attack", -1, PedToNet(target))
			else
				ApplyAttackToTarget(playerPed, target, attackType)
			end

			Citizen.SetTimeout(Config.AttackCooldown, function()
				IsAttacking = false
			end)
		end
	end
end

function ToggleCrouch()
	local playerPed = PlayerPedId()

	SetPedCrouchMovement(playerPed, not GetPedCrouchMovement(playerPed), true)
end

AddEventHandler("fixanimals:attack", function(attacker, entity)
	local attackerPed = GetPlayerPed(GetPlayerFromServerId(attacker))
	local attackType = GetAttackType(attackerPed)

	if entity == -1 then
		if IsPvpEnabled() then
			ApplyAttackToTarget(attackerPed, PlayerPedId(), attackType)
		end
	else
		ApplyAttackToTarget(attackerPed, NetToPed(entity), attackType)
	end
end)


Citizen.CreateThread(function()
	local lastPed = 0

	while true do
		local ped = PlayerPedId()

		if ped ~= lastPed then
			if IsPedHuman(ped) then
				SetControlContext(2, 0)
				IsAnimal = false
			else

				SetPedConfigFlag(ped, 43, true)
				IsAnimal = true
			end

			lastPed = ped
		end

		Citizen.Wait(1000)
	end
end)


Citizen.CreateThread(function()
	while true do
		if IsAnimal then

			SetControlContext(2, `OnMount`)

			DisableFirstPersonCamThisFrame()


			if IsControlJustPressed(0, `INPUT_ATTACK`) then
				Attack()
			end

			if IsControlJustPressed(0, `INPUT_HORSE_MELEE`) then
				ToggleCrouch()
			end
		end

		Citizen.Wait(0)
	end
end)