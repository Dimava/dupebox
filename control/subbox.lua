
Subbox = {}
Subbox.meta = {}
setmetatable(Subbox, Subbox.meta)
Subbox.prototype = {__class = "Subbox"}
Subbox.metaprototype = {__index = Subbox.prototype}



function Subbox.of(o)
	setmetatable(o, Subbox.metaprototype)
	o.__class = o.__class
	if not o.entity_state then o.entity_state = {} end
	return o
end





function Subbox.prototype:wall_position_list()
	local box = self.area:grow(-0.5)
	local list = {}
	for i=0,box:width() do
		local wall = i > 1 and i < box:width()-1 and "dupe-wall" or "dupe-wall-angle"
		table.insert(list, {pos = box[1]:add{i, 0}, wall = wall, dir = 2})
		table.insert(list, {pos = box[1]:add{i, box:height()}, wall = wall, dir = 2})
	end
	for i=1,box:height()-1 do
		local wall = i > 1 and i < box:height()-1 and "dupe-wall" or "dupe-wall-angle"
		table.insert(list, {pos = box[1]:add{0, i}, wall = wall, dir = 0})
		table.insert(list, {pos = box[1]:add{box:width(), i}, wall = wall, dir = 0})
	end
	return list
end

function Subbox.prototype:stop_position()
	return self.position
end

function Subbox.prototype:raise_flying_text(text, pos_list, angle_text)
	Build.reset(self)
	if type(text) == "string" then text = {text=text, color={1,0.5,0.5}} end
	if type(angle_text) == "string" then angle_text = {text=angle_text, color={0.5,0.5,0.5}} end
	for i,v in ipairs(pos_list or {}) do
		Build{"flying-text", data=text, pos=v}
	end
	local box = self.area:grow(0.5)
	for i,v in ipairs(angle_text and {box[1],box[2],box:left_bottom(),box:right_top()} or {}) do
		Build{"flying-text", data=angle_text, pos=v}
	end
end

