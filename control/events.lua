
gui = require("mod-gui")


Script.on_built_entity(function(event)
	if event.entity.name ~= "entity-ghost" then
		on_build_somehow(event.entity)
	else
		on_build_ghost_somehow(event.entity)
	end
end)

Script.on_robot_built_entity(function(event)
	if event.entity.name ~= "entity-ghost" then
		on_build_somehow(event.entity)
	else
		on_build_ghost_somehow(event.entity)
	end
end)

Script.on_player_mined_entity(function(event)
	if event.entity.name ~= "entity-ghost" then
		on_destroyed_somehow(event.entity)
	else
		on_destroyed_ghost_somehow(event.entity)
	end
end)

Script.on_robot_mined_entity(function(event)
	on_destroyed_somehow(event.entity)
end)

Script.on_pre_ghost_deconstructed(function(event)
	on_destroyed_ghost_somehow(event.ghost)
end)



function on_build_somehow(entity)
	if entity.name == "dupe-train-stop" then
		if entity.surface.name ~= "dupe-surface" then
			return Subbox.create_and_add_from_train_stop(entity)
		end
	end
	if entity.name == "dupe-linked-belt" then
		return on_build_linked_belt(entity)
	end

	local subbox = Subbox.get_from_entity(entity)
	if subbox then
		subbox:sync_built_entity(entity)
	end
end

function on_build_ghost_somehow(ghost)
	if ghost.name == "entity-ghost" and ghost.ghost_name == "dupe-train-stop" then
		if ghost.surface.name ~= "dupe-surface" then
			return Subbox.create_and_add_from_train_stop_ghost(ghost)
		end
	end
	if ghost.name == "entity-ghost" and ghost.ghost_name == "dupe-linked-belt" then
		return on_build_linked_belt_ghost(ghost)
	end
	local subbox = Subbox.get_from_entity(ghost)
	if subbox then
		subbox:sync_built_entity_ghost(ghost)
	end
end

function on_destroyed_somehow(entity)
	if entity.name == "dupe-train-stop" then
		return Subbox.remove_train_stop(entity)
	end
	if entity.name == "dupe-linked-belt" then
		return on_destroy_linked_belt(entity)
	end
end

function on_destroyed_ghost_somehow(ghost)
	if ghost.name == "entity-ghost" and ghost.ghost_name == "dupe-train-stop" then
		return Subbox.remove_train_stop_ghost(ghost)
	end
	if ghost.name == "entity-ghost" and ghost.ghost_name == "dupe-linked-belt" then
		return on_destroy_linked_belt_ghost(ghost)
	end
end



Script.on_entity_renamed(function(event)
	if event.entity.name == "dupe-train-stop" then
		-- local dupebox = Dupebox.get(event.entity.backer_name)
		-- if not dupebox then
		if event.entity.backer_name ~= event.old_name and not event.by_script then
			Game.line("You can not rename Dupeboxes!")
			event.entity.backer_name = event.old_name
		end
	end
end)

-- Script.on_entity_settings_pasted(function(event)
-- 	local source = event.source
-- 	local destination = event.destination
-- 	if destination.name == "dupe-train-stop" or destination.name == "entity-ghost" and destination.ghost_name == "dupe-train-stop" then
-- 		local subbox = Subbox.get_from_train_stop(destination)
-- 		if not subbox then return Game.line("on_entity_settings_pasted: renamed dupe-train-stop, but it has no subbox, why?") end
-- 		if subbox.backer_name ~= destination.backer_name then
-- 			-- Game.line("You can not rename Dupeboxes!")
-- 			-- destination.backer_name = subbox.backer_name
-- 		end
-- 	end
-- end)





Script.on_player_selected_area("dupe-planner", function(event)
	Subbox.create_and_add_from_selection_event(event)
end)



Script.on_gui_opened(function(event)
	-- Game.dline(event)

	if event.entity and event.entity.name == "dupe-train-stop" then

		local d = Dupebox.get(event.entity.backer_name)
		d:recreate_train_stop_gui(event.player)
	end

end)

Script.on_gui_click(function(event)
	if event.element.name == "dupe_btn_activate" then
		Game.line("You have pressed ACTIVATE button!")
		local player = event.player
		local entity = player.opened
		local subbox = Subbox.get_from_entity(entity)
		subbox:get_dupebox():activate{player=player, subbox=subbox, entity=entity}
		return
	end
	if event.element.name == "dupe_btn_tp_in" then
		local player = event.player
		local entity = player.opened
		local subbox = Subbox.get_from_train_stop(entity)
		local prodbox = subbox:get_dupebox().prodbox
		prodbox:teleport_player_inside{player=player, subbox=subbox, entity=entity}
		return
	end
	if event.element.name == "dupe_btn_tp_out" then
		local player = event.player
		local entity = player.opened
		local prodbox = Prodbox.get_from_train_stop(entity)
		prodbox:teleport_player_outside{player=player, entity=entity}
		return
	end
end)



