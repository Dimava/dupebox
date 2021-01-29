require('control/Pos')
require('control/Box')


Build = {}
Build.__proto__ = {}
Build.meta = {__index = Build.__proto__}
setmetatable(Build, Build.meta)

Build.defaults = {
	offset = Pos{0, 0},
	direction = 2,
	surface = "dupe-surface",
	force = "enemy",
}

function Build.meta:__call(o)
	local data, v = Build.parse_data(o)

	-- v.surface.create_entity(data)
	local run,entity = pcall(v.surface.create_entity,data)
	if not run or o.run and not entity then error("Error on create_entity: "..entity.."\n"..serpent.block(data)) end

	-- if entity == nil and o.force_replace then
	-- 	local bad = surface.find_entities_filtered{area={{data.position[1]-0.5,data.position[2]-0.5},{data.position[1]+0.5,data.position[2]+0.5}}}
	-- 	if bad ~= nil and #bad > 0 then
	-- 		for i,v in ipairs(bad) do
	-- 			if v.type ~= "character" then
	-- 				v.destroy()
	-- 			end
	-- 		end
	-- 	end
	-- end

	return entity
end

function Build.can(o)
	local data, v = Build.parse_data(o)
	return v.surface.can_place_entity(data)
end

function Build.parse_data(o)

	local data = {}

	data.name = o.name or o[1]
	-- if data.name == nil then error("Build: missing name") end

	if o.position or o.pos then
		if o.offset then
			data.position = Pos(o.position or o.pos):add(o.offset)
		else
			data.position = Pos(o.position or o.pos)
		end
	else
		data.position = Pos(Build.defaults.offset):add(o.offset or {0,0})
	end
	data.direction = (o.direction or o.dir or Build.defaults.direction) % 8

	local inner_name = o.inner_name or o[2]
	if data.name == "entity-ghost" or data.name == "ghost" and game.entity_prototypes[inner_name] then
		data.name = "entity-ghost"
		data.inner_name = inner_name
	end
	if data.name == "corpse" then
		for k,v in pairs(game.entity_prototypes[inner_name].corpses) do data.name = k break end
		data.direction = data.direction / 2
		if o.type == "output" then data.direction = data.direction + 4 end
	end

	local surface = o.surface or Build.defaults.surface
	if type(surface) == "string" then surface = game.surfaces[surface] end

	if o.type then data.type = o.type end
	if o.player then data.player = o.player end
	data.force = o.force or Build.defaults.force

	if o.data then for k,v in pairs(o.data) do data[k] = v end end

	if o.debug then Game.dline{data, surface=surface.name} end
	return data, {surface = surface}
end

function Build.fef(data, arg2)
	if arg2 then error("outdated!") end
	if not data then data, surface = surface, Build.defaults.surface end
	-- local data2, v = Build.parse_data(data)
	-- data.position = data2.position
	-- Game.line{data=data}
	if data.area then data.area = Box(data.area) end
	if data.pos then data.position = data.pos data.pos = nil end
	if data.position then data.position = Pos(data.position) end
	if data.offset then
		local pos = data.position or Build.defaults.offset
		data.position = Pos(pos):add(data.offset)
		data.offset = nil
	end
	local surface = game.surfaces[data.surface and data.surface.name or data.surface or Build.defaults.surface]
	-- Game.line{"fef", surface=surface.name, data=data}
	local found = surface.find_entities_filtered(data)
	data.surface = surface
	return found
end

function Build.fef_or_ghost(data)
	local found = Build.fef(data)
	if #found then return found end
	data.ghost_name = data.name
	data.name = nil
	return Build.fef(data)
end


function Build.reset(data)
	Build.defaults = {
		offset = Pos{0,0},
		direction = 2,
		surface = "dupe-surface",
		force = "enemy",
	}
	Build.set(data)
end

function Build.set(data)
	local function str_or_name(e)
		if type(e) == "string" then return e end
		return e.name
	end
	data = data or {}
	if data.object_name == "LuaEntity" then
		data = {offset = data.position, direction = data.direction, surface = data.surface.name, force = data.force.name}
	end
	if data.offset then
		Build.defaults.offset = Pos(data.offset or data.position)
	end
	if data.direction then
		Build.defaults.direction = data.direction
	end
	if data.surface then
		Build.defaults.surface = str_or_name(data.surface)
	end
	if data.force then
		Build.defaults.force = str_or_name(data.force)
	end
