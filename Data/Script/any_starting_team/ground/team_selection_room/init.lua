--[[
    init.lua
    Created: 08/16/2024 20:14:11
    Description: Autogenerated script file for the map team_selection_room.
]]--
-- Commonly included lua functions and data
require 'origin.common'

-- Package name
local team_selection_room = {}

-------------------------------
-- Map Callbacks
-------------------------------
---team_selection_room.Init(map)
--Engine callback function
function team_selection_room.Init(map)


end

---team_selection_room.Enter(map)
--Engine callback function
function team_selection_room.Enter(map)
	
	GROUND:Hide("PLAYER")
	
	-- unlock the default starters
	_DATA.Save:RogueUnlockMonster("bulbasaur")
	_DATA.Save:RogueUnlockMonster("charmander")
	_DATA.Save:RogueUnlockMonster("squirtle")
	_DATA.Save:RogueUnlockMonster("pikachu")
	
	-- intro
	if SV.base_camp.IntroComplete == false then
		GAME:WaitFrames(60)
		UI:WaitShowVoiceOver("Hello![pause=40]\n\nWelcome to the world of Pokémon!\n", -1)
		UI:WaitShowVoiceOver("You're on your way to Guildmaster Island.\n", -1)
		UI:WaitShowVoiceOver("Before you can proceed,[pause=10] you just need to answer a few questions.\n", -1)
		UI:WaitShowVoiceOver("Questions about your ideal team of Pokémon,[pause=10] of course!\n", -1)
		GAME:FadeIn(60)
		team_selection_room.SelectTeam(map)
	else -- failsafe for if the player gets in another way, somehow
		GAME:WaitFrames(20)
		GAME:EnterZone("guildmaster_island", -1, 1, 0)
	end
	
end

---team_selection_room.Exit(map)
--Engine callback function
function team_selection_room.Exit(map)


end

---team_selection_room.Update(map)
--Engine callback function
function team_selection_room.Update(map)


end

---team_selection_room.GameSave(map)
--Engine callback function
function team_selection_room.GameSave(map)


end

---team_selection_room.GameLoad(map)
--Engine callback function
function team_selection_room.GameLoad(map)

  --GAME:FadeIn(20)

end

-------------------------------
-- Entities Callbacks
-------------------------------

-- Thanks to Palika for the code for the text entry, trait selection, and paged choice menu

