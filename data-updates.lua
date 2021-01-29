dutil = require('data-util')


data:extend{{
	type = "item-subgroup",
	name = "dupe-subgroup",
	group = "combat",
	order = " ",
}}

dutil.clone{
	type = "inserter",
	src = "stack-inserter",
	name = "dupe-inserter",
	subgroup = "dupe-subgroup",

	energy_source = {type = "void"},
	stack = true,
	filter_count = 0,
	extension_speed = 10,
	rotation_speed = 5,
	allow_custom_vectors = true,
}
dutil.clone{
	type = "inserter",
	src = "filter-inserter",
	name = "dupe-filter-inserter",
	subgroup = "dupe-subgroup",

	-- map_color = dutil.constants.infinity_tint,
	-- friendly_map_color = dutil.constants.infinity_tint,
	energy_source = {type = "void"},
	stack = true,
	filter_count = 1,
	extension_speed = 1,
	rotation_speed = 0.5,
	tint = {r=0.4,g=1,b=0,a=1},
}

dutil.clone{
	type = "tile",
	src = "lab-dark-1",
	item = {src = "concrete"},
	name = "dupe-floor",
	subgroup = "dupe-subgroup",

	entity = {force_override = {tint = dutil.constants.infinity_tint}},

	decorative_removal_probability = 1,
}

dutil.clone{
	type = "transport-belt",
	src = "transport-belt",
	name = "dupe-belt",
	subgroup = "dupe-subgroup",

	speed = 0.25,
}

dutil.clone{
	type = "linked-belt",
	src = "linked-belt",
	name = "dupe-linked-belt",
	subgroup = "dupe-subgroup",

	speed = 0.25,
	max_health = 10,
}

dutil.clone{
	type = "linked-container",
	src = "linked-chest",
	name = "dupe-chest",
	subgroup = "dupe-subgroup",

	inventory_size = 1,
}


-- dutil.clone{
-- 	type = "wall",
-- 	src = "stone-wall",
-- 	name = "dupe-wall",
-- 	subgroup = "dupe-subgroup",
-- 	tint = {r=0.65,g=0.35,b=0,a=1},
-- 	item_tint = {r=0.5,g=0.5,b=0,a=1},
-- 	max_health = 10,
-- }
-- dutil.clone{
-- 	type = "wall",
-- 	src = "stone-wall",
-- 	name = "dupe-wall-valid",
-- 	subgroup = "dupe-subgroup",
-- 	tint = {r=0.7,g=0.7,b=0,a=1},
-- }
dutil.clone{
	type = "gate",
	src = "gate",
	name = "dupe-wall-valid",
	subgroup = "dupe-subgroup",
	tint = {r=0.2,g=1.0,b=0,a=1},
	max_health = 10,
	placeable_by = {item="dupe-wall", count=1},
	minable = {mining_time=0.1, result="dupe-wall"},
	item = {disabled = true}
}
dutil.clone{
	type = "gate",
	src = "gate",
	name = "dupe-wall",
	subgroup = "dupe-subgroup",
	tint = {r=0.7,g=0.7,b=0,a=1},
	max_health = 10,
	placeable_by = {item="dupe-wall", count=1},
	minable = {mining_time=0.1, result="dupe-wall"},
}
dutil.clone{
	type = "wall",
	src = "stone-wall",
	name = "dupe-wall-angle",
	subgroup = "dupe-subgroup",
	tint = {r=0.4,g=0.6,b=0,a=1},
	max_health = 10,
	placeable_by = {item="dupe-wall", count=1},
	minable = {mining_time=0.1, result="dupe-wall"},
	item = {disabled = true}
}
dutil.clone{
	type = "wall",
	src = "stone-wall",
	name = "dupe-wall-angle-green",
	subgroup = "dupe-subgroup",
	tint = {r=0.2,g=1.0,b=0,a=1},
	max_health = 10,
	placeable_by = {item="dupe-wall", count=1},
	minable = {mining_time=0.1, result="dupe-wall"},
	item = {disabled = true}
}

dutil.clone.capsule{
	src = "slowdown-capsule",
	name = "dupe-teleport-capsule",
	subgroup = "dupe-subgroup",
	-- tint = {r=0.5,g=0.5,b=1},
}