end

function Build.mine_and_spill(entity, mine, spill, subtract)
	if not entity.valid then return end
	local inventory = game.create_inventory(10)
	local surface = entity.surface
	local position = Pos(entity.position)
	mine = mine or {}
	spill = spill or {}
	mine.inventory = inventory
	subtract = table.deepcopy(subtract or {})
	local mined, empty
	repeat
		if mine.debug then Game.dline{"mining", entity.position} end
		mined = entity.mine(mine)
		local empty = true
		for k,v in pairs(subtract) do
			local delta = inventory.remove(v)
			if delta > 0 then
				empty = false
				v.count = v.count - delta
				if v.count == 0 then subtract[k] = nil end
			end
		end
		for i=1,#inventory do
			local stack = inventory[i]
			if stack.count then
				empty = false
				spill.position = position
				spill.stack = stack
				Build.spill(spill)
			end
		end
		if empty then break end
	until(mined)
	inventory.destroy()
end

function Build.spill(data)
	local surface = data.surface or Build.defaults.surface
	local allow_belts = data.allow_belts ~= nil or data.allow_belts
	surface = game.surfaces[surface.name or surface]
	local inventory = data.inventory or data.inv or {data.stack}
	for i=1,#inventory do
		local stack = inventory[i]
		if stack.count then
			surface.spill_item_stack(
				data.position, stack, data.enable_looted, data.force, allow_belts)
		end
	end

end

function Build.fake_kill_and_mine(entity)

end




function set_behavior(entity, bdata, data)
	local function to_signal(s)
		if type(s) == "table" then return s end
		if s:sub(1, 7) == "signal-" then return {type="virtual", name=s} end
		return {type="item", name=s}
	end

	if entity.type == "decider-combinator" then
		local parameters = {
			first_signal = to_signal(bdata[1]),
			comparator = bdata[2],
			second_signal = type(bdata[3]) ~= "number" and to_signal(bdata[3]) or nil,
			constant = type(bdata[3]) == "number" and bdata[3] or nil,
			output_signal = to_signal(bdata[4]),
			copy_count_from_input = bdata[5] ~= 1 and true or false
		}
		local behaviour = entity.get_control_behavior()
		behaviour.parameters = parameters
		return behaviour
	end

	if entity.type == "arithmetic-combinator" then
		local parameters = {
			first_signal = type(bdata[1]) ~= "number" and to_signal(bdata[1]) or nil,
			first_constant = type(bdata[1]) == "number" and bdata[1] or nil,
			operation = bdata[2],
			second_signal = type(bdata[3]) ~= "number" and to_signal(bdata[3]) or nil,
			second_constant = type(bdata[3]) == "number" and bdata[3] or nil,
			output_signal = to_signal(bdata[4]),
		}
		local behaviour = entity.get_control_behavior()
		behaviour.parameters = parameters
		return behaviour
	end

	if entity.type == "transport-belt" then
		local behaviour = entity.get_control_behavior()

		if bdata == nil then
			behaviour.enable_disable = false
		else
			behaviour.enable_disable = true
			behaviour.circuit_condition = {
				condition = {
					first_signal = to_signal(bdata[1]),
					comparator = bdata[2],
					second_signal = type(bdata[3]) ~= "number" and to_signal(bdata[3]) or nil,
					constant = type(bdata[3]) == "number" and bdata[3] or nil,
				}
			}
		end

		if data == nil then
			behaviour.read_contents = false
		else
			behaviour.read_contents = true
			if type(data) == "string" then
				behaviour.read_contents_mode = defines.control_behavior.transport_belt.content_read_mode[data]
			else
				behaviour.read_contents_mode = data
			end
		end

		return behaviour
	end



	error("unsuported set_behavior type: "..entity.type)
end

function connect_neighbour(src, target, wire, source_circuit_id, target_circuit_id)
	if not src then error("connect_neighbour: source not set") end
	if not target then error("connect_neighbour: target not set") end
	local wire_type = wire
	if wire == "red" then wire_type = defines.wire_type.red end
	if wire == "green" or wire == nil then wire_type = defines.wire_type.green end
	local data = {
		target_entity = target,
		wire = wire_type,
		source_circuit_id = source_circuit_id or nil,
		target_circuit_id = target_circuit_id or nil,
	}
	src.connect_neighbour(data)
