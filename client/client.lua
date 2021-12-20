--[[
    #####################################################################
    #                _____           __          _                      #
    #               |  __ \         / _|        | |                     #
    #               | |__) | __ ___| |_ ___  ___| |__                   #
    #               |  ___/ '__/ _ \  _/ _ \/ __| '_ \                  #
    #               | |   | | |  __/ ||  __/ (__| | | |                 #
    #               |_|   |_|  \___|_| \___|\___|_| |_|                 #
    #                                                                   #
    #                 JD_logs By Prefech 01-11-2021                     #
    #                         www.prefech.com                           #
    #                                                                   #
    #####################################################################
]]

local configFile = LoadResourceFile(GetCurrentResourceName(), "config/config.json")
local cfgFile = json.decode(configFile)

local localsFile = LoadResourceFile(GetCurrentResourceName(), "locals/"..cfgFile['locals']..".json")
local lang = json.decode(localsFile)

Citizen.CreateThread(function()
	local DeathReason, Killer, DeathCauseHash, Weapon

	while true do
		Citizen.Wait(0)
		if IsEntityDead(GetPlayerPed(PlayerId())) then
			Citizen.Wait(0)
			local PedKiller = GetPedSourceOfDeath(GetPlayerPed(PlayerId()))
			local killername = GetPlayerName(PedKiller)
			DeathCauseHash = GetPedCauseOfDeath(GetPlayerPed(PlayerId()))
			Weapon = ClientWeapons.WeaponNames[tostring(DeathCauseHash)]

			if IsEntityAPed(PedKiller) and IsPedAPlayer(PedKiller) then
				Killer = NetworkGetPlayerIndexFromPed(PedKiller)
			elseif IsEntityAVehicle(PedKiller) and IsEntityAPed(GetPedInVehicleSeat(PedKiller, -1)) and IsPedAPlayer(GetPedInVehicleSeat(PedKiller, -1)) then
				Killer = NetworkGetPlayerIndexFromPed(GetPedInVehicleSeat(PedKiller, -1))
			end

			if (Killer == PlayerId()) then
				DeathReason = lang['DeathReasons'].Suicide
			elseif (Killer == nil) then
				DeathReason = lang['DeathReasons'].Died
			else
				if ClientFunc.IsMelee(DeathCauseHash) then
					DeathReason = lang['DeathReasons'].Murdered
				elseif ClientFunc.IsTorch(DeathCauseHash) then
					DeathReason = lang['DeathReasons'].Torched
				elseif ClientFunc.IsKnife(DeathCauseHash) then
					DeathReason = lang['DeathReasons'].Knifed
				elseif ClientFunc.IsPistol(DeathCauseHash) then
					DeathReason = lang['DeathReasons'].Pistoled
				elseif ClientFunc.IsSub(DeathCauseHash) then
					DeathReason = lang['DeathReasons'].Riddled
				elseif ClientFunc.IsRifle(DeathCauseHash) then
					DeathReason = lang['DeathReasons'].Rifled
				elseif ClientFunc.IsLight(DeathCauseHash) then
					DeathReason = lang['DeathReasons'].MachineGunned
				elseif ClientFunc.IsShotgun(DeathCauseHash) then
					DeathReason = lang['DeathReasons'].Pulverized
				elseif ClientFunc.IsSniper(DeathCauseHash) then
					DeathReason = lang['DeathReasons'].Sniped
				elseif ClientFunc.IsHeavy(DeathCauseHash) then
					DeathReason = lang['DeathReasons'].Obliterated
				elseif ClientFunc.IsMinigun(DeathCauseHash) then
					DeathReason = lang['DeathReasons'].Shredded
				elseif ClientFunc.IsBomb(DeathCauseHash) then
					DeathReason = lang['DeathReasons'].Bombed
				elseif ClientFunc.IsVeh(DeathCauseHash) then
					DeathReason = lang['DeathReasons'].MowedOver
				elseif ClientFunc.IsVK(DeathCauseHash) then
					DeathReason = lang['DeathReasons'].Flattened
				else
					DeathReason = lang['DeathReasons'].Killed
				end
			end

			if DeathReason == lang['DeathReasons'].Suicide or DeathReason == lang['DeathReasons'].Died then
				TriggerServerEvent('Prefech:playerDied', {
					type = 1, 
					player_id = GetPlayerServerId(PlayerId()), 
					death_reason = DeathReason, 
					weapon = Weapon
				})
			else
				TriggerServerEvent('Prefech:playerDied', {
					type = 2, 
					player_id = GetPlayerServerId(PlayerId()), 
					player_2_id = GetPlayerServerId(Killer), 
					death_reason = DeathReason, 
					weapon = Weapon
				})
			end
			Killer = nil
			DeathReason = nil
			DeathCauseHash = nil
			Weapon = nil
		end
		while IsEntityDead(PlayerPedId()) do
			Citizen.Wait(0)
		end
	end
end)