Script.on_chunk_generated(function(event)
	if event.surface.name ~= "dupe-surface" then return end
	local box = Box(event.area):grow(-0.5)
	local tiles = {}
	for i=0,box:width() do
		for j=0,box:height() do
			tiles[#tiles+1] = {name = "out-of-map", position=box[1]:add{i,j}}
		end
	end
	event.surface.set_tiles(tiles)
end)




function on_build_linked_belt(entity)
	local data = Subbox.parse_linked_belt(entity)
	local subbox = data.subbox

	if not subbox then
		Game.line("Can build dupe-linked-belt only near dupebox!")
		entity.destroy()
		return
	end
	local pos = data.pos
	local dir = data.dir
	local dupebox = subbox:get_dupebox()

	local in_wall = not subbox.area:grow(-1):contains(pos:sub(dir))
				and not subbox.area:grow(-1):contains(pos:add(dir))

	local contains_input = subbox.area:contains(pos:sub(dir))
	local contains_output = subbox.area:contains(pos:add(dir))


	if in_wall or contains_input and contains_output
			or not contains_input and not contains_output then
		Game.line("Can build dupe-linked-belt only near dupebox!")
		entity.destroy()
		return
	end

	if dupebox.linked_belts[data.id] then
		if subbox:get_dupebox().prodbox.activated then return end
		-- dirty fix
		Build.reset(subbox)
		local input = Build.fef{name="dupe-linked-belt", pos=subbox.position:add(data.offset):sub(data.dir)}[1]
		local output = Build.fef{name="dupe-linked-belt", pos=subbox.position:add(data.offset):add(data.dir)}[1]
		if input and output and input.linked_belt_type ~= output.linked_belt_type then
			if input.linked_belt_neighbour == output then return end
			if not input.linked_belt_neighbour and not output.linked_belt_neighbour then
				input.connect_linked_belts(output)
				return
			end
			input.destroy()
			output.destroy()
		end
	end

	Build.reset(entity)
	Build.set{direction=data.direction, offset=data.offset}
	for i,sub in ipairs(dupebox.subboxes) do
		Build.reset(sub)
		Build.set{direction=data.direction, offset=data.offset}
		local input, output
		if sub == subbox and entity.valid then if entity.linked_belt_type  == "input" then input = entity else output = entity end end
		if not getmetatable(sub.position) then Game.line{sub=sub.position} end
		input = input
			or Build.fef_or_ghost{name="dupe-linked-belt", offset=sub.position:sub(dir)}[1]
			or Build{"ghost", "dupe-linked-belt", type="input", offset=sub.position:sub(dir)}
		output = output
			or Build.fef_or_ghost{name="dupe-linked-belt", offset=sub.position:add(dir)}[1]
			or Build{"ghost", "dupe-linked-belt", type="output", offset=sub.position:add(dir)}
		if input and output then
			input.connect_linked_belts(output)
		else Game.dline("No linked-belt to connect, why?") end
	end

	dupebox.linked_belts[data.id] = {
		id = data.id,
		offset = data.offset,
		dir = data.dir,
		direction = data.direction,
		type = subbox.area:contains(pos:add(dir)) and "input" or "output",
	}

end

function on_build_linked_belt_ghost(ghost)
	local subbox = Subbox.get_from_linked_belt(ghost)
	if not subbox then
		Game.line("Can build dupe-linked-belt only near dupebox!")
		ghost.destroy()
		return
	end

	local dupebox = subbox:get_dupebox()
	local id = subbox:entity_id(ghost)

	local data = dupebox.linked_belts[id]
	if not data then on_build_linked_belt(ghost) return end

end

function on_destroy_linked_belt(entity)
	local data = Subbox.parse_linked_belt(entity)
	local subbox = data.subbox
	if not subbox then return end
	local dupebox = data.subbox:get_dupebox()

	for i,subbox in ipairs(dupebox.subboxes) do
		local surface = game.surfaces[subbox.surface]
		local list = {subbox.position:add(data.offset):add(data.dir),
						subbox.position:add(data.offset):sub(data.dir)}
		local bad = {}
		for i,pos in ipairs(list) do
			local found = surface.find_entities_filtered{ghost_name="dupe-linked-belt", position=pos}
			for i,v in ipairs(found) do bad[#bad+1] = v end
			local found = surface.find_entities_filtered{name="dupe-linked-belt", position=pos}
			for i,v in ipairs(found) do bad[#bad+1] = v end
		end
		for i,v in ipairs(bad) do
			if v ~= entity then
				if v.name == "entity-ghost" then 
					v.destroy()
				else
					Build.mine_and_spill(v, {}, {force=dupebox.force})
				end
			end
		end
	end

	dupebox.linked_belts[data.id] = nil
end

function on_destroy_linked_belt_ghost(ghost)
	on_destroy_linked_belt(ghost)
end





script.on_nth_tick(67, function(event)
	local dc = DupeController.get()
	for k,dupebox in pairs(dc.dupeboxes) do
		local prodbox = dupebox.prodbox
		for k,link in pairs(dupebox.linked_belts) do
			if link.missing_infinity_filters then
				Duper.try_set_infinity_filters{link=link, dupebox=dupebox, prodbox=dupebox.prodbox}
			end 
		end
		local max_limit = 200
		local limit = max_limit * 100 * 100
		for i,subbox in ipairs(dupebox.subboxes) do
			if subbox.requested_blueprint_sync then
				if limit > 0 then
					local player = subbox.requested_blueprint_sync ~= true
						and game.players[subbox.requested_blueprint_sync] or nil
					subbox:get_dupebox():copy_ghosts(subbox, nil, {player = player})
					subbox.requested_blueprint_sync = nil
				end
				limit = limit - #dupebox.subboxes * dupebox.size[1] * dupebox.size[2]
			end
		end
		if limit <= 0 then
			Game.dline("[Dupebox] Long copypasting operation is in process... ("..(math.floor(-limit/max_limit/10)/1000).." left) "..game.tick)
		end
	end
end)