dutil.clone{
	type = "decider-combinator",
	src = "decider-combinator",
	name = "dupe-decider-combinator",
	subgroup = "dupe-subgroup",
	energy_source = {type = "void"},
}
dutil.clone{
	type = "arithmetic-combinator",
	src = "arithmetic-combinator",
	name = "dupe-arithmetic-combinator",
	subgroup = "dupe-subgroup",
	energy_source = {type = "void"},
}

dutil.clone{
	type = "loader",
	src = "loader",
	name = "dupe-loader",
	subgroup = "dupe-subgroup",
	speed = 0.25,
}

dutil.clone{
	type = "splitter",
	src = "splitter",
	name = "dupe-splitter",
	subgroup = "dupe-subgroup",
	speed = 0.25,
}

dutil.clone{
	type = "loader",
	src = "loader",
	name = "dupe-loader",
	subgroup = "dupe-subgroup",
	speed = 0.25,
}

dutil.clone{
	type = "infinity-container",
	src = "infinity-chest",
	name = "dupe-infinity-chest",
	subgroup = "dupe-subgroup",

	inventory_size = 4,
}


dutil.clone{
	type = "train-stop",
	src = "train-stop",
	name = "dupe-train-stop",
	subgroup = "dupe-subgroup",
	-- placeable_by = {item = "dupe-train-stop", count = 0},
	-- minable = {mining_time=0.1, result="dupe-train-stop", count = 0}
}

dutil.clone{
	type = "programmable-speaker",
	src = "programmable-speaker",
	name = "dupe-screamer",
	subgroup = "dupe-subgroup",

	energy_source = {type = "void"},
}

dutil.clone{
	type = "radar",
	src = "radar",
	name = "dupe-radar",
	subgroup = "dupe-subgroup",

	energy_source = {type = "void"},
	max_distance_of_nearby_sector_revealed = 4,
	max_distance_of_sector_revealed = 4,
}

data:extend{
-- 	{
-- 	type = "recipe",
-- 	enabled = true,
-- 	energy_required = 0.5,
-- 	ingredients = {},
-- 	name = "dupe-teleport-capsule",
-- 	result = "dupe-teleport-capsule",
-- }, 
{
	type = "recipe",
	enabled = true,
	energy_required = 0.5,
	ingredients = {},
	name = "dupe-wall",
	result = "dupe-wall",
}, {
	type = "recipe",
	enabled = true,
	energy_required = 0.5,
	ingredients = {},
	name = "dupe-linked-belt",
	result = "dupe-linked-belt",
}, {
	type = "recipe",
	enabled = true,
	energy_required = 0.5,
	ingredients = {},
	name = "dupe-train-stop",
	result = "dupe-train-stop",
}, {
	type = "recipe",
	enabled = true,
	energy_required = 0.5,
	ingredients = {},
	name = "dupe-planner",
	result = "dupe-planner",
},
-- {
-- 	type = "recipe",
-- 	enabled = true,
-- 	energy_required = 0.5,
-- 	ingredients = {{"dupe-wall", 1}},
-- 	name = "dupe-gate-box-request",
-- 	result = "dupe-gate-box-request",
-- }
}


data:extend{{
	type = "selection-tool",
	name = "dupe-planner",

	selection_color = dutil.constants.infinity_tint,
	selection_cursor_box_type = "copy",
	selection_mode = {"any-tile"},

	alt_selection_color = {b=0, g=1, r=0},
	alt_selection_cursor_box_type = "copy",
	alt_selection_mode = {"any-tile"},

	always_include_tiles = true,
	flags = {}, --{"hidden", "only-in-cursor"},
	icons = {{
		icon = "__base__/graphics/icons/blueprint.png",
		icon_mipmaps = 4,
		icon_size = 64,
		tint = {r=1,g=1,b=0.2,a=1},
	}},
	order = "c[selection-tool]-a[tape-measure]",
	stack_size = 1,
	subgroup = "dupe-subgroup",
}}

data:extend{{
	type = "blueprint",
	name = "dupe-blueprint",

	alt_selection_color = {0.3,0.8,1},
	alt_selection_count_button_color = {0.3,0.8,1},
	alt_selection_cursor_box_type = "copy",
	alt_selection_mode = { "blueprint" },
	close_sound = { filename = "__base__/sound/item-close.ogg", volume = 1 },
	draw_label_for_cursor_render = true,
	flags = {}, --{ "hidden", "only-in-cursor" },
	icons = {{
		icon = "__base__/graphics/icons/blueprint.png",
		icon_mipmaps = 4,
		icon_size = 64,
		tint = {r=1,g=1,b=0.5,a=1},
	}},
	open_sound = { filename = "__base__/sound/item-open.ogg", volume = 1 },
	order = "c[automated-construction]-a[blueprint]-no-picker",
	selection_color = {57,156,251},
	selection_count_button_color = {43,113,180},
	selection_cursor_box_type = "copy",
	selection_mode = {"blueprint"},
	stack_size = 1,
	subgroup = "dupe-subgroup",
}}