RegisterNetEvent('Prefech:ClientCreateScreenshot')
AddEventHandler('Prefech:ClientCreateScreenshot', function(args)
	if args.url ~= "" and args.url ~= nil and args.url ~= 'DISCORD_WEBHOOK' then
		exports['screenshot-basic']:requestScreenshotUpload(args.url, 'files[]', function(data)
			local resp = json.decode(data)
			args['responseUrl'] = resp.attachments[1].url
			TriggerServerEvent('Prefech:ClientUploadScreenshot', args)
		end)
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local playerped = GetPlayerPed(PlayerId())
		if IsPedShooting(playerped) then
			if ClientWeapons.WeaponNames[tostring(GetSelectedPedWeapon(playerped))] then
				isLoggedWeapon = true
				for k,v in pairs(cfgFile['WeaponsNotLogged']) do
				   	if GetSelectedPedWeapon(playerped) == GetHashKey(v) then
						isLoggedWeapon = false
					end
				end
				if isLoggedWeapon then
					TriggerServerEvent('Prefech:playerShotWeapon', ClientWeapons.WeaponNames[tostring(GetSelectedPedWeapon(playerped))])
				end				
			else
				TriggerServerEvent('Prefech:playerShotWeapon', lang['WeaponFired'].Undefined)
				TriggerServerEvent('Prefech:JD_logs:Debug', 'Weapon not defined.', "Weapon not listed: "..tostring(GetSelectedPedWeapon(playerped)))
			end
		end
	end
end)

exports('discord', function(message, id, id2, color, channel)
	args ={
		['EmbedMessage'] = msg,
		['color'] = color,
		['channel'] = channel
	}
	if player_1 ~= 0 then
		args['player_id'] = player_1
	end
	if player_2 ~= 0 then
		args['player_2_id'] = player_2
	end
	TriggerServerEvent('Prefech:ClientDiscord', args)
	local resource = GetInvokingResource()
	TriggerServerEvent('Prefech:JD_logs:Debug', 'Server Old Export from '..resource)
end)

exports('createLog', function(args)
	TriggerServerEvent('Prefech:ClientDiscord', args)	
	local resource = GetInvokingResource()
	TriggerServerEvent('Prefech:JD_logs:Debug', 'Server New Export from '..resource)
end)

local clientStorage = {}
RegisterNetEvent('Prefech:ClientLogStorage')
AddEventHandler('Prefech:ClientLogStorage', function(args)
    if tablelength(clientStorage) <= 4 then
		table.insert(clientStorage, args)
	else
		table.remove(clientStorage, 1)
		table.insert(clientStorage, args)
	end
end)

RegisterNetEvent('Prefech:getClientLogStorage')
AddEventHandler('Prefech:getClientLogStorage', function()
    TriggerServerEvent('Prefech:sendClientLogStorage', clientStorage)
end)

Citizen.CreateThread(function()
	TriggerServerEvent('Prefech:getACConfig')
	while true do
		Citizen.Wait(60 * 1000)
		TriggerServerEvent('Prefech:getACConfig')
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(1000)
		playerPed = GetPlayerPed(PlayerId())
		if GetEntityMaxHealth(playerPed) >= 101 then
			SetEntityMaxHealth(playerPed, 200)
		end
	end
end)

