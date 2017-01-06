guids = {
	start_button = 'bbd923',
	generation_counter = '1c4a11',
	generation_marker = 'a63f90',
	discard_one = '0e0cb2',
	discard_two = 'a55736',
	projects = '1ae58d',
	project_tile = 'b550fe',
	corporations = 'b17690',
	corporate_era_corporations = '658e8a'
}
things = {}

discardPile_x = -21
discardPile_y = 2
discardPile_z = -10.9
cards_required = 0

project_management_positions = {
	Yellow = {-16, 2.3, -35},
	Red = {16, 2.3, -35},
	White = {41, 4.5, -2.7},
	Blue = {16.2, 4.5, 35},
	Green = {-16, 4.5, 35}
}

function onload ()
	-- Where are all the things?
	for name, guid in pairs(guids) do
		things[name] = getObjectFromGUID(guid)
		if not things[name] then
			displayError('Failed to find "'.. name ..'" on the board with GUID "' .. guid .. '"')
		end
	end

	-- Create the Research button
	things['start_button'].createButton({
		click_function = 'performResearchClick',
		label = 'Research',
		function_owner = nil,
		position = { 0, 0.3, 0},
		rotation = {0, 180, 0},
		width = 800,
		height = 400,
		font_size = 200
	})
end

function rebuildProjectDeckFromDiscardPiles()
	local project_area = things['project_tile']
	local discard_one = findDeckInZone(things['discard_one'])
	local discard_two = findDeckInZone(things['discard_two'])
	if discard_one then
		combineDecks(discard_one, project_area)
	end
	if discard_two then
		combineDecks(discard_two, project_area)
	end

	wait(0.2)
	local project_deck = findDeckInZone(things['projects'])
	if project_deck and project_deck.getQuantity() > cards_required then
		project_deck.shuffle()
		wait(0.2)
		performResearch()
	else
		diplayError('Failed making a new project deck. Are the discard piles empty?')
	end
	return 1
end

function combineDecks(source, destination)
	local r = destination.getRotation()
	r.z = 180 -- ensure decks are placed face-down
	source.setRotation(r)
	source.setPosition(destination.getPosition())
end

function performResearchClick()
	startLuaCoroutine(Global, 'performResearch')
end

function performResearch()
	local project_deck = findDeckInZone(things['projects'])
	local generation_counter = things['generation_counter'].Counter
	local generation = generation_counter.getValue()
	local playerCount = playerCount()
	local research_limit = 4

	if generation == 0 then
		research_limit = 10
		if project_deck then
			project_deck.shuffle()
			wait(0.2)
		end
	end

	if generation >= 14 and playerCount == 1 then
		displayError('Solo game is limited to 14 generations. No more research available.')
	else
		cards_required = research_limit * playerCount
		if project_deck and project_deck.getQuantity() > cards_required then
			generation_counter.increment()
			if research_limit == 10 then
				dealTenProjectsAndTwoCorporations()
			else
				project_deck.dealToAll(research_limit)
			end
			incrementGenerationMarker(generation)
			broadcastToAll('Generation ' .. (generation+1) .. ' has begun.', {1,1,1})
		else
			rebuildProjectDeckFromDiscardPiles()
		end
	end
	return 1
end

function displayError(message)
	broadcastToAll(message, {1,0,0})
end

function dealTenProjectsAndTwoCorporations()
	-- Ten projects...
	local project_deck = findDeckInZone(things['projects'])
	for colour, player_position in pairs(project_management_positions) do
		if Player[colour].seated then
			for i = 0, 10, 1 do
				project_deck.takeObject({
					position = player_position,
					flip = true
				});
			end
		end
	end

	-- Two corporations...
	local corporation_deck = things['corporations']
	if not corporation_deck then
		corporation_deck = things['corporate_era_corporations']
	end
	if not corporation_deck then
		displayError('Could not find a deck of corporations to deal out :(')
	end
	corporation_deck.shuffle()
	wait(0.5)
	corporation_deck.dealToAll(2)
end

function incrementGenerationMarker(generation)
	local marker = things['generation_marker']
	local p = marker.getPosition()
	marker.setRotation({0,0,0})
	if generation <= 25 then
		marker.setPosition({p.x, 5, p.z+1.16})
	elseif generation <= 50 then
		marker.setPosition({p.x+1.37, 5, p.z})
	else
		marker.setPosition({p.x, 5, p.z-1.16})
	end
end

function playerCount()
	local T = getSeatedPlayers()
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end

function findDeckInZone(zone)
	local objectsInZone = zone.getObjects()
	for i, object in ipairs(objectsInZone) do
		if object.tag == "Deck" then
			return object
		end
	end
	return nil
end

function wait(time)
	local start = os.time()
	repeat coroutine.yield(0) until os.time() > start + time
end