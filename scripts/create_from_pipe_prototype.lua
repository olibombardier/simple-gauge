local utility = require("__simple-gauge__.scripts.utils")

---Adds a simple gauge created from a pipe prototype
---@param pipe_name data.EntityID
---@param technology_name data.TechnologyID?
---@param item_name data.ItemID?
---@param recipe_name data.RecipeID?
local function create_from_pipe_prototype(pipe_name, technology_name, item_name, recipe_name)
	local pipe_prototype = data.raw["pipe"][pipe_name]

	item_name = item_name or pipe_prototype.name
	recipe_name = recipe_name or pipe_prototype.name
	technology_name = technology_name or "fluid-handling"


	local gauge = table.deepcopy(pipe_prototype)
	local item = table.deepcopy(data.raw["item"][item_name])
	local recipe = table.deepcopy(data.raw["recipe"][recipe_name])

	local new_name = "simple-gauge"
	if pipe_prototype.name ~= "pipe" then new_name = "simple-gauge-" .. pipe_prototype.name end

	local localised_name = { "item-name.simple-gauge", utility.get_item_localised_name(item_name) }

	local gauge_icon = {
		icon = "__simple-gauge__/graphics/icons/gauge.png",
		scale = 0.25,
		shift = { -10, -10 },
		draw_background = true,
	}
	---@type data.IconData[]
	local icons
	if pipe_prototype.icons then
		icons = table.deepcopy(pipe_prototype.icons)
		table.insert(icons, gauge_icon)
	else
		icons = {
			{
				icon = pipe_prototype.icon,
				icon_size = pipe_prototype.icon_size or 64,
			},
			gauge_icon
		}
	end

	item.name = new_name
	item.localised_name = localised_name
	item.place_result = new_name
	item.icon = nil
	item.icons = icons

	recipe.name = new_name
	recipe.localised_name = localised_name
	recipe.results = { { type = "item", name = new_name, amount = 1 } }

	local tech = data.raw["technology"][technology_name]
	table.insert(tech.effects, { type = "unlock-recipe", recipe = new_name })

	--Prevent warnings
	gauge.icon = nil
	gauge.horizontal_window_bounding_box = nil
	gauge.vertical_window_bounding_box = nil

	---@cast gauge data.StorageTankPrototype
	gauge.type = "storage-tank"
	gauge.name = new_name
	gauge.localised_name = localised_name
	gauge.order = "zz[gauge]-" .. (gauge.order or new_name)
	gauge.icons = icons
	gauge.minable = gauge.minable or { mining_time = 0.5 }
	gauge.minable.results = nil
	gauge.minable.result = gauge.name
	gauge.fluid_box = {
		volume = pipe_prototype.fluid_box.volume,
		max_pipeline_extent = pipe_prototype.fluid_box.max_pipeline_extent,
		pipe_connections = {
			{
				direction = defines.direction.north,
				position = { 0, 0 },
				connection_category = pipe_prototype.fluid_box.pipe_connections[1].connection_category or "default",
			},
			{
				direction = defines.direction.south,
				position = { 0, 0 },
				connection_category = pipe_prototype.fluid_box.pipe_connections[1].connection_category or "default",
			}
		},
		pipe_covers = pipecoverspictures(),
		hide_connection_info = true,
	}
	gauge.two_direction_only = true
	gauge.window_bounding_box = { { -0.4, -0.4 }, { 0.4, 0.4 } }
	gauge.flow_length_in_ticks = 60
	gauge.circuit_wire_max_distance = 9
	gauge.circuit_connector = circuit_connector_definitions.create_vector(
		universal_connector_template,
		{
			{ variation = 0, main_offset = util.by_pixel(5, -12), shadow_offset = util.by_pixel(0, 2), show_shadow = false },
			{ variation = 2, main_offset = util.by_pixel(0, -10), shadow_offset = { 0, 0 },            show_shadow = false },
			{ variation = 0, main_offset = util.by_pixel(5, -12), shadow_offset = util.by_pixel(0, 2), show_shadow = false },
			{ variation = 2, main_offset = util.by_pixel(0, -10), shadow_offset = { 0, 0 },            show_shadow = false },
		}
	)
	local vertical_pipe = {
		layers = {
			pipe_prototype.pictures.straight_vertical,
			gauge.circuit_connector[1].sprites.connector_main,
			gauge.circuit_connector[1].sprites.wire_pins,
			gauge.circuit_connector[1].sprites.led_blue_off,
		},
	}

	local horizontal_pipe = {
		layers = {
			pipe_prototype.pictures.straight_horizontal,
			gauge.circuit_connector[2].sprites.connector_main,
			gauge.circuit_connector[2].sprites.wire_pins,
			gauge.circuit_connector[2].sprites.led_blue_off,
		},
	}

	gauge.pictures = {
		picture = {
			north = vertical_pipe,
			east = horizontal_pipe,
			south = vertical_pipe,
			west = horizontal_pipe,
		}
	}

	data:extend({ gauge, item, recipe })
end

return create_from_pipe_prototype