function team_selection_room.SelectTeam(map)
	
	max_party_members = RogueEssence.Dungeon.ExplorerTeam.MAX_TEAM_SLOTS
	--print(max_party_members)
	
	local party_index = 1
	party_list = {}
	ability_list = {}
	name_list = {}
	local select_text_list = {
		"Enter the species of your player character.",
		"Enter the species of the new party member.",
		"Enter the species of the last party member."
	}
	sleepAnim = "EventSleep"
	
	GAME:WaitFrames(20)
	SOUND:PlayBGM("Personality Test.ogg", true)
	GAME:WaitFrames(40)
	local finished_adding = false
	local valid_species = false
	
	while not finished_adding do
		valid_species = false
		if party_index == 1 then
			UI:NameMenu(select_text_list[1], "Put spaces or hyphens as underscores.")
		elseif party_index == max_party_members then
			UI:NameMenu(select_text_list[3], "Put spaces or hyphens as underscores.")
		else
			UI:NameMenu(select_text_list[2], "Put spaces or hyphens as underscores.")
		end
		UI:WaitForChoice()
		local result = UI:ChoiceResult()
		local lower_result = string.lower(result)
		
		local mons = _DATA.DataIndices[RogueEssence.Data.DataManager.DataType.Monster]:GetOrderedKeys(false)
		--  Count - 1 to account for missingno, as count goes up one more than it should because of missingno
		for i = 1, _DATA.DataIndices[RogueEssence.Data.DataManager.DataType.Monster].Count - 1, 1 do
			if mons[i] == lower_result then
				valid_species = true		
				break
			end						
		end
		
		if valid_species and lower_result ~= "missingno" then
			if not _DATA:GetMonster(lower_result).Released then 
				UI:WaitShowDialogue(_DATA:GetMonster(lower_result):GetColoredName() .. " does not have complete data and/or sprites.[pause=0] Please select a different species.")
				valid_species = false
			else
				
				char_choice = RogueEssence.Dungeon.MonsterID(lower_result, 0, "normal", Gender.Genderless)
				
				GAME:WaitFrames(20)
				
				visual_character = RogueEssence.Ground.GroundChar(char_choice, RogueElements.Loc(0, 0), Direction.Down, "Entity", "VisualCharacter")
				visual_character:ReloadEvents()
				GAME:GetCurrentGround():AddTempChar(visual_character)
				visual_character:OnMapInit()
				local result = RogueEssence.Script.TriggerResult()
				TASK:WaitTask(visual_character:RunEvent(RogueEssence.Script.LuaEngine.EEntLuaEventTypes.EntSpawned, result, visual_character))
				
				if GROUND:CharGetAnimFallback(visual_character, "EventSleep") ~= "EventSleep" then
					sleepAnim = "Sleep"
				else
					sleepAnim = "EventSleep"
				end
				
				GROUND:CharSetAnim(visual_character, sleepAnim, true)
				--GAME:WaitFrames(40)
				GROUND:Hide("VisualCharacter")
				GAME:WaitFrames(20)
				for i=1,20,1 do
					GROUND:Unhide("VisualCharacter")
					GAME:WaitFrames(1)
					GROUND:Hide("VisualCharacter")
					GAME:WaitFrames(1)
				end
				GROUND:Unhide("VisualCharacter")
				
				UI:ChoiceMenuYesNo(STRINGS:Format("You would like to add {0} to your team?", _DATA:GetMonster(char_choice.Species):GetColoredName()))
				UI:WaitForChoice()
				local choiceResult = UI:ChoiceResult()
				
				if choiceResult == false then
					GAME:WaitFrames(20)
					for i=1,20,1 do
						GROUND:Hide("VisualCharacter")
						GAME:WaitFrames(1)
						GROUND:Unhide("VisualCharacter")
						GAME:WaitFrames(1)
					end
					GROUND:RemoveCharacter("VisualCharacter")
					GAME:WaitFrames(40)
				else
					-- form choice
					form = 0
					form_name = _DATA:GetMonster(char_choice.Species).Forms[form].FormName:ToLocal()
					form_index = {}
					
					local stop_choice = true
					
					if _DATA:GetMonster(char_choice.Species).Forms.Count > 1 then 
						local forms = {}
						for i = 0,  _DATA:GetMonster(char_choice.Species).Forms.Count - 1, 1 do 
							local is_temporary = _DATA:GetMonster(char_choice.Species).Forms[i].Temporary
							print(is_temporary)
							if is_temporary == false then
								table.insert(forms, "[color=#00FF00]" .. _DATA:GetMonster(char_choice.Species).Forms[i].FormName:ToLocal() .. "[color]")
								table.insert(form_index, i)
							end
						end
						table.insert(forms, "On second thought...")
						
						if #forms > 2 then
							
							local form_continue = false
								
							while not form_continue do
								result = team_selection_room.PagedChoiceMenu("Which form would you like?", forms, 1, #forms)
								--UI:BeginChoiceMenu("Which form would you like?", forms_subset, 1, #forms_subset)
								--UI:WaitForChoice()
								--result = UI:ChoiceResult()
								
								if result == #forms then
									GAME:WaitFrames(20)
									for i=1,20,1 do
										GROUND:Hide("VisualCharacter")
										GAME:WaitFrames(1)
										GROUND:Unhide("VisualCharacter")
										GAME:WaitFrames(1)
									end
									GROUND:RemoveCharacter("VisualCharacter")
									GAME:WaitFrames(40)
									stop_choice = false
									form_continue = true
								else
									--form = result - 1
									form = form_index[result]
									
									--make sure this form is also released.
									if not _DATA:GetMonster(char_choice.Species).Forms[form].Released then
										UI:WaitShowDialogue("This form does not have necessary data or sprites.[pause=0] Please try again.")
									else
										--UI:ChoiceMenuYesNo("Is [color=#00FF00]" .. _DATA:GetMonster(char_choice.Species).Forms[form].FormName:ToLocal() .. "[color] correct?")
										--UI:WaitForChoice()
										form_continue = UI:ChoiceResult()
										form_name = _DATA:GetMonster(char_choice.Species).Forms[form].FormName:ToLocal()
									end
								end
							end
						end
						
						--[[
						if char_choice.Species == "alcremie" then
							
							local form_continue = false
							
							while not form_continue do
								team_selection_room.PagedChoiceMenu("Which form would you like?", forms, 1, #forms)
								--UI:BeginChoiceMenu("Which form would you like?", forms_subset, 1, #forms_subset)
								UI:WaitForChoice()
								result = UI:ChoiceResult()
								
								if result == #forms then
									GAME:WaitFrames(20)
									for i=1,20,1 do
										GROUND:Hide("VisualCharacter")
										GAME:WaitFrames(1)
										GROUND:Unhide("VisualCharacter")
										GAME:WaitFrames(1)
									end
									GROUND:RemoveCharacter("VisualCharacter")
									GAME:WaitFrames(40)
									stop_choice = false
									form_continue = true
								else
									--form = result - 1
									form = form_index[result]
									
									--make sure this form is also released.
									if not _DATA:GetMonster(char_choice.Species).Forms[form].Released then
										UI:WaitShowDialogue("This form does not have necessary data or sprites.[pause=0] Please try again.")
									else
										--UI:ChoiceMenuYesNo("Is [color=#00FF00]" .. _DATA:GetMonster(char_choice.Species).Forms[form].FormName:ToLocal() .. "[color] correct?")
										--UI:WaitForChoice()
										form_continue = UI:ChoiceResult()
										form_name = _DATA:GetMonster(char_choice.Species).Forms[form].FormName:ToLocal()
									end
								end
							end
							
						else		
							local form_continue = false
							
							while not form_continue do
								UI:BeginChoiceMenu("Which form would you like?", forms, 1, #forms)
								UI:WaitForChoice()
								result = UI:ChoiceResult()
								
								if result == #forms then
									GAME:WaitFrames(20)
									for i=1,20,1 do
										GROUND:Hide("VisualCharacter")
										GAME:WaitFrames(1)
										GROUND:Unhide("VisualCharacter")
										GAME:WaitFrames(1)
									end
									GROUND:RemoveCharacter("VisualCharacter")
									GAME:WaitFrames(40)
									stop_choice = false
									form_continue = true
								else
									--form = result - 1
									form = form_index[result]
									
									--make sure this form is also released.
									if not _DATA:GetMonster(char_choice.Species).Forms[form].Released then
										UI:WaitShowDialogue("This form does not have necessary data or sprites.[pause=0] Please try again.")
									else
										--UI:ChoiceMenuYesNo("Is [color=#00FF00]" .. _DATA:GetMonster(char_choice.Species).Forms[form].FormName:ToLocal() .. "[color] correct?")
										--UI:WaitForChoice()
										form_continue = UI:ChoiceResult()
										form_name = _DATA:GetMonster(char_choice.Species).Forms[form].FormName:ToLocal()
									end
								end
							end
						end
						]]--
					end
					
					if stop_choice == true then
						char_choice.Form = form
						
						GROUND:RemoveCharacter("VisualCharacter")
						
						visual_character = RogueEssence.Ground.GroundChar(char_choice, RogueElements.Loc(0, 0), Direction.Down, "Entity", "VisualCharacter")
						visual_character:ReloadEvents()
						GAME:GetCurrentGround():AddTempChar(visual_character)
						visual_character:OnMapInit()
						local result = RogueEssence.Script.TriggerResult()
						TASK:WaitTask(visual_character:RunEvent(RogueEssence.Script.LuaEngine.EEntLuaEventTypes.EntSpawned, result, visual_character))
						
						GROUND:CharSetAnim(visual_character, sleepAnim, true)
						
						-- gender choice
						local gender_choices = {'Male', 'Female', "Non-Binary"}
						UI:BeginChoiceMenu(STRINGS:Format("What gender of [color=#00FF00]{0}[color]?", form_name), gender_choices, 1, 1)
						UI:WaitForChoice()
						
						local gender_choice = UI:ChoiceResult()
						local entity_gender = Gender.Genderless
						
						if gender_choice == 1 then
							entity_gender = Gender.Male
						elseif gender_choice == 2 then
							entity_gender = Gender.Female
						else --dunno if this will cause issues with sprites to use
							entity_gender = Gender.Genderless
						end
						
						char_choice.Gender = entity_gender
						
						GROUND:RemoveCharacter("VisualCharacter")
						
						visual_character = RogueEssence.Ground.GroundChar(char_choice, RogueElements.Loc(0, 0), Direction.Down, "Entity", "VisualCharacter")
						visual_character:ReloadEvents()
						GAME:GetCurrentGround():AddTempChar(visual_character)
						visual_character:OnMapInit()
						local result = RogueEssence.Script.TriggerResult()
						TASK:WaitTask(visual_character:RunEvent(RogueEssence.Script.LuaEngine.EEntLuaEventTypes.EntSpawned, result, visual_character))
						
						GROUND:CharSetAnim(visual_character, sleepAnim, true)
						
						-- ability choice
						
						local monster = _DATA:GetMonster(char_choice.Species).Forms[char_choice.Form]
						local ability = monster.Intrinsic1
						if monster.Intrinsic2 ~= "none" or monster.Intrinsic3 ~= "none" then--if pokemon has more than one ability, let player choose which to get
							--UI:WaitShowDialogue("[color=#FF0000]Error: selected species has potential DNA sequences for more than one ability.")
							if monster.Intrinsic3 == "none" then -- has two regular abilities and no hidden ability.
								UI:BeginChoiceMenu("Which ability do you want?", {_DATA:GetIntrinsic(monster.Intrinsic1):GetColoredName(), _DATA:GetIntrinsic(monster.Intrinsic2):GetColoredName()}, 1, 1)
								UI:WaitForChoice()
								local result = UI:ChoiceResult()
								if result == 2 then
									ability = monster.Intrinsic2
								end
							elseif monster.Intrinsic2 == "none" then -- has a regular ability and a hidden ability.
								UI:BeginChoiceMenu("Which ability do you want?", {_DATA:GetIntrinsic(monster.Intrinsic1):GetColoredName(), _DATA:GetIntrinsic(monster.Intrinsic3):GetColoredName()}, 1, 1)
								UI:WaitForChoice()
								local result = UI:ChoiceResult()
								if result == 2 then
									ability = monster.Intrinsic3
								end
							else -- has three abilities.
								UI:BeginChoiceMenu("Which ability do you want?", {_DATA:GetIntrinsic(monster.Intrinsic1):GetColoredName(), _DATA:GetIntrinsic(monster.Intrinsic2):GetColoredName(), _DATA:GetIntrinsic(monster.Intrinsic3):GetColoredName()}, 1, 1)
								UI:WaitForChoice()
								local result = UI:ChoiceResult()
								if result == 2 then
									ability = monster.Intrinsic2
								elseif result == 3 then
									ability = monster.Intrinsic3
								end
							end
						end
						table.insert(ability_list, ability)
						--ability_list[party_index] = ability
						
						-- name entry
						
						name_choice = ""
						
						UI:ChoiceMenuYesNo("Would you like to give this Pokémon a nickname?")
						UI:WaitForChoice()
						yesNoResult = UI:ChoiceResult()
						if yesNoResult == true then
							local yesnoResult = false 
							while not yesnoResult do
								UI:NameMenu("What is the Pokémon's name?", "", 116)
								UI:WaitForChoice()
								result = UI:ChoiceResult()
								UI:ChoiceMenuYesNo("Is [color=#00FFFF]" .. result .. "[color] correct?")
								UI:WaitForChoice()
								yesnoResult = UI:ChoiceResult()
							end
							-- name_list[party_index] = result
							name_choice = result
						else
							-- name_list[party_index] = _DATA:GetMonster(char_choice.Species).Name:ToLocal()
							name_choice = _DATA:GetMonster(char_choice.Species).Name:ToLocal()
						end
						table.insert(name_list, name_choice)
						
						local shiny = "normal"
						UI:ChoiceMenuYesNo(STRINGS:Format("Lastly, do you want [color=#00FFFF]{0}[color] to be shiny?", name_choice), true)
						UI:WaitForChoice()
						result = UI:ChoiceResult()
						
						if result then shiny = 'shiny' end
						char_choice.Skin = shiny
						
						GROUND:RemoveCharacter("VisualCharacter")
						
						visual_character = RogueEssence.Ground.GroundChar(char_choice, RogueElements.Loc(0, 0), Direction.Down, "Entity", "VisualCharacter")
						visual_character:ReloadEvents()
						GAME:GetCurrentGround():AddTempChar(visual_character)
						visual_character:OnMapInit()
						local result = RogueEssence.Script.TriggerResult()
						TASK:WaitTask(visual_character:RunEvent(RogueEssence.Script.LuaEngine.EEntLuaEventTypes.EntSpawned, result, visual_character))
						
						GROUND:CharSetAnim(visual_character, sleepAnim, true)
						
						GAME:WaitFrames(40)
						for i=1,20,1 do
							GROUND:Hide("VisualCharacter")
							GAME:WaitFrames(1)
							GROUND:Unhide("VisualCharacter")
							GAME:WaitFrames(1)
						end
						GROUND:RemoveCharacter("VisualCharacter")
						GAME:WaitFrames(20)
						
						--party_list[party_index] = char_choice
						table.insert(party_list, char_choice)
						if party_index == 1 then
							SV.General.Starter = char_choice
						end
						UI:WaitShowDialogue(STRINGS:Format("Added [color=#00FFFF]{0}[color] to the party.", name_choice))
						
						if party_index ~= max_party_members then
							UI:ChoiceMenuYesNo("Would you like to keep adding more Pokémon?")
							UI:WaitForChoice()
							yesNoResult = UI:ChoiceResult()
							if yesNoResult == false then
								finished_adding = true
							end
						else
							finished_adding = true
						end
						
						if party_index ~= max_party_members then
							party_index = party_index + 1
						end
					else
						
					end
				end
			end 
		else
			UI:WaitShowDialogue(STRINGS:Format("{0} is not a valid Pokémon species.", result))
		end
	end
	
	team_selection_room.FillTeam(map)
	
end

function team_selection_room.FillTeam(map)
	
	--remove any team members that may exist by default for some reason
	local party_count = _DATA.Save.ActiveTeam.Players.Count
	for ii = 1, party_count, 1 do
		_DATA.Save.ActiveTeam.Players:RemoveAt(0)
	end

	local assembly_count = GAME:GetPlayerAssemblyCount()
	for i = 1, assembly_count, 1 do
	   _DATA.Save.ActiveTeam.Assembly.RemoveAt(i-1)--not sure if this permanently deletes or not...
	end 
	
	-- fill the team with the selected pokemon
	for i = 1, #party_list, 1 do
		local mon_id = party_list[i]
		if mon_id.Species ~= "missingno" then
			
			-- unlock in the pokedex and for roguelocke
			_DATA.Save:RogueUnlockMonster(mon_id.Species)
			_DATA.Save:RegisterMonster(mon_id.Species)
			
			-- add to the team
			_DATA.Save.ActiveTeam.Players:Add(_DATA.Save.ActiveTeam:CreatePlayer(_DATA.Save.Rand, mon_id, 5, ability_list[i], 0))
			local my_pokemon = GAME:GetPlayerPartyMember(i - 1)
			GAME:SetCharacterNickname(my_pokemon, name_list[i])
			local talk_evt = RogueEssence.Dungeon.BattleScriptEvent("AllyInteract")
			my_pokemon.ActionEvents:Add(talk_evt)
			my_pokemon:FullRestore()
			
		end
	end
	GAME:SetTeamLeaderIndex(0)
	_DATA.Save:UpdateTeamProfile(true)
	_DATA.Save.ActiveTeam.Players[0].IsFounder = true
	_DATA.Save.ActiveTeam.Players[0].IsPartner = true
	GROUND:Hide("PLAYER")
	GAME:WaitFrames(20)
	
	UI:WaitShowDialogue("OK![pause=0] That's it![pause=0] You're all ready to go!")
	if _DATA.Save.ActiveTeam.Players.Count == 1 then
		UI:WaitShowDialogue("You're off to Guildmaster Island!")
	else
		UI:WaitShowDialogue("You and your team are off to Guildmaster Island!")
	end
	UI:WaitShowDialogue("Be strong![pause=0] Stay smart![pause=0] And be victorious!")
	
	GAME:WaitFrames(20)
	
	GAME:FadeOut(false, 60)
	SOUND:PlayBGM("", true, 60)
	GAME:WaitFrames(60)
	GAME:CutsceneMode(false)
	GAME:EnterZone("guildmaster_island", -1, 1, 0)
	
end

-- Code by Palika
function team_selection_room.PagedChoiceMenu(message, choices, defaultchoice, cancelchoice)
	local choice_amount = #choices
	local choice_submenus = {}
	local submenu_length = 10
	local result
	
	--if you see weird - and + 1 with a modulo, its indexing shenanigans.
	if choice_amount > submenu_length then
		--populate choice_submenus 
		for i = 1, choice_amount, 1 do 
			if i % submenu_length == 1 then table.insert(choice_submenus, {}) end --add an empty table in if we need to start a new subtable
			choice_submenus[math.ceil(i / submenu_length)][((i - 1) % submenu_length) + 1] = choices[i]
		end 
		
		for i = 1, #choice_submenus, 1 do
			table.insert(choice_submenus[i], "Prev Page")
			table.insert(choice_submenus[i], "Next Page")
		end
		
		local continue = false 
		local current_submenu = 1
		local total_submenus = #choice_submenus
		local default_cursor_option  = 1--stay on whatever we selected last (next or last page)
		--Loop submenus until player chooses an actual option.
		while not continue do
			UI:BeginChoiceMenu(message, choice_submenus[current_submenu], default_cursor_option, # choice_submenus[current_submenu])
			UI:WaitForChoice()
			result = UI:ChoiceResult()
			UI:SetAutoFinish(true)--so submenus dont have to repeat the entire query.
			
			--prev page 
			if result == #choice_submenus[current_submenu] - 1 then 
				current_submenu = ((current_submenu - 2) % total_submenus) + 1
				default_cursor_option = #choice_submenus[current_submenu] - 1
			--next page 
			elseif result == #choice_submenus[current_submenu] then
				current_submenu = (current_submenu % total_submenus) + 1
				default_cursor_option = #choice_submenus[current_submenu]
			--an actual choice. Need to adjust the result according to the submenu.
			else 
				result = result + ((current_submenu - 1) * submenu_length)
				continue = true 
				UI:SetAutoFinish(false)--set this back to not auto finish. No way to check if it is on or off before we get here, so typical situation we'd want is to turn it back off. Destructive, but what can you do.
			end 
		end 
	else
		UI:BeginChoiceMenu(message, choices, defaultchoice, cancelchoice)
		UI:WaitForChoice()
		result = UI:ChoiceResult()
	end 
	
	--print("result is: " .. tostring(result))
	return result
	
end 

return team_selection_room

