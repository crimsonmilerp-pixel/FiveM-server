local allowlistArray = {}
local readFile = LoadResourceFile(GetCurrentResourceName(), GetConvar('nc.allowlist', 'allowlist.json'))
local deniedMessage = GetConvar('nc.deniedMessage', 'You are not allowed to join this server.')
local checkingMessage = GetConvar('nc.checkingMessage', 'Checking allowlist...')
local progressMessage = GetConvar('nc.progressMessage', 'Checking allowlist: %.2f%%')
local enableAllowlist = GetConvarBool('nc.enableAllowlist', true)

function printAsciiMessageBox(message)
	local length = string.len(message)
	local top = '╔' .. string.rep('═', length + 2) .. '╗'
	local middle = '║ ' .. message .. ' ║'
	local bottom = '╚' .. string.rep('═', length + 2) .. '╝'
	print(top)
	print(middle)
	print(bottom)
end

if not enableAllowlist then
	printAsciiMessageBox('Allowlist is disabled')
end

-- Function for reloading our allowList
function reloadAllowlist()
	local allowlistFile = LoadResourceFile(GetCurrentResourceName(), GetConvar('nc.allowlist', 'allowlist.json'))
	if allowlistFile then
		allowlistArray = json.decode(allowlistFile)
		print('Allowlist reloaded. Found ' .. #allowlistArray .. ' entries.')
	else
		print('Failed to reload allowlist.')
	end
end

if readFile and enableAllowlist then
	reloadAllowlist()
end

AddEventHandler('playerDropped', function()
	local player = source
	local identifiers = GetPlayerIdentifiers(player)
	local license

	Wait(0)

	for _, v in pairs(identifiers) do
		if string.find(v, 'license') then
			license = v
			break
		end
	end

	print('Dropped: ' .. license)
end)

-- https://docs.fivem.net/docs/scripting-reference/events/list/playerConnecting/
AddEventHandler('playerConnecting', function(name, setReason, deferrals)
	local identMap = {}
	local player = source
	local identifiers = GetPlayerIdentifiers(player)
	for i = 1, #identifiers do
		local ident = identifiers[i]
		local colonPos = string.find(ident, ':') - 1
		local identType = string.sub(ident, 1, colonPos)
		identMap[identType] = ident
	end
	local license = identMap['license']
	if not enableAllowlist then
		-- Don't ever defer if allowlist is disabled
		-- If we and another resource defer at the same time, players will just never connect
		print('Connecting: ' .. name .. ' (' .. license .. ')') -- Still print for player tracking
		return
	end

	deferrals.defer()
	local allowed = false
	deferrals.update(checkingMessage)

	Wait(0) -- must wait for 1 tick after doing an action on a deferral

	-- We'll set a bunch of variables here for doing updates
	local totalAllowed = #allowlistArray
	local playersIdentifiers = #identifiers
	local currentIdCheck = 0
	local totalChecksNeeded = totalAllowed * playersIdentifiers

	-- Loop through our player's identifiers
	for identifierIndex, identifier in pairs(identifiers) do
		-- Now loop the allowlist
		for allowListIndex, allowListEntry in ipairs(allowlistArray) do
			if string.lower(allowListEntry) == string.lower(identifier) then
				deferrals.done()
				allowed = true
				print(string.format('Player %s is allowlisted. Allowing connection...', name))
				break
			end

			deferrals.update(string.format(progressMessage, (currentIdCheck / totalChecksNeeded) * 100))
			currentIdCheck = currentIdCheck + 1
		end
	end
	if allowed then
		-- Find a license to use for player tracking
		print('Connecting: ' .. name .. ' (' .. license .. ')')
		return
	end

	-- Not allowlisted
	deferrals.done(deniedMessage)
	print(string.format('Player %s is not allowlisted.', name))
	print(string.format('Valid identifiers: %s\nUse one of these to add them to the allowlist.', table.concat(identifiers, ', ')))
end)

-- Command for allowlist
RegisterCommand('allowlist', function(source, args, rawCommand)
	-- Only allow console to run this command
	if source > 0 then
		print('Only console can run this command.')
		return
	end
	-- If no args, print the help
	if #args == 0 then
		print('Usage: ' .. rawCommand .. ' <subcommand>')
		print('Subcommands:')
		print('  reload - Reload the allowlist')
		print('  add <identifier> - Add an identifier to the allowlist')
		print('  remove <identifier> - Remove an identifier from the allowlist')
		print('  list - List the allowlist')
		return
	end
	-- Check the first arg to see if it's a valid subcommand
	local subcommand = args[1]
	if subcommand == 'reload' then
		reloadAllowlist()
		return
	end

	-- Subcommand for adding a new entry to the allowlist
	if subcommand == 'add' then
		-- Check if there are enough args
		if #args < 2 then
			print('Usage: ' .. rawCommand .. ' <identifier>')
			return
		end
		-- Check if the identifier is already in the allowlist
		local identifier = args[2]
		for _, allowlistEntry in ipairs(allowlistArray) do
			if string.lower(allowlistEntry) == string.lower(identifier) then
				print('Identifier already in allowlist.')
				return
			end
		end
		table.insert(allowlistArray, identifier)
		print('Identifier added to allowlist.')
		-- Reload the allowlist
		local allowlistFile = LoadResourceFile(GetCurrentResourceName(), GetConvar('nc.allowlist', 'allowlist.json'))
		-- Write the allowlist to the file
		if allowlistFile then
			SaveResourceFile(GetCurrentResourceName(), GetConvar('nc.allowlist', 'allowlist.json'), json.encode(allowlistArray), -1)
		else
			print('Failed to save allowlist.')
		end
		return
	end

	-- Subcommand for removing an entry from the allowlist
	if subcommand == 'remove' then
		-- Check if there are enough args
		if #args < 2 then
			print('Usage: ' .. rawCommand .. ' <identifier>')
			return
		end
		-- Check if the identifier is in the allowlist
		local identifier = args[2]
		local found = false
		for i, allowlistEntry in ipairs(allowlistArray) do
			if string.lower(allowlistEntry) == string.lower(identifier) then
				table.remove(allowlistArray, i)
				print('Identifier removed from allowlist.')
				found = true
				-- Reload the allowlist
				local allowlistFile = LoadResourceFile(GetCurrentResourceName(), GetConvar('nc.allowlist', 'allowlist.json'))
				-- Write the allowlist to the file
				if allowlistFile then
					SaveResourceFile(GetCurrentResourceName(), GetConvar('nc.allowlist', 'allowlist.json'), json.encode(allowlistArray), -1)
				else
					print('Failed to save allowlist.')
				end
				break
			end
		end
		if not found then
			print('Identifier not found in allowlist.')
		end
		return
	end

	-- List the allowlist
	if subcommand == 'list' then
		print('Allowlist:')
		for _, allowlistEntry in ipairs(allowlistArray) do
			print(allowlistEntry)
		end
	end
end, true)
