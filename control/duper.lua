


Duper = {}
Duper.meta = {}
setmetatable(Duper, Duper.meta)
Duper.prototype = {__class = "Duper"}
Duper.metaprototype = {__index = Duper.prototype}


Duper.INITIAL_DUPER_OFFSET_Y = 9
Duper.DUPER_MARGIN_Y = 1
Duper.DRAW_AREAS = true









function Duper.activate_link(data)
	local prodbox, dupebox, link = data.prodbox, data.dupebox, data.link

	if link.type == "input" then
		return Duper.activate_input_link(data)
	end
	if link.type == "output" then
		return Duper.activate_output_link(data)
	end

	Game.line{"nop with: ", link=link}
end


function Duper.activate_input_link(data)
	local prodbox, dupebox, link = data.prodbox, data.dupebox, data.link

	local dupeface = game.surfaces["dupe-surface"]

	local y = Duper.INITIAL_DUPER_OFFSET_Y
	for id,link in pairs(dupebox.linked_belts) do
		if link.active then
			if y < link.area[2][2] then y = link.area[2][2] + Duper.DUPER_MARGIN_Y - 1 end
		end
	end
	local duper_area = Box{{0, 0}, {9, prodbox.multiplier+1}}:move(prodbox.position):move{0,y}
	local duper_pos = duper_area[1]:add{0.5, 0.5}
	link.area = duper_area
	link.pos = duper_pos
	link.active = true

	Duper.scan_area{area=duper_area, prodbox=prodbox}

	if Duper.DRAW_AREAS then dupeface.add_script_area{area=duper_area,name=dupebox.backer_name.." "..link.id} end
	-- dupeface.add_script_position{position=duper_pos,name=dupebox.backer_name}

	local paths = {}

	local outputs = {}
	for i,sub in ipairs(prodbox:get_active_subboxes()) do
		local path = {}
		paths[i] = path
		-- build_offset = {box.x + data.duper_offset[1], box.y + data.duper_offset[2] + i}
		Build.reset(sub)
		path.input = Build.fef{
			name="dupe-linked-belt",
			position=sub.position:add(link.offset):sub(link.dir),
		}[1]
		Build.reset(prodbox)
		Build.set{offset=duper_pos:add{0, i}, force="enemy"}

		path.duper_input = Build{"dupe-linked-belt", offset = {0,0}, type = "output"}
		path.input.connect_linked_belts(nil)

		path.input.connect_linked_belts(path.duper_input)

		path.belt1 = Build{"dupe-belt", offset = {1, 0}}
		path.belt2 = Build{"dupe-belt", offset = {2, 0}}

		path.loader = Build{"dupe-loader", offset = {3, 0}, type = "input"}

		path.box = Build{"dupe-infinity-chest", offset = {5, 0}}
		if i > 1 then
			path.box.remove_unfiltered_items = true
		end
	end
	Build.reset(prodbox)
	Build.set{offset=duper_pos, force="enemy"}

	local mainpath = paths[1]
	mainpath.outloader = Build{"dupe-loader", offset = {6, 1}, type = "output"}
	mainpath.output = Build.fef{
		name = "dupe-linked-belt",
		pos = prodbox.position:add(link.offset):add(link.dir)
	}[1]
	mainpath.duper_output = Build{"dupe-linked-belt", offset = {8, 1}, type = "input"}
	mainpath.duper_output.connect_linked_belts(mainpath.output)

	mainpath.decider = Build{"dupe-decider-combinator", offset = {1, 0}}
	set_behavior(mainpath.decider, {"signal-anything", "=", #paths * 8, "signal-check", 1})

	mainpath.decider2 = Build{"dupe-decider-combinator", offset = {4, 0}, direction = 2 + 4}
	set_behavior(mainpath.decider2, {"signal-anything", ">", 2, "signal-red", 1})

	for i,path in ipairs(paths) do
		if i == 1 then
			connect_neighbour(mainpath.decider, path.belt1, "green", 1)
			connect_neighbour(mainpath.decider, path.belt2, "red", 2)
			connect_neighbour(mainpath.decider2, path.box, "green", 1)
			connect_neighbour(mainpath.decider2, path.belt2, "red", 2)
		else
			connect_neighbour(paths[i-1].belt1, path.belt1, "green")
			connect_neighbour(paths[i-1].belt2, path.belt2, "red")
		end
	end

	for i,path in ipairs(paths) do
		set_behavior(path.belt1, nil, "hold")

		set_behavior(path.belt2, {"signal-check", ">", "signal-red"}, nil)
	end

	for i,path in ipairs(paths) do
		for k,v in pairs(path) do
			if v.force ~= force then
				v.destructible = false
			end
		end
	end

end

function Duper.activate_output_link(data)
	local prodbox, dupebox, link = data.prodbox, data.dupebox, data.link

	local dupeface = game.surfaces["dupe-surface"]

	local y = Duper.INITIAL_DUPER_OFFSET_Y
	for id,link in pairs(dupebox.linked_belts) do
		if link.active then
			if y < link.area[2][2] then y = link.area[2][2] + Duper.DUPER_MARGIN_Y - 1 end
		end
	end
	local duper_area = Box{{0, 0}, {11, prodbox.multiplier+1}}:move(prodbox.position):move{-2,y}
	local duper_pos = duper_area[1]:add{2.5, 0.5}
	link.area = duper_area
	link.pos = duper_pos
	link.active = true

	Duper.scan_area{area=duper_area, prodbox=prodbox}

	local chest_area = Box{{0, 1}, {1, prodbox.multiplier}}:move(duper_pos):move{-2.5, 0.5}
	local wire_source = duper_pos:add{1, 1}
	link.chest_area = chest_area
	link.wire_source = wire_source
	link.missing_infinity_filters = true

	if Duper.DRAW_AREAS then
		dupeface.add_script_area{area=duper_area,name=dupebox.backer_name.." "..link.id}
		dupeface.add_script_area{area=chest_area,name="infinity-chests",color={1,0,0}}
		dupeface.add_script_position{position=wire_source,name="wire source", color={0,1,0}}
	end
	-- dupeface.add_script_position{position=duper_pos,name=dupebox.backer_name}

	local paths = {}

	local mainpath = {}


	Build.reset(prodbox)
	mainpath.input = Build.fef{name="dupe-linked-belt", pos=prodbox.position:add(link.offset):sub(link.dir)}[1]
	if not mainpath.input then
		-- DEBUG
		Game.dline{old=
			Array.of(Build.fef{area=prodbox.position:add(link.offset):sub(link.dir):grow(1)}):map{'{it.name,it.position}'}
		}
		mainpath.input = Build{name="dupe-linked-belt", pos=prodbox.position:add(link.offset):sub(link.dir)}
		Game.dline{new=
			Array.of(Build.fef{area=prodbox.position:add(link.offset):sub(link.dir):grow(1)}):map{'{it.name,it.position}'}
		}
	end

	Build.reset{offset=duper_pos, force="enemy"}

	mainpath.duper_input = Build{"dupe-linked-belt", offset = {0, 1}, type = "output"}
	mainpath.input.connect_linked_belts(mainpath.duper_input)

	mainpath.decider = Build{"dupe-decider-combinator", offset = {1, 0}}
	mainpath.decider2 = Build{"dupe-decider-combinator", offset = {4, 0}, direction = 2 + 4}


	for i,sub in ipairs(prodbox:get_active_subboxes()) do
		local path = {}
		if i == 1 then path = mainpath end
		paths[i] = path

		Build.reset(prodbox)
		Build.set{offset=duper_pos:add{0, i}, force="enemy"}

		path.belt1 = Build{"dupe-belt", offset={1, 0}}
		path.belt2 = Build{"dupe-belt", offset={2, 0}}

		if i ~= 1 then
			path.crate = Build{"dupe-infinity-chest", offset={-2, 0}}
			path.creator = Build{"dupe-loader", offset={-1, 0}, type = "output"}
		end
		path.loader = Build{"dupe-loader", offset={3, 0}, type = "input"}
		path.box = Build{"dupe-infinity-chest", offset={5, 0}}
		path.unloader = Build{"dupe-loader", offset={6, 0}, type = "output"}
		path.dupe_output = Build{"dupe-linked-belt", offset={8, 0}, type = "input"}

		Build.reset(sub)
		path.output = Build.fef{name = "dupe-linked-belt", pos = sub.position:add(link.offset):add(link.dir)}[1]
		path.output.connect_linked_belts(path.dupe_output)
	end
	
	for i,path in ipairs(paths) do
		for k,v in pairs(path) do
			if v.force ~= force then
				v.destructible = false
			end
		end
	end
	-- connect wires

	for i,path in ipairs(paths) do
		if i == 1 then
			connect_neighbour(path.decider, path.belt1, "green", 1)
			connect_neighbour(path.decider, path.belt2, "red", 2)
			connect_neighbour(path.decider2, path.box, "green", 1)
			connect_neighbour(path.decider2, path.belt2, "red", 2)
		end

		if i ~= 1 then
			connect_neighbour(paths[i-1].belt1, path.belt1, "green")
			connect_neighbour(paths[i-1].belt2, path.belt2, "red")
			connect_neighbour(paths[i-1].box, path.box, "green")
		end
	end

	-- fix config
	set_behavior(mainpath.decider, {"signal-anything", "=", #paths * 8, "signal-check", 1})
	set_behavior(mainpath.decider2, {"signal-anything", ">", #paths * 4, "signal-red", 1})

	for i,path in ipairs(paths) do
		set_behavior(path.belt1, nil, "hold")
		set_behavior(path.belt2, {"signal-check", ">", "signal-red"}, nil)
	end

end


function Duper.try_set_infinity_filters(data)
	local prodbox, dupebox, link = data.prodbox, data.dupebox, data.link

	local belt = game.surfaces[prodbox.surface].find_entities_filtered{position=link.wire_source}[1]
	if not belt then error("missing wire_source") end

	local signals = belt.get_merged_signals()

	if signals == nil or #signals == 0 then return end

	if #signals > 1 then
		Game.line("Dupebox bus "..serpent.line(v).."is broken:")
		Game.line("  - provided multiple items: "..serpent.line(signals))
		link.missing_infinity_filters = false
		return
	end

	Game.always(#signals == 1)

	local chests = game.surfaces[prodbox.surface].find_entities_filtered{
		name = "dupe-infinity-chest",
		area = link.chest_area,
	}
	for i,v in ipairs(chests) do
		v.infinity_container_filters = {{name=signals[1].signal.name,count=10,index=1}}
	end
	link.missing_infinity_filters = false

end

function Duper.scan_area(data)
	local area, prodbox = data.area, data.prodbox
	local dupeface = game.surfaces[prodbox.surface]

	dupeface.request_to_generate_chunks(area:center(),
										math.max(area:size()[1], area:size()[2]) / 64 + 1)
	dupeface.force_generate_chunk_requests()
	game.forces[prodbox.force].chart_all(dupeface)

end