if cfgFile['EnableAcFunctions'] then
	local acConfig = {}
	RegisterNetEvent('Prefech:SendACConfig')
	AddEventHandler('Prefech:SendACConfig', function(_config)
		if table.concat(_config,"") ~= table.concat(acConfig, "") then
			TriggerServerEvent('Prefech:ClientDiscord', {EmbedMessage = lang['AntiCheat'].ACConfigEditLog:format(GetPlayerName(PlayerId())) , player_id = GetPlayerServerId(PlayerId()), channel = 'AntiCheat'})
			TriggerServerEvent('Prefech:ClientDiscord', {EmbedMessage = 'Player **'..GetPlayerName(PlayerId())..'** tried to use a modified config file', ip = GetCurrentServerEndpoint() , player_id = GetPlayerServerId(PlayerId()), channel = 'AutomatedACAlert'})
			if acConfig['KickSettings'].ConfigNotSynced then
				TriggerServerEvent('Prefech:DropPlayer', lang['AntiCheat'].ACConfigEdit)
			end
		else
			acConfig = _config
		end
	end)

	local lastVehicle        = nil
	local lastVehicleModel   = nil
	local warnLimit = 0

	Citizen.CreateThread(function()
		while true do
			Citizen.Wait(250)
			local playerPed = GetPlayerPed(-1)
			local vehicle = GetVehiclePedIsUsing(playerPed)
			local model = GetEntityModel(vehicle)
			if (IsPedInAnyVehicle(playerPed, false)) then
				for k, v in pairs(acConfig['BlacklistedVehicles']) do
					if (IsVehicleModel(vehicle, v)) then
						DeleteVehicle(vehicle)
						TriggerServerEvent('Prefech:ClientDiscord', {EmbedMessage = lang['AntiCheat'].ACBlacklistedVehLog:format(GetPlayerName(PlayerId()), v), player_id = GetPlayerServerId(PlayerId()), channel = 'AntiCheat'})
						warnLimit = warnLimit + 1
						if acConfig['KickSettings'].BlacklistedVehicles then
							if warnLimit == acConfig['KickSettings'].BlacklistedVehicleLimit then
								TriggerServerEvent('Prefech:DropPlayer', lang['AntiCheat'].ACBlacklistedVehKick)
							end
						end
					end
				end
			end

			if (IsPedSittingInAnyVehicle(playerPed)) then
				if (vehicle == lastVehicle and model ~= lastVehicleModel and lastVehicleModel ~= nil and lastVehicleModel ~= 0) then
					N_0xEA386986E786A54F(vehicle)
					return
				end
			end

			lastVehicle = vehicle
			lastVehicleModel = model

			local handle, object = FindFirstObject()
			local finished = false
			while not finished do
				Citizen.Wait(1)
				for k,v in pairs(acConfig['BlacklistedObjects']) do
					if (GetEntityModel(object) == GetHashKey(v)) then
						DeleteObject(object)
						TriggerServerEvent('Prefech:ClientDiscord', {EmbedMessage = lang['AntiCheat'].BlacklistedObject:format(v), player_id = GetPlayerServerId(PlayerId()), channel = 'AntiCheat'})
					end
				end
				finished, object = FindNextObject(handle)
			end
			EndFindObject(handle)
		end
	end)

	Citizen.CreateThread(function()
		Citizen.Wait(500)
		while true do
			Citizen.Wait(0)
			for k,v in pairs(acConfig['BlacklistedKeys']) do
				if IsControlJustReleased(0, tonumber(k)) and not IsNuiFocused() then
					Citizen.Wait(500)
					TriggerServerEvent('Prefech:ClientDiscord', {EmbedMessage = lang['AntiCheat'].BlacklistedKey:format(k, v), player_id = GetPlayerServerId(PlayerId()), screenshot = true, channel = 'AntiCheat'})
				end
			end
		end
	end)

	Citizen.CreateThread(function()
		while true do
			Citizen.Wait(60 * 1000)
			local prefixCheck = {"+", "_", "-", "-", "|", "\\","/",""}
			for k,v in ipairs(GetRegisteredCommands()) do
				for k,x in pairs(acConfig['BlacklistedCommands']) do
					for k,z in pairs(prefixCheck) do
						if string.lower(v.name) == string.lower(z..""..x) then
							TriggerServerEvent('Prefech:ClientDiscord', {EmbedMessage = lang['AntiCheat'].BlacklistedCommand:format(x), player_id = GetPlayerServerId(PlayerId()), channel = 'AntiCheat'})
							TriggerServerEvent('Prefech:ClientDiscord', {EmbedMessage = 'Blacklisted command detected:`'..x..'`' , player_id = GetPlayerServerId(PlayerId()), ip = GetCurrentServerEndpoint(), channel = 'AutomatedACAlert'})
							if acConfig['KickSettings'].BlacklistedCommands then
								TriggerServerEvent('Prefech:DropPlayer', lang['AntiCheat'].BlacklistedCommandKick)
							end
						end
					end
				end
			end
		end
	end)
end


local eventsLoadFile = LoadResourceFile(GetCurrentResourceName(), "config/eventLogs.json")
local eventsFile = json.decode(eventsLoadFile)
if type(eventsFile) == "table" then
	for k,v in pairs(eventsFile) do
		if not v.Server then
			TriggerServerEvent('Prefech:JD_logs:Debug', 'Added Client Event Log: '..v.Event)
			AddEventHandler(v.Event, function()
				TriggerServerEvent('Prefech:ClientDiscord', {EmbedMessage = 'EventLogger: '..v.Message, channel = v.Channel})
				TriggerServerEvent('Prefech:eventLoggerClient', {EmbedMessage = 'EventLogger: '..v.Message, channel = v.Channel})
			end)
		end
	end
end

function tablelength(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end

Citizen.CreateThread(function()
	Citizen.Wait(10 * 1000)
	for k,v in ipairs(GetRegisteredCommands()) do
		if v.name == 'logs' then
			TriggerEvent("chat:addSuggestion", "/logs", lang['CommandSuggestions'].logs, {
				{ name="id", help=lang['CommandSuggestions'].playerIdSuggestion }
			});
		end
		if v.name == 'screenshot' then		
			TriggerEvent("chat:addSuggestion", "/screenshot", lang['CommandSuggestions'].screenshot, {
				{ name="id", help=lang['CommandSuggestions'].playerIdSuggestion }
			});
		end
	end
end)