data:extend{{
	["flags"] = {
		"not-on-map",
		"placeable-off-grid"
	},
	["name"] = "dupe-flying-text-center",
	["speed"] = 0,
	["time_to_live"] = 0,
	["type"] = "flying-text",
	text_alignement = "center",
},{
	["flags"] = {
		"not-on-map",
		"placeable-off-grid"
	},
	["name"] = "dupe-flying-text",
	["speed"] = 0,
	["time_to_live"] = 0,
	["type"] = "flying-text"
}}




-- local straight_rail = table.deepcopy(data.raw["straight-rail"]["straight-rail"])
-- straight_rail.icons = dutil.recursive_tint(dutil.extract_icon_info(straight_rail), nil)
-- dutil.recursive_tint(straight_rail)
-- straight_rail.name = "dupe-"..straight_rail.name
-- straight_rail.minable.result = "dupe-rail"
-- local curved_rail = table.deepcopy(data.raw["curved-rail"]["curved-rail"])
-- curved_rail.icons = dutil.recursive_tint(dutil.extract_icon_info(curved_rail), nil)
-- dutil.recursive_tint(curved_rail)
-- curved_rail.name = "dupe-"..curved_rail.name
-- curved_rail.minable.result = "dupe-rail"

-- data:extend{
-- {
-- 	["curved_rail"] = "dupe-curved-rail",
-- 	icons = {{
-- 		["icon"] = "__base__/graphics/icons/rail.png",
-- 		["icon_mipmaps"] = 4,
-- 		["icon_size"] = 64,
-- 		tint = dutil.constants.infinity_tint,
-- 	}},
-- 	["localised_name"] = {
-- 		"item-name.dupe-rail"
-- 	},
-- 	["name"] = "dupe-rail",
-- 	["order"] = "a[train-system]-a[rail]",
-- 	["place_result"] = "dupe-straight-rail",
-- 	["stack_size"] = 100,
-- 	["straight_rail"] = "dupe-straight-rail",
-- 	["subgroup"] = "dupe-subgroup",
-- 	["type"] = "rail-planner"
-- },
-- straight_rail,
-- curved_rail,
-- }



-- selection_mode (forced to be "blueprint")
-- alt_selection_mode (forced to be "blueprint")
-- always_include_tiles (forced to be false)
-- entity_filters
-- entity_type_filters
-- tile_filters
-- entity_filter_mode
-- tile_filter_mode
-- alt_entity_filters
-- alt_entity_type_filters
-- alt_tile_filters
-- alt_entity_filter_mode
-- alt_tile_filter_mode

-- local ins = dutil.copy(data.raw.inserter["filter-inserter"], 
-- 	{
-- 		["energy_source"] = {
-- 			["type"] = "void",
-- 			["drain"] = "undefined",
-- 			["usage_priority"] = "undefined"
-- 		},
-- 		["extension_speed"] = 1,
-- 		["icons"] = {
-- 			{
-- 				["icon"] = "__base__/graphics/icons/filter-inserter.png",
-- 				["icon_mipmaps"] = 4,
-- 				["icon_size"] = 64,
-- 				["tint"] = {
-- 					["a"] = 1,
-- 					["b"] = 1,
-- 					["g"] = 0.5,
-- 					["r"] = 1
-- 				}
-- 			}
-- 		},
-- 		["minable"] = {
-- 			["result"] = "dupe-inserter"
-- 		},
-- 		["name"] = "dupe-inserter",
-- 		["placeable_by"] = {
-- 			["count"] = 1,
-- 			["item"] = "dupe-inserter"
-- 		},
-- 		["rotation_speed"] = 0.5,
-- 		["stack"] = true,
-- 		["icon"] = "undefined",
-- 		["icon_mipmaps"] = "undefined",
-- 		["icon_size"] = "undefined",
-- 		["filter_count"] = 1
-- 	}
-- )

-- data:extend{ins}


