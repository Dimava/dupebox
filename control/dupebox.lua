require('control/subbox')
require('control/prodbox')


Dupebox = {}
Dupebox.meta = {}
setmetatable(Dupebox, Dupebox.meta)
Dupebox.prototype = {__class = "Dupebox"}
Dupebox.metaprototype = {__index = Dupebox.prototype}

DupeController = {}
DupeController.meta = {}
setmetatable(DupeController, DupeController.meta)
DupeController.prototype = {__class = "DupeController"}
DupeController.metaprototype = {__index = DupeController.prototype}







function Dupebox.of(o)
	setmetatable(o, Dupebox.metaprototype)
	o.__class = o.__class
	if not o.subboxes then o.subboxes = {} end
	if not o.entity_state then o.entity_state = {} end
	if not o.prodbox then o.prodbox = Prodbox.create_empty(o) end
	if not o.linked_belts then o.linked_belts = {} end
	return o
end


function DupeController.of(o)
	setmetatable(o, DupeController.metaprototype)
	o.__class = o.__class
	return o

end

function DupeController.serialize(o)
	local visited = {}
	local function dig(o)
		if type(o) ~= "table" then return end
		if visited[o] then return end
		visited[o] = true
		rawset(o, "__class", o.__class)
		for k,v in pairs(o) do
			dig(v)
		end
	end
	dig(o)
end

function DupeController.deserialize(o)
	local visited = {}
	local function dig(o)
		if type(o) ~= "table" then return end
		if visited[o] then return end
		visited[o] = true
		if not getmetatable(o) and o.__class then
			local class = _G[o.__class]
			if class and class.of then class.of(o)
			elseif class and class.metaprototype then
				setmetatable(o, class.metaprototype)
			end
		end
		for k,v in pairs(o) do
			dig(v)
		end
	end
	dig(o)
end

function DupeController.initialize()
	if not global.DupeController then
		global.DupeController = DupeController.create()
	else
		if getmetatable(global.DupeController) == nil then
			DupeController.deserialize(global.DupeController)
		end
	end
	return global.DupeController
end

local _dc = nil
function DupeController.get()
	if _dc == nil then
		_dc = DupeController.initialize()
	end
	return _dc
end


function DupeController.create()
	return DupeController.of{
		dupeboxes = {},
		subboxes = {},
		train_stops = {},
	}
end


-- function DupeController.prototype:add_train_stop(stop)
-- 	local dc = DupeController.get()

-- 	local data = {
-- 		__class = "DupeTrainStop",
-- 		id = "stop_"..stop.surface.name.."("..stop.position.x..","..stop.position.y..")",
-- 		position = Pos(stop.position),
-- 		surface = stop.surface.name,
-- 		backer_name = stop.backer_name,
-- 	}

-- 	dc.train_stops[data.id] = data
-- end


-- function DupeController.prototype:rename_train_stop(stop)

-- end
-- function DupeController.prototype:remove_train_stop(stop)

-- end


-- function DupeController.prototype:rename_train_stop(stop)

-- end
-- function DupeController.prototype:rename_train_stop(stop)

-- end






function Dupebox.create_and_add_from_subbox(subbox)
	DupeController.serialize(subbox)

	local dc = DupeController.get()
	local dupebox = dc.dupeboxes[subbox.backer_name]
	if dupebox == nil then
		dupebox = Dupebox.of{
			size = subbox.area:size(),
			force = subbox.force,
			backer_name = subbox.backer_name,
			subboxes = {subbox},
		}
		dc.dupeboxes[subbox.backer_name] = dupebox
		DupeController.serialize(dupebox)
	end

	Game.always(subbox.area:size():equals(dupebox.size), "subbox size differs from dupebox size!")

	local r = table.includes_or_insert(dupebox.subboxes, subbox)
	table.includes_or_insert(dc.subboxes, subbox)

	Build.reset(subbox)
	for k,link in pairs(dupebox.linked_belts) do
		local area = Pos(subbox.position):add(link.offset):grow(link.dir):normalize():grow(0.5)
		local found = Build.fef{type="transport-belt", area=area}
		if #found > 0 then
			-- Game.line{Array.of(found):map{'{it.name, dir=it.direction}'}}
			for i,v in ipairs(found) do v.order_deconstruction(dupebox.force) end
		end
	end
	dupebox:copy_ghosts(dupebox.subboxes[1], {subbox})
	subbox.requested_blueprint_sync = true

	return dupebox