end


function connect_linked_belts(a, b)
	if a.linked_belt_type == b.linked_belt_type then error("same linked_belt_type") end
	a.connect_linked_belts(b)
	if a.linked_belt_neighbour ~= b then error("failed to connect!") end
	Game.line{"succesfully connected!", a.surface.name, a.position, b.surface.name, b.position}
end






-- 	local run,entity = pcall(surface.create_entity,data)
-- 	if not run then error("not entity: "..serpent.block(data)) end
-- 	return entity
-- end

-- function set_behavior(entity, bdata, data)
-- 	local function to_signal(s)
-- 		if type(s) == "table" then return s end
-- 		if s:sub(1, 7) == "signal-" then return {type="virtual", name=s} end
-- 		return {type="item", name=s}
-- 	end

-- 	if entity.type == "decider-combinator" then
-- 		local parameters = {
-- 			first_signal = to_signal(bdata[1]),
-- 			comparator = bdata[2],
-- 			second_signal = type(bdata[3]) ~= "number" and to_signal(bdata[3]) or nil,
-- 			constant = type(bdata[3]) == "number" and bdata[3] or nil,
-- 			output_signal = to_signal(bdata[4]),
-- 			copy_count_from_input = bdata[5] ~= 1 and true or false
-- 		}
-- 		local behaviour = entity.get_control_behavior()
-- 		behaviour.parameters = parameters
-- 		return behaviour
-- 	end

-- 	if entity.type == "arithmetic-combinator" then
-- 		local parameters = {
-- 			first_signal = type(bdata[1]) ~= "number" and to_signal(bdata[1]) or nil,
-- 			first_constant = type(bdata[1]) == "number" and bdata[1] or nil,
-- 			operation = bdata[2],
-- 			second_signal = type(bdata[3]) ~= "number" and to_signal(bdata[3]) or nil,
-- 			second_constant = type(bdata[3]) == "number" and bdata[3] or nil,
-- 			output_signal = to_signal(bdata[4]),
-- 		}
-- 		local behaviour = entity.get_control_behavior()
-- 		behaviour.parameters = parameters
-- 		return behaviour
-- 	end

-- 	if entity.type == "transport-belt" then
-- 		local behaviour = entity.get_control_behavior()

-- 		if bdata == nil then
-- 			behaviour.enable_disable = false
-- 		else
-- 			behaviour.enable_disable = true
-- 			behaviour.circuit_condition = {
-- 				condition = {
-- 					first_signal = to_signal(bdata[1]),
-- 					comparator = bdata[2],
-- 					second_signal = type(bdata[3]) ~= "number" and to_signal(bdata[3]) or nil,
-- 					constant = type(bdata[3]) == "number" and bdata[3] or nil,
-- 				}
-- 			}
-- 		end

-- 		if data == nil then
-- 			behaviour.read_contents = false
-- 		else
-- 			behaviour.read_contents = true
-- 			if type(data) == "string" then
-- 				behaviour.read_contents_mode = defines.control_behavior.transport_belt.content_read_mode[data]
-- 			else
-- 				behaviour.read_contents_mode = data
-- 			end
-- 		end

-- 		return behaviour
-- 	end



-- 	error("unsuported set_behavior type: "..entity.type)
-- end

-- function connect_neighbour(src, target, wire, source_circuit_id, target_circuit_id)
-- 	local wire_type = wire
-- 	if wire == "red" then wire_type = defines.wire_type.red end
-- 	if wire == "green" or wire == nil then wire_type = defines.wire_type.green end
-- 	local data = {
-- 		target_entity = target,
-- 		wire = wire_type,
-- 		source_circuit_id = source_circuit_id or nil,
-- 		target_circuit_id = target_circuit_id or nil,
-- 	}
-- 	src.connect_neighbour(data)
-- end


-- function extend_position(x, y, radius)
-- 	return {{x-radius,y-radius},{x+radius,y+radius}}
-- end

-- function pos_diff(a, b)
-- 	return (a.x-b.x)*(a.x-b.x)+(a.y-b.y)*(a.y-b.y)
-- end



-- return cutil




Event = {}
Event.meta = {}
Event.prototype = {__class = "Event"}
Event.metaprototype = Event.prototype -- {__index = Event.prototype}
setmetatable(Event, Event.meta)