function Subbox.prototype:can_build(raise_flying_text)
	Build.reset(self)
	local canBuild = Build.can{"ghost", "dupe-train-stop", pos=self:stop_position(), dir=4}
	if not canBuild then
		if raise_flying_text then
			self:raise_flying_text("failed to build train stop here", {self:stop_position()},
									"failed to build train stop")
		end
		return false
	end

	local list = self:wall_position_list()
	local bad = {}
	for i,v in ipairs(list) do
		if not Build.can{v.wall, pos=v.pos, dir=v.dir,
					data={build_check_type=defines.build_check_type.blueprint_ghost}} then
			local dir = v.dir ~= 0 and Pos{1, 3} or Pos{3, 1}
			local found = Build.fef{area=v.pos:grow(dir:div(2))}
			local are_belts = Array.of(found):every{'it.type == "transport-belt"'}
			local same_dir = Array.of(found):every{'it.direction == '..found[1].direction}

			-- TODO: allow walls
			-- local area

			if not are_belts or not same_dir then
				Game.line{Array.of(found):map("it.direction"), are_belts=are_belts, same_dir=same_dir}
				table.insert(bad, v.pos)
			end
		end
	end
	if #bad > 0 then
		if raise_flying_text then
			self:raise_flying_text("failed to build wall here", bad,
									"failed to build "..#bad.." walls")
		end
		return false
	end

	return true
end

function Subbox.prototype:build_with_ghosts()
	if not self:can_build() then error("can't build!") end
	Build.reset(self)
	local stop = Build{"ghost", "dupe-train-stop", pos=self:stop_position(), dir=4}
	stop.backer_name = self.backer_name
	local list = self:wall_position_list()
	local bad = {}
	for i,v in ipairs(list) do

		if not Build.can{v.wall, pos=v.pos, dir=v.dir,
					data={build_check_type=defines.build_check_type.blueprint_ghost}} then
			local dir = v.dir ~= 0 and Pos{1, 3} or Pos{3, 1}
			local found = Build.fef{area=v.pos:grow(dir:div(2))}
			local direction = found[1].direction
			for i,v in ipairs(found) do v.order_deconstruction(self.force) end

			Build{"ghost", "dupe-linked-belt", pos=v.pos:sub(Pos.fromdir(direction)), dir=direction}

		end

		Build{"ghost", v.wall, pos=v.pos, dir=v.dir}
	end
	return stop
end

function Subbox.prototype:get_dupebox()
	return Dupebox.get(self.backer_name)
end

function Subbox.prototype:remove()
	table.exclude(self:get_dupebox().subboxes, self)
	table.exclude(DupeController.get().subboxes, self)
end

function Subbox.prototype:sync_built_entity(entity)
	if entity.name == "entity-ghost" then return end
	if not self.requested_blueprint_sync or self.requested_blueprint_sync == true then
		self.requested_blueprint_sync = entity.last_user and entity.last_user.name or true
	end
end

function Subbox.prototype:sync_built_entity_ghost(entity)
	if not self.requested_blueprint_sync or self.requested_blueprint_sync == true then
		self.requested_blueprint_sync = entity.last_user and entity.last_user.name or true
	end
end






function Subbox.create_and_add_from_selection_event(event)
	local box = Box(event.area):floor():grow(-0.5):normalize()
	if box:width() < 1 or box:height() < 1 then
		Game.line("Area is too small!!!")
		return
	end
	local stopPos = box:left_bottom():add{1,1}:round(2):sub{1,1}
	local area = Box{stopPos, box:right_top():sub{0.5,-0.5}}:normalize():grow(2)

	local backer_name = "1234567890123456789"
	while #backer_name > 12 do backer_name = game.backer_names[math.random(#game.backer_names)] end
	backer_name = "<"..backer_name.." "..(area:width()-2).."x"..(area:height()-2)..">"

	local subbox = Subbox.of{
		surface = event.surface.name,
		position = stopPos,
		area = area,
		force = event.player.force.name,
		backer_name = backer_name,
	}

	if not subbox:can_build(true) then
		return
	end

	local stop = subbox:build_with_ghosts()

	local stack = event.player.cursor_stack
	stack.set_stack("dupe-blueprint")
	stack.create_blueprint{
		surface = subbox.surface,
		force = subbox.force,
		area = subbox.area,
		include_station_names = true,
		include_fuel = true,
	}
	stack.label = "Dupebox "..stop.backer_name..""

	local entities = Array.of(stack.get_blueprint_entities())
	local bp_size = area:size():add{-0.1,-0.1}:round(2)
	local offset = Pos{0,0}

	local stop_position = Pos(entities:find{'it.name == "dupe-train-stop"'}.position)

	offset = stop_position
		:sub{0, bp_size[2]}
		:add{-2, 0}
		:round(2)

	for i,v in ipairs(entities) do
		v.position = Pos(v.position):sub(offset)
	end
	stack.set_blueprint_entities(entities)

	stack.blueprint_snap_to_grid = bp_size

	local dc = DupeController.get()

	Dupebox.create_and_add_from_subbox(subbox)
end



function Subbox.create_and_add_from_train_stop_ghost(entity)
	if not entity.backer_name then
		Game.line("Use dupe-planner instead!!!")
		entity.destroy()
		return nil
	end
	if entity.direction ~= 4 then
		Game.line("Dupebox rotation is not supported!!!")
		entity.destroy()
		return nil
	end
	local dupebox = Dupebox.get(entity.backer_name)
	if not dupebox then
		Game.line("Use dupe-planner instead!!!")
		entity.destroy()
		return nil
	end
	local subbox = Subbox.of{
		surface = entity.surface.name,
		position = Pos(entity.position),
		area = Box{{0,0}, dupebox.size}:move{-2, 2-dupebox.size[2]}:move(entity.position),
		force = entity.force.name,
		backer_name = entity.backer_name,
	}
	Dupebox.create_and_add_from_subbox(subbox)
end

function Subbox.create_and_add_from_train_stop(entity)
	if not entity.backer_name then
		Game.line("Use dupe-planner instead!!!")
		entity.destroy()
		return nil
	end
	if entity.direction ~= 4 then
		Game.line("Dupebox rotation is not supported!!!")
		entity.destroy()
		return nil
	end
	local dupebox = Dupebox.get(entity.backer_name)
	if not dupebox then
		Game.line("Use dupe-planner instead!!!")
		entity.destroy()
		return nil
	end
	local subbox = table.find(dupebox.subboxes, function(v)return Pos(v.position):equals(entity.position) end)
	if not subbox then
		subbox = Subbox.of{
			surface = entity.surface.name,
			position = Pos(entity.position),
			area = Box{{0,0}, dupebox.size}:move{-2, 2-dupebox.size[2]}:move(entity.position),
			force = entity.force.name,
			backer_name = entity.backer_name,
		}
		Dupebox.create_and_add_from_subbox(subbox)
	end
end

function Subbox.remove_train_stop(entity)
	if not entity.backer_name then return end
	local dupebox = Dupebox.get(entity.backer_name)
	local subbox = dupebox:subbox_at_train_pos(entity.position, entity.surface.name)
	subbox:remove()
end

function Subbox.remove_train_stop_ghost(entity)
	if not entity.backer_name then return end
	local dupebox = Dupebox.get(entity.backer_name)
	local subbox = dupebox:subbox_at_train_pos(entity.position, entity.surface.name)
	if subbox then subbox:remove() end
end

function Subbox.get_from_train_stop_position(pos, surface)
	pos = Pos(pos)
	for i,v in ipairs(DupeController.get().subboxes) do
		if pos:equals(v.position) and surface == v.surface then
			return v
		end
	end
	return nil
end
function Subbox.get_from_train_stop(stop)
	local pos = Pos(stop.position)
	local surface = stop.surface.name
	for i,v in ipairs(DupeController.get().subboxes) do
		if pos:equals(v.position) and surface == v.surface then
			return v
		end
	end
	return nil
end

function Subbox.get_from_entity(entity)
	return Subbox.get_from_position(entity.position, entity.surface)
end

function Subbox.parse_linked_belt(entity)
	local name = entity.name == "entity-ghost" and entity.ghost_name or entity.name
	local pos = Pos(entity.position)
	if entity.linked_belt_type == "input" then
		pos = pos:add(Pos.fromdir(entity.direction))
	else
		pos = pos:sub(Pos.fromdir(entity.direction))
	end
	local subbox = Subbox.get_from_position(pos, entity.surface)
	if not subbox then return {} end
	return {id=subbox:entity_id{name=name,pos=pos}, pos=pos, offset=pos:sub(subbox.position),
			surface=entity.surface.name, dir=Pos.fromdir(entity.direction),
			direction=entity.direction, subbox=subbox}
end

function Subbox.get_from_linked_belt(entity)
	return Subbox.parse_linked_belt(entity).subbox
end

function Subbox.get_from_position(position, surface)
	local pos = Pos(position)
	if type(surface) ~= "string" then surface = surface.name end
	for i,v in ipairs(DupeController.get().subboxes) do
		if v.surface == surface then
			local box = v.area
			if box[1][1] < pos[1] and pos[1] < box[2][1]
					and box[1][2] < pos[2] and pos[2] < box[2][2] then
				return v
			end
		end
	end
	return nil
end


function Subbox.prototype:make_blueprint(grow)
	local inv = game.create_inventory(1)
	local stack = inv.find_empty_stack()
	stack.set_stack("dupe-blueprint")
	stack.create_blueprint{
		surface = self.surface,
		force = self:get_dupebox().force,
		area = self.area:grow(grow or 1),
		include_station_names = true,
		include_fuel = true,
	}
	local subbox = self
	local function build(data)
		data = data or {}
		local res = stack.build_blueprint{
			surface = data.surface or subbox.surface,
			force = data.force or subbox:get_dupebox().force,
			position = data.position,
			force_build = data.force_build == nil and true or data.force_build,
			-- direction=…,
			skip_fog_of_war = data.skip_fog_of_war  == nil and true or data.skip_fog_of_war,
			by_player = data.by_player,
			-- raise_built=…
		}
		if not data.keep then inv.destroy() end
		return res
	end
	return {inv = inv, stack = stack, build = build}
end 

function Subbox.prototype:check_walls_built()
	local list = self:wall_position_list()
	local surface = self:get_surface()
	local data = {stop_built=false, walls_built=0, walls_total=#list, all_walls_built=false, complete=false}
	
	Build.reset(self)
	data.stop_built = 0 < #Build.fef{name="dupe-train-stop", pos=self:stop_position()}
	for i,v in ipairs(list) do
		local found = Build.fef{name=v.wall, pos=v.pos}
		if #found > 0 then
			data.walls_built = data.walls_built + 1
			end
	end

	data.all_walls_built = data.walls_built == data.walls_total
	data.complete = data.stop_built and data.all_walls_built or false
	return data
end

function Subbox.prototype:get_surface()
	return game.surfaces[self.surface]
end

function Subbox.prototype:can_activate()
	return self:check_walls_built().complete
end

function Subbox.prototype:entity_id(entity)
	local name = entity.name == "entity-ghost" and entity.ghost_name or entity.name
	local pos = Pos(entity.position or entity.pos)
	local offset = pos and pos:sub(self.position) or entity.offset
	return name.."@("..offset[1]..","..offset[2]..")"
end

function Subbox.prototype:process_activation(data)

	local list = self:wall_position_list()
	local surface = self:get_surface()
	local data = {stop_built=false, walls_built=0, walls_total=#list, all_walls_built=false, complete=false}
	
	Build.reset(self)
	local stop = Build.fef{name="dupe-train-stop", pos=self:stop_position()}[1]
	stop.minable = false
	for i,v in ipairs(list) do
		local found = Build.fef{name=v.wall, pos=v.pos}[1]
		found.minable = false
	end

	data.all_walls_built = data.walls_built == data.walls_total
	data.complete = data.stop_built and data.all_walls_built or false

	self.activated = true
end