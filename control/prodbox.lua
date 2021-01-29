require('control/duper')

Prodbox = {}
Prodbox.meta = {}
setmetatable(Prodbox, Prodbox.meta)
Prodbox.prototype = {__class = "Prodbox"}
Prodbox.metaprototype = {__index = Prodbox.prototype}


function Prodbox.of(o)
	setmetatable(o, Prodbox.metaprototype)
	o.__class = o.__class
	if not o.player_data then o.player_data = {} end
	if not o.force then o.force = o:get_dupebox().force end
	return o
end

function Prodbox.create_empty(dupebox)
	local prodbox = Prodbox.of{
		backer_name = dupebox.backer_name,
		tiles_filled = false,
		activated = false,

		surface = nil,
		force = dupebox.force,
		position = nil,
		area = nil,
		size = dupebox.size,
		multiplier = 0,
	}
	local dupeface = Prodbox.create_dupeface()
	prodbox.surface = "dupe-surface"
	local rightmost_prodbox = 10000
	for k,dupebox in pairs(DupeController.get().dupeboxes) do
		if dupebox.prodbox and dupebox.prodbox.position then
			if dupebox.prodbox.position[1] > rightmost_prodbox then
				rightmost_prodbox = dupebox.prodbox.position[1] + dupebox.prodbox.size[1]
			end
		end
	end
	rightmost_prodbox = rightmost_prodbox + 256 + rightmost_prodbox % 2
	prodbox.position = Pos{rightmost_prodbox, 0}:add{1,1}
	-- Build{surface=dupeface, position=prodbox.position, "dupe-train-stop"}
	local subbox = dupebox.subboxes[1]
	prodbox.area = subbox.area:move(subbox.position:mul(-1)):move(prodbox.position)

	dupeface.request_to_generate_chunks(prodbox.area:center(),
										math.max(prodbox.size[1], prodbox.size[2]) / 64 + 2)
	dupeface.force_generate_chunk_requests()
	game.forces[dupebox.force].chart_all(dupeface)

	DupeController.serialize(prodbox)
	return prodbox
end

function Prodbox.create_dupeface()
	if not Prodbox._fix_surface_settings then
		Prodbox._fix_surface_settings = true
		if game.surfaces["dupe-surface"] then
			game.surfaces["dupe-surface"].map_gen_settings = {
				default_enable_all_autoplace_controls = false,
				cliff_settings = {richness = 0},
			}
		end
	end
	if game.surfaces["dupe-surface"] then return game.surfaces["dupe-surface"] end
	game.create_surface("dupe-surface", {
		-- height = 1, width = 1
		default_enable_all_autoplace_controls = false,
		cliff_settings = {richness = 0},
	})
	return game.surfaces["dupe-surface"]
end


function Prodbox.get_from_train_stop(stop)
	local pos = Pos(stop.position)
	local surface = stop.surface.name
	for k,v in pairs(DupeController.get().dupeboxes) do
		v = v.prodbox
		if pos:equals(v.position) and surface == v.surface then
			return v
		end
	end
	return nil
end




function Prodbox.prototype:get_dupebox()
	return Dupebox.get(self.backer_name)
end

function Prodbox.prototype:process_dupebox_activation(data)
	self:fill_tiles()


	self.activated = true
	self.multiplier = 0
	for i,subbox in ipairs(self:get_dupebox().subboxes) do
		if subbox:can_activate() then
			self.multiplier = self.multiplier + 1
			subbox:process_activation(data)
		end
	end

	self:teleport_buildings_inside()


	if data.player then
		self:teleport_player_inside(data)
	end

end


function Prodbox.prototype:teleport_buildings_inside()
	for i,subbox in ipairs(self:get_dupebox().subboxes) do
		local bp = subbox:make_blueprint(0)
		local ghosts = bp.build{surface = self.surface, position = self.area:center()}
		local revived = {["dupe-train-stop"]=true,["dupe-wall"]=true,["dupe-wall-angle"]=true}
		for i,ghost in ipairs(ghosts) do
			if revived[ghost.ghost_name] then
				local collides, entity, item_request_proxy = ghost.revive{return_item_request_proxy=true}
				entity.minable = false
				entity.destructible = false
			end
		end
	end

	self:sync_ghosts_inside()
end


-- function Prodbox.prototype:revive_entity(ghost)
-- 	local offset = Pos(ghost.position):sub(self.position)
-- 	local prototype = ghost.ghost_prototype
-- 	local items_to_place_this = prototype.items_to_place_this
-- 	local proxy = ghost.revive{return_item_request_proxy=true}
-- 	local subboxes = Array.from(self:get_dupebox().subboxes)
-- 		:filter(function(sub) return sub.activated end)
-- 	for i,sub in ipairs(subboxes) do
-- 		local found = Build.fef{surface=sub.surface, pos=sub.position:add(offset)}[1]
-- 		Build.mine_and_spill(found, {}, {force=sub.force}, items_to_place_this)
-- 	end
-- end