function Event.prototype:__index(key)
	if key == "player" then
		self.player = game.players[self.player_index]
		return self.player
	end
	if key == "entity" then
		local entity = self.created_entity
		self.entity = entity
		return entity
	end
	return nil
end

function Event.of(o)
	return setmetatable(o, Event.metaprototype)
end







Script = {}
Script.register = {}
Script.registered = {}
Script.__proto__ = {}
Script.meta = {__index = Script.__proto__}
setmetatable(Script, Script.meta)


function Script.on(name, callback, filter)
	if defines.events["on_"..name] then name = "on_"..name end
	if type(callback) ~= "function" then callback, filter = filter, callback end
	if Script.register[name] then
		return Script.register[name](callback, Script.parse_filter(filter))
	end
	script.on_event(
		defines.events[name],
		function(event) return callback(Event.of(event)) end,
		Script.parse_filter(filter)
	)
end

function Script.meta:__newindex(key, value)
	if key:sub(1, 3) ~= "on_" then return rawset(self, key, value) end
	Script.on(key, value, nil)
end

function Script.meta:__index(key, value)
	if key:sub(1, 3) ~= "on_" then return nil end
	return function(value, filter)
		return Script.on(key, value, filter)
	end
end

function Script.register.on_player_selected_area(fn, o)
	if type(fn) ~= "function" then fn, o = o, fn end
	if type(o) ~= "string" then
		script.on_event(defines.events.on_player_selected_area, function(event)
			return fn(Event.of(event))
		end)
		return
	end
	script.on_event(defines.events.on_player_selected_area, function(event)
		if event.item ~= item then return end
		return fn(Event.of(event))
	end)
end

function Script.register.on_built_entity(fn)
	script.on_event(defines.events.on_built_entity, function(event)
		return fn(Event.of(event))
	end)
end








-- script.set_event_filter(defines.events.on_built_entity, {{filter = "name", name = "fast-inserter"}})
-- script.set_event_filter(defines.events.on_entity_died, {{filter = "type", type = "unit"}, {filter = "name", name = "fast-inserter"}})

-- script.on_event(defines.events.on_entity_damaged,
--   function(e) game.print("A wall was damaged on tick " .. e.tick) end,
--   {{filter="type", type = "wall"}})







function Script.parse_filter(o)
	if o == nil then return nil end
	if type(o) == "string" then o = {o} end
	if type(o[1]) ~= "table" then o = {o} end
	o = table.deepcopy(o)
	local data = {}
	for i,v in ipairs(o) do
		local filter = {}
		local unused = nil
		for k,f in pairs(v) do
			if type(k) == "number" then
				if f == "and" or f == "or" then filter.mode = f
				elseif f == "invert" then filter.invert = true
				else filter.filter = f end
			else
				if k == "invert" then filter.invert = f
				elseif k == "filter" then filter.filter = f
				else -- either second prop or single prop
					if v.filter then
						filter[k] = f
					else
						filter.filter = k
						filter[Script.filter_types[k] or k] = f
					end
				end
			end
		end
		table.insert(data, filter)
	end
	return data
end


Script.filter_types = {
	type = "type",
	name = "name",
	ghost_type = "type",
	ghost_name = "name",
	["damage-type"] = "type",
}






Game = {}


function Game.block(data)
	return game.print(serpent.block(data))
end
function Game.line(data)
	return game.print(serpent.line(data))

	-- if #arg == 1 then return game.print(serpent.line(arg[1])) end
	-- local s = ""
	-- for i,v in ipairs(arg) do
	-- 	if i > 1 then s = s.." " end
	-- 	if type(v) == "string" or type(v) == "number" then s = s..v
	-- 	else s = s..serpent.line(v) end
	-- end
end


Game.debug = true

function Game.dline(data)
	if Game.debug == false then return end
	local str = serpent.line(data)
	if Game.debug == true then
		local i = 0
		for s in debug.traceback():gmatch("[^\r\n]+") do
			i = i + 1
			if 2 < i and i < 5 then str = str.."\n                @"..s end
		end
	end
	return game.print(str)

	-- if #arg == 1 then return game.print(serpent.line(arg[1])) end
	-- local s = ""
	-- for i,v in ipairs(arg) do
	-- 	if i > 1 then s = s.." " end
	-- 	if type(v) == "string" or type(v) == "number" then s = s..v
	-- 	else s = s..serpent.line(v) end
	-- end
