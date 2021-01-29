
local dutil = {} -- require('__flib__.data-util')





-- recursive tinting - tint all sprite definitions in the given table
local function is_sprite_def(array)
  return array.width and array.height and (array.filename or array.stripes or array.filenames)
end
function dutil.recursive_tint(array, tint)
  if tint ~= false then
    tint = tint or dutil.constants.infinity_tint
  end
  for _, v in pairs(array) do
    if type(v) == "table" then
      if is_sprite_def(v) or v.icon then
        if tint == false then
          v.tint = nil
        else
          v.tint = tint
        end
      end
      v = dutil.recursive_tint(v, tint)
    end
  end
  return array
end

-- consolidate icon information into a table to use in "icons"
function dutil.extract_icon_info(obj, skip_cleanup)
  local icons = obj.icons or {{icon = obj.icon, icon_size = obj.icon_size, icon_mipmaps = obj.icon_mipmaps}}
  icons[1].icon_size = icons[1].icon_size or obj.icon_size
  if not skip_cleanup then
    obj.icon = nil
    obj.icon_size = nil
    obj.icon_mipmaps = nil
  end
  return icons
end

-- generate the localised description of a chest
function dutil.chest_description(suffix, is_aggregate)
  if is_aggregate then
    return {
      "",
      {"entity-description.ee-aggregate-chest"},
      suffix ~= "" and {"", "\n", {"entity-description.logistic-chest"..suffix}} or "",
      "\n[color=255,57,48]", {"entity-description.ee-performance-warning"}, "[/color]"
    }
  else
    return {
      "",
      {"entity-description.ee-infinity-chest"},
      suffix ~= "" and {"", "\n", {"entity-description.logistic-chest"..suffix}} or ""
    }
  end
end

dutil["copy"] = require('util').table.deepcopy
function dutil.deepassign(to, from) 
	for k,v in pairs(from) do
		if type(v) ~= 'table' then
			if v == "undefined" then to[k] = nil else to[k] = v end
		else
			if type(to[k]) == 'table' then deepassign(to[k], v) else to[k] = v end
		end
	end
end



dutil.constants = {infinity_tint={r=1,g=1,b=0,a=1},tint={r=1,g=1,b=0,a=1}}











dutil.clone = {}
dutil.clone.meta = {}

function dutil.clone.meta.__call(self, o)
	function get(k, v) return o[k] and o[k][v] or o[v] end
	local src = {
		item = data.raw[o.item and o.item.type or "item"][get("item", "src")],
		entity = data.raw[o.type][get("entity", "src")],
	}
	if not src.item then error("not src.item: "..serpent.block(o)) end
	if not src.entity then error("not src.entity: "..serpent.block(o)) end


	-- copy: item, entity
	local item = table.deepcopy(src.item)
	local entity = table.deepcopy(src.entity)

	item.name = get("item", "name")
	entity.name = get("entity", "name")

	-- do tint:
	item.icons = dutil.recursive_tint(dutil.extract_icon_info(item), get("item", "tint"))
	if o.type ~= "tile" then
		entity.icons = dutil.recursive_tint(dutil.extract_icon_info(entity), get("entity", "tint"))
	end
	dutil.recursive_tint(item, get("item", "tint"))
	dutil.recursive_tint(entity, get("entity", "tint"))

	-- copy names where they belong:
	item.subgroup = o.subgroup or item.subgroup
	item.order = o.order or item.order
	if item.place_result then item.place_result = o.name end
	if item.place_as_tile then item.place_as_tile.result = o.name end

	entity.placeable_by = {item = o.name, count = 1}
	if not entity.minable then entity.minable = {mining_time=0.1, result=o.name} end
	entity.minable.result = o.name

	-- copy extra data
	local ignore = { type = true, name = true, tint = true, force_override = true }
	local base_ignore = { item = true, entity = true }

	for k,v in pairs(o) do
		if not ignore[k] and not base_ignore[k] then
			entity[k] = v
		end
	end
	if o.entity then
		for k,v in pairs(o.entity) do
			if not ignore[k] then
				entity[k] = v
			end
		end
		for k,v in pairs(o.entity.force_override or {}) do
			entity[k] = v
		end
	end
	if o.item then
		for k,v in pairs(o.item.force_override or {}) do
			item[k] = v
		end
	end

	if get("item", "disabled") then return data:extend{entity} end
	data:extend{ item, entity }
end

setmetatable(dutil.clone, dutil.clone.meta)

dutil.clone.capsule = function(o)
	function get(k, v) return o[k] and o[k][v] or o[v] end
	local src = {
		capsule = data.raw.capsule[get("capsule", "src")],
		projectile = data.raw.projectile[get("projectile", "src")],
		explosion = data.raw.explosion[get("explosion", "src") .. "-explosion"] or data.raw.explosion[get("explosion", "src")],
	}

	-- copy: capsule, projectile, explosion
	local capsule = table.deepcopy(src.capsule)
	local projectile = table.deepcopy(src.projectile)
	local explosion = table.deepcopy(src.explosion)
	-- there's also "particle" but I dont wanna do it

	capsule.name = get("capsule", "name")
	projectile.name = get("projectile", "name")
	explosion.name = o.explosion and o.explosion.name or (o.name .. "-explosion")

	-- do tint:
	capsule.icons = dutil.recursive_tint(dutil.extract_icon_info(capsule), get("capsule", "tint"))
	if projectile.icons then
		projectile.icons = dutil.recursive_tint(dutil.extract_icon_info(projectile), get("projectile", "tint"))
	end
	explosion.icons = dutil.recursive_tint(dutil.extract_icon_info(explosion), get("explosion", "tint"))
	dutil.recursive_tint(capsule, get("capsule", "tint"))
	dutil.recursive_tint(projectile, get("projectile", "tint"))
	dutil.recursive_tint(explosion, get("explosion", "tint"))

	-- copy names where they belong:
	if capsule.ammo_type and capsule.ammo_type.action then
		for i,v in ipairs(capsule.ammo_type.action) do
			if v.action_delivery and v.action_delivery.type == "projectile" and v.action_delivery.name == src.projectile.name then
				v.action_delivery.name = projectile.name
			end 
		end
	end

	if projectile.action then
		for i,v in ipairs(projectile.action) do
			if v.action_delivery and v.action_delivery.target_effects and v.action_delivery.target_effects.entity_name == src.explosion.name then
				v.action_delivery.target_effects.entity_name = explosion.name
			end
		end
	end

	-- copy extra data
	local ignore = { type = true, name = true, tint = true }
	local base_ignore = { item = true, name = true, tint = true }

	for k,v in pairs(o) do
		if not ignore[k] and not base_ignore[k] then
			capsule[k] = v
		end
	end
	if o.capsule then
		for k,v in pairs(o.capsule) do
			if not ignore[k] then
				capsule[k] = v
			end
		end
	end
	if o.projectile then
		for k,v in pairs(o.projectile) do
			if not ignore[k] then
				projectile[k] = v
			end
		end
	end
	if o.explosion then
		for k,v in pairs(o.explosion) do
			if not ignore[k] then
				explosion[k] = v
			end
		end
	end

	data:extend{ capsule, projectile, explosion }

	-- log(
	-- 	"\n\n\n capsule:\n"..serpent.block(capsule)..
	-- 	"\n\n\n projectile:\n"..serpent.block(projectile)..
	-- 	"\n\n\n explosion:\n"..serpent.block(explosion)..
	-- 	"\n\n\n"
	-- )
	-- log(
	-- 	"\n\n\n src-projectile:\n"..serpent.block(src.projectile)..
	-- 	"\n\n\n"
	-- )
end


return dutil