function Prodbox.prototype:revive_ghost_from_built(id, entity_data, datas)
	local ghost = entity_data.entity
	local prototype = ghost.ghost_prototype
	local items_to_place_this = prototype.items_to_place_this
	local proxy = ghost.revive{return_item_request_proxy=true}
	for k,data in pairs(datas) do
		local found = data[id].entity
		Build.mine_and_spill(found, {}, {force=self.force}, items_to_place_this)
	end
end

function Prodbox.inventory_copied_item_list()
	local copied_items = {"blueprint", "blueprint-book", "deconstruction-item", "item-with-entity-data", "item-with-inventory", "selection-tool"}
	for i,v in ipairs(copied_items) do copied_items[v] = true end
	return copied_items
end



function Prodbox.prototype:sync_ghosts_inside()
	local pdata, datas = self:get_all_entities_data()
	for id,entity_data in pairs(pdata) do
		local status = {built=0, ghost=0, none=0}
		entity_data.status = status
		for k,v in pairs(datas) do
			local subdata = v[id]
			if subdata then
				if subdata.built then status.built = status.built+1
				else status.ghost = status.ghost+1 end
			else status.none = status.none+1 end
		end
		if not entity_data.built and status.none > 0 then
			Game.dline("Some entities ("..entity_data.id..") are missing in some subboxes, TODO")
		end
		if entity_data.built == false and status.none == 0 and status.ghost == 0 then
			local found = Build.fef{surface=self.surface, pos=entity_data.pos}
			-- TODO smth with proxy
			-- self:revive_entity(found[1])
			self:revive_ghost_from_built(id, entity_data, datas)
		elseif not entity_data.built then
			Build.reset(entity_data.entity)
			Build{"dupe-flying-text-center", direction=0, data={text=entity_data.status.built.."/"..#datas:keys()}}
		end
	end
end

function Prodbox.prototype:sync_ghosts_outside()
	local pdata, datas = self:get_all_entities_data()
	for id,entity_data in pairs(pdata) do
		local status = {built=0, ghost=0, none=0}
		entity_data.status = status
		for sub,v in pairs(datas) do
			local subdata = v[id]
			if subdata then
				if subdata.built then status.built = status.built+1
				else status.ghost = status.ghost+1 end
			else
				status.none = status.none+1
				if not entity_data.built then
					Build.reset(entity_data.entity)
					Build{"ghost", entity_data.name, surface=sub.surface,
							pos=entity_data.offset:add(sub.position)}
				end
			end
		end
		if not entity_data.built and status.none > 0 then
			Game.dline("Some entities ("..entity_data.id..") are missing in some subboxes, TODO")
		end
	end

end

function Prodbox.prototype:get_all_entities_data()
	local ignored = {["dupe-wall"]=true,["dupe-wall-angle"]=true,["dupe-train-stop"]=true,}--["dupe-linked-belt"]=true}
	local function box_entities_data(sub)
		local found = Array.of(Build.fef{surface=sub.surface, area=sub.area})
			:filter(function(v) return v.name end)
		local data = found:mapNotNil(function(v)
			local built = v.name ~= "entity-ghost"
			local prototype = built and v.prototype or v.ghost_prototype
			if not prototype.items_to_place_this then return nil end
			local name = built and v.name or v.ghost_name
			if ignored[name] then return nil end
			local offset = Pos(v.position):sub(sub.position)
			local id = sub:entity_id(v)
			return {id=id, offset=offset, name=name, built=built, pos=Pos(v.position), entity=v}
		end)
		return {sub, Object.fromEntries(data:map(function(v)return{v.id, v} end))}
	end

	local subboxes = Array.from(self:get_dupebox().subboxes)
		:filter(function(sub) return sub.activated end)

	local datas = Object.fromEntries(subboxes:map(box_entities_data))
	local pdata = box_entities_data(self)[2]
	return pdata, datas
end




function Prodbox.prototype:teleport_player_inside(data)
	self:sync_ghosts_inside()
	self:sync_linked_belts()

	local player = data.player
	local dupeface = game.surfaces["dupe-surface"]
	local pdata = self.player_data[data.player.name] or {}
	self.player_data[data.player.name] = pdata

	-- if not data.subbox then data.subbox = subbox.get_from_train_stop(player.opened) end

	pdata.tp_from = data.subbox
	if not pdata.tp_from then Game.dline("teleporting from nowhere, why?") error() end

	local old_character = player.character
	player.teleport(pdata.tp_from.position:add{1,0}, pdata.tp_from.surface)
	player.character = nil
	player.associate_character(old_character)
	player.teleport(self.position:add{1,0}, dupeface)
	player.create_character()

	player.character.character_crafting_speed_modifier =
		(old_character.character_crafting_speed_modifier + 1) / self.multiplier - 1
	player.character.character_mining_speed_modifier =
		(old_character.character_mining_speed_modifier + 1) / self.multiplier - 1

	local old_inventory = old_character.get_main_inventory()
	local inventory = player.character.get_main_inventory()
	player.character.character_inventory_slots_bonus = #old_inventory - #inventory
	inventory = player.character.get_main_inventory()

	Game.always(#old_inventory == #inventory)

	for i=1,#old_inventory do
		inventory.set_filter(i, old_inventory.get_filter(i))
	end
	local old_items = {}
	local items = {}
	local copied_items = Prodbox.inventory_copied_item_list()
	for i=1,#old_inventory do
		local old_stack = old_inventory[i]
		local stack = inventory[i]
		if old_stack.count > 0 then
			if copied_items[old_stack.type] then
				stack.set_stack(old_stack)
			elseif not old_stack.item_number then
				old_items[old_stack.name] = (old_items[old_stack.name] or 0) + old_stack.count
			end
		end
	end

	for name,count in pairs(old_items) do
		if count > self.multiplier then
			items[name] = math.floor(count / self.multiplier)
			inventory.insert{name=name, count=items[name]}
		end
	end

	pdata.tp_items = items


	-- Build{"dupe-teleport-capsule-explosion", position=player.position, surface=player.surface, force=player.force}

end


function Prodbox.prototype:teleport_player_outside(data)
	self:sync_ghosts_outside()

	local player = data.player
	local dupeface = game.surfaces["dupe-surface"]
	local pdata = self.player_data[data.player.name] or {}

	local chars = player.get_associated_characters()
	local old_character = player.character
	player.character = nil
	-- Game.dline(pdata.tp_from.position)
	player.teleport(pdata.tp_from.position:add{1,0}, pdata.tp_from.surface)
	player.character = chars[1]
	player.teleport(pdata.tp_from.position:add{1,0}, pdata.tp_from.surface)

	local inventory = player.character.get_main_inventory()
	local old_inventory = old_character.get_main_inventory()
	local old_items = {}
	local copied_items = Prodbox.inventory_copied_item_list()
	for i=1,#old_inventory do
		local old_stack = old_inventory[i]
		if old_stack.count > 0 and not copied_items[old_stack.type] then
			old_items[old_stack.name] = (old_items[old_stack.name] or 0) + old_stack.count
		end
	end
	for name,count in pairs(pdata.tp_items) do
		if count > (old_items[name] or 0) then
			inventory.remove{name=name, count=(count-(old_items[name] or 0))*self.multiplier}
		end
	end
	for name,count in pairs(old_items) do
		if count > (pdata.tp_items[name] or 0) then
			inventory.insert{name=name, count=(count-(pdata.tp_items[name] or 0))*self.multiplier}
		end
	end
	old_character.destroy()

	local found = Build.fef{surface=self.surface, name="dupe-flying-text-center"}
	for i,v in ipairs(found) do v.destroy() end


	-- Build{"dupe-teleport-capsule-explosion", position=player.position, surface=player.surface, force=player.force}

end





function Prodbox.prototype:fill_tiles()
	local dupeface = game.surfaces["dupe-surface"]
	local box = self.area:grow(-0.5)
	local pos = box[1]
	local tiles = {}
	for i=0,box:width() do
		for j=0,box:height() do
			if (i+j)%2==0 then
				tiles[#tiles+1] = {name="dupe-floor",position=box[1]:add{i, j}}
			else
				tiles[#tiles+1] = {name="lab-dark-2",position=box[1]:add{i, j}}
			end
		end
	end
	dupeface.set_tiles(tiles)

	tiles = {}
	for i=2,5 do
		for j=-1,3 do
			local name = "water"
			tiles[#tiles+1] = {name=name, position=box[1]:add{-i,j}}
			tiles[#tiles+1] = {name=name, position=box:left_bottom():add{-i,-j}}
			tiles[#tiles+1] = {name=name, position=box:right_top():add{i,j}}
			tiles[#tiles+1] = {name=name, position=box[2]:add{i,-j}}
		end
	end
	dupeface.set_tiles(tiles)

	tiles = {}
	for i=1,2 do
		for j=1,1 do
			local name = i == 1 and "lab-dark-2" or "black-refined-concrete"
			tiles[#tiles+1] = {name=name, position=box[1]:add{-i,j}}
			tiles[#tiles+1] = {name=name, position=box:left_bottom():add{-i,-j}}
			tiles[#tiles+1] = {name=name, position=box:right_top():add{i,j}}
			tiles[#tiles+1] = {name=name, position=box[2]:add{i,-j}}
		end
	end
	dupeface.set_tiles(tiles)
end

function Prodbox.prototype:entity_id(entity)
	local name = entity.name == "entity-ghost" and entity.ghost_name or entity.name
	local pos = Pos(entity.position or entity.pos)
	local offset = pos and pos:sub(self.position) or entity.offset
	return name.."@("..offset[1]..","..offset[2]..")"
end


function Prodbox.prototype:sync_linked_belts()

	for id,link in pairs(self:get_dupebox().linked_belts) do
		if not link.active then
			Duper.activate_link{prodbox=self, dupebox=self:get_dupebox(), link=link}
		end
	end

end

function Prodbox.prototype:get_active_subboxes()
	local subboxes = Array.from(self:get_dupebox().subboxes)
		:filter(function(sub) return sub.activated end)
		return subboxes
end