end

Game.line = Game.dline

function Game.TODO(message, data)
	error("Non-implemented error: "..message.."\n"..(data and serpent.block(data) or ""))
end

function Game.always(condition, message, data)
	if condition then return end
	error("Non-implemented error: "..message.."\n"..(data and serpent.block(data) or ""))
end












function table.includes(array, value)
	for i,v in ipairs(array) do
		if v == value then return true end
	end
	return false
end


function table.includes_or_insert(array, value)
	for i,v in ipairs(array) do
		if v == value then return true end
	end
	table.insert(array, value)
	return false
end

function table.find(array, callback)
	for i,v in ipairs(array) do
		if callback(v) then return v end
	end
	return nil
end

function table.exclude(array, value)
	for i,v in ipairs(array) do
		if v == value then
			table.remove(array, i)
			return true
		end
	end
	return false
end

function table.keys(array)
	local keys = {}
	for k,v in pairs(array) do
		keys[#keys+1] = k
	end
	return keys
end

function table.filter(array, callback)
	local res = {}
	for i,v in ipairs(array) do
		if callback(v, i, array) then table.insert(res, v) end
	end
	return res
end

function table.map(array, callback)
	local res = {}
	for i,v in ipairs(array) do
		res[i] = callback(v, i, array)
	end
	return res
end






Array = {}
Array.meta = {}
Array.prototype = {__class = "Array"}
Array.metaprototype = {__index = Array.prototype}
setmetatable(Array, Array.meta)


function Array.of(o)
	return setmetatable(o, Array.metaprototype)
end

function Array.from(array)
	local res = {}
	for i,v in ipairs(array) do
		res[i] = v
	end
	return Array.of(res)
end


function Array.prototype:filter(callback)
	callback = Array._as_function(callback)
	local res = {}
	for i,v in ipairs(self) do
		if callback(v, i, self) then table.insert(res, v) end
	end
	return Array.of(res)
end

function Array.prototype:map(callback)
	callback = Array._as_function(callback)
	local res = {}
	for i,v in ipairs(self) do
		res[i] = callback(v, i, self)
	end
	return Array.of(res)
end

function Array.prototype:mapNotNil(callback)
	callback = Array._as_function(callback)
	local res = {}
	for i,v in ipairs(self) do
		local r = callback(v, i, self)
		if r ~= nil then table.insert(res, r) end
	end
	return Array.of(res)
end

function Array.prototype:find(callback)
	callback = Array._as_function(callback)
	for i,v in ipairs(self) do
		if callback(v, i, self) then return v end
	end
end

function Array.prototype:each(callback)
	callback = Array._as_function(callback)
	for i,v in ipairs(self) do
		callback(v, i, self)
	end
	return self
end

function Array.prototype:length()
	return #self
end

function Array.prototype:includes(value)
	for i,v in ipairs(self) do
		if v == value then return true end
	end
	return false
end

function Array.prototype:objectFromEntries()
	return Object.fromEntries(self)
end

function Array.prototype:every(callback)
	callback = Array._as_function(callback)
	for i,v in ipairs(self) do
		if not callback(v, i, self) then return false end
	end
	return true
end

function Array._as_function(fn)
	if type(fn) == "function" then return fn end
	if type(fn) == "table" and #fn == 1 and type(fn[1]) == "string" then fn = fn[1] end
	if type(fn) == "string" then
		return loadstring(
			"return function(it) return "..fn.." end"
		)()
	end 
	Game.line(fn)
	error("unknown callback type")
end



Object = {}
Object.meta = {}
Object.prototype = {__class = "Object"}
Object.metaprototype = {__index = Object.prototype}
setmetatable(Object, Object.meta)

function Object.of(o)
	setmetatable(o, nil)
	o.__class = nil
	return setmetatable(o, Object.metaprototype)
end

function Object.fromEntries(array)
	local res = {}
	for i,v in ipairs(array) do
		res[v[1]] = v[2]
	end
	return Object.of(res)
end

function Object.prototype:keys()
	local res = {}
	for k,v in pairs(self) do
		if k ~= "__class" then
			table.insert(res, k)
		end
	end
	return Array.of(res)
end

function Object.keys(o)
	local res = {}
	for k,v in pairs(o) do
		if k ~= "__class" then
			table.insert(res, k)
		end
	end
	return Array.of(res)
end