end

function Dupebox.prototype:subbox_at_train_pos(pos, surface)
	pos = Pos(pos)
	for i,v in ipairs(self.subboxes) do
		if pos:equals(v.position) and surface == v.surface then
			return v
		end
	end
	return nil
end

function Dupebox.get(backer_name)
	local dc = DupeController.get()
	return dc.dupeboxes[backer_name]
end

function Dupebox.prototype:recreate_train_stop_gui(player)
	local gui = player.gui.relative
	local frame = gui.dupe_train_gui or
					gui.add{type="frame", name="dupe_train_gui", direction="vertical"}
	frame.clear()
	frame.anchor = {
		gui = defines.relative_gui_type.train_stop_gui,
		position = defines.relative_gui_position.left,
		name = "dupe-train-stop",
	}

	frame.add{type="label", caption="Dupebox "..self.backer_name}
	frame.add{type="line"}

	local activateable = #table.filter(self.subboxes, function(v)return not v.activated and v:can_activate() end)
	local activated_count = #table.filter(self.subboxes, function(v)return v.activated end)

	local data = {
		"Size: "..serpent.line(Pos(self.size):sub{2,2}),
		"Subboxes: "..#self.subboxes,
		"  - activated: "..activated_count.."/"..#self.subboxes,
		"  - can be activated: "..activateable.."/"..(#self.subboxes - activated_count),
		(activateable < (#self.subboxes - activated_count)) and
			("(deactivation will destroy everything inside so activate "..
						"AFTER ALL WALLS AND STOPS ARE BUILT) (they are not built yet)"),
		"Prodbox: "..(self.prodbox.activated and "activated" or "inactive"),

	}
	for i,v in ipairs(data) do
		if type(v) == "table" then
			if type(v.condition) == "function" then v.condition = v.condition() end
			if v.condition == false then v = "" end
			if type(v.value) == "function" then v = v.value() end
		end
		if v and v ~= "" then
			frame.add{type="label", caption=v}
		end
	end

	if not self.prodbox.activated then
		frame.add{type="button", name="dupe_btn_activate", caption="ACTIVATE"}
	else
		if player.surface.name == self.prodbox.surface then
			frame.add{type="button", name="dupe_btn_tp_out", caption="TELEPORT OUTSIDE"}
		else
			frame.add{type="button", name="dupe_btn_tp_in", caption="TELEPORT INSIDE"}
		end
	end

end

function Dupebox.prototype:copy_ghosts(subbox, targets, options)
	targets = targets or self.subboxes
	options = options or {}
	local bp = subbox:make_blueprint(0)

	for i,subbox in ipairs(targets) do
		bp.build{
			position = subbox.area:center(),
			by_player = options.player,
			keep = true,
		}
	end
	bp.inv.destroy()
end

function Dupebox.prototype:activate(data)
	if data.entity and not data.subbox then data.subbox = Subbox.get_from_entity(data.entity) end



	self.prodbox:process_dupebox_activation(data)
end

-- function Dupebox.prototype:sync_built_entity(entity, subbox)
-- 	local offset = Pos(entity.position):sub(subbox.position)
-- 	local id = entity.name.."@("..offset[1]..","..offset[2]..")"

-- 	local gdata = self.entity_state[id]
-- 	local is_new = false
-- 	if not gdata then
-- 		gdata = {id=id, offset=offset, state={}}
-- 		self.entity_state[id] = gdata
-- 	end

-- 	gdata.state = {}

-- 	if subbox.entity_state[id] then
-- 		subbox.entity_state[id].state = "built"
-- 	else
-- 		subbox.entity_state[id] = {id=id, state="built"}
-- 	end

-- 	Build.reset(entity)
-- 	Build.set{offset = offset}
-- 	for i,subbox in ipairs(self.subboxes) do
-- 		if not subbox.entity_state[id] then
-- 			local e = Build{"ghost", entity.name, offset=subbox.position, debug=true}
-- 			subbox.entity_state[id] = {id=id, state="ghost"}
-- 		end
-- 		local es = subbox.entity_state[id]
-- 		gdata.state[es.state] = (gdata[es.state] or 0) + 1
-- 	end

-- 	if #table.keys(gdata.state) == 1 then
-- 		Dupebox.prototype:on_sync_state_syncronized(id)
-- 	end

-- end

-- function Dupebox.prototype:on_sync_state_syncronized(id)

-- end