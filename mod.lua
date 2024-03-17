if not FloatingHealthbars then

	dofile(ModPath .. "req/EnemyHealthBar.lua")

	FloatingHealthbars = {
		mod_path = ModPath,
		save_path = SavePath .. "floating_healthbars/",
		save_file = SavePath .. "floating_healthbars/settings.json",
		variants = {},
		fonts = {
			tweak_data.menu.pd2_medium_font,
			"fonts/font_eurostile_ext",
			"core/fonts/diesel",
			"core/fonts/system_font",
		},
		settings = {
			variant = "default",
			fill_direction = 1,
			scale_type = 1,
			max_scale = 2,
			width_by_text = false,
			width = 128,
			height = 20,
			name_size = 20,
			name_x_offset = 0,
			name_y_offset = -1,
			hp_size = 16,
			hp_x_offset = 0,
			hp_y_offset = 1,
			allcaps = false,
			font = 1,
			outline = true,
			enemies = true,
			jokers = true,
			civilians = true,
			hostages = true,
			turrets = true
		}
	}

	function FloatingHealthbars:character_slot_mask()
		local slots = {}
		if self.settings.enemies then
			table.insert(slots, 12)
			table.insert(slots, 13)
		end
		if self.settings.jokers then
			table.insert(slots, 16)
		end
		if self.settings.civilians then
			table.insert(slots, 21)
		end
		if self.settings.hostages then
			table.insert(slots, 22)
		end
		if self.settings.turrets then
			table.insert(slots, 25)
			table.insert(slots, 26)
		end
		return World:make_slot_mask(unpack(slots))
	end

	if not file.DirectoryExists(FloatingHealthbars.save_path) then
		file.CreateDirectory(FloatingHealthbars.save_path)
	end

	local texture_ids = Idstring("texture")
	local function add_variants(asset_path)
		for _, file in pairs(file.GetFiles(asset_path)) do
			local name, ext = file:match("^(.+)%.(.+)$")
			if ext == "dds" or ext == "texture" then
				local path = "guis/textures/healtbars/" .. name
				BLT.AssetManager:CreateEntry(Idstring(path), texture_ids, asset_path .. file)
				FloatingHealthbars.variants[name] = path
			end
		end
	end
	add_variants(FloatingHealthbars.mod_path .. "assets/")
	add_variants(FloatingHealthbars.save_path)

	if io.file_is_readable(FloatingHealthbars.save_file) then
		local data = io.load_as_json(FloatingHealthbars.save_file)
		for k, v in pairs(FloatingHealthbars.settings) do
			if type(data[k]) == type(v) then
				FloatingHealthbars.settings[k] = data[k]
			end
		end
	end

	Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInitFloatingHealthbars", function (loc)
		HopLib:load_localization(FloatingHealthbars.mod_path .. "loc/", loc)
	end)

	Hooks:Add("MenuManagerBuildCustomMenus", "MenuManagerBuildCustomMenusFloatingHealthbars", function(_, nodes)

		local width_menu_item, max_scale_menu_item
		local menu_id = "floating_healthbars"
		local menu_id_units = "floating_healthbars_units"

		MenuHelper:NewMenu(menu_id)
		MenuHelper:NewMenu(menu_id_units)

		function MenuCallbackHandler:floating_healthbars_value(item)
			local value = item:value()
			FloatingHealthbars.settings[item:name()] = value
			max_scale_menu_item:set_enabled(FloatingHealthbars.settings.scale_type > 1)
		end

		function MenuCallbackHandler:floating_healthbars_toggle(item)
			FloatingHealthbars.settings[item:name()] = item:value() == "on"
			width_menu_item:set_enabled(not FloatingHealthbars.settings.width_by_text)
		end

		function MenuCallbackHandler:floating_healthbars_toggle_unit(item)
			self:floating_healthbars_toggle(item)
			if managers.hud then
				managers.hud:reset_floating_healthbar()
			end
		end

		function MenuCallbackHandler:floating_healthbars_save()
			io.save_as_json(FloatingHealthbars.settings, FloatingHealthbars.save_file)
			if managers.hud then
				managers.hud:reset_floating_healthbar()
			end
		end

		local variants = table.map_keys(FloatingHealthbars.variants)
		local pretty_variants = {}
		for k, v in pairs(variants) do
			pretty_variants[k] = v:pretty(true)
		end
		MenuHelper:AddMultipleChoice({
			menu_id = menu_id,
			id = "variant",
			title = "menu_floating_healthbars_variant",
			items = pretty_variants,
			item_values = variants,
			localized_items = false,
			value = FloatingHealthbars.settings.variant,
			callback = "floating_healthbars_value",
			priority = 99
		})

		MenuHelper:AddMultipleChoice({
			menu_id = menu_id,
			id = "fill_direction",
			title = "menu_floating_healthbars_fill_direction",
			items = { "menu_floating_healthbars_left", "menu_floating_healthbars_right", "menu_floating_healthbars_center" },
			value = FloatingHealthbars.settings.fill_direction,
			callback = "floating_healthbars_value",
			priority = 98
		})

		MenuHelper:AddToggle({
			menu_id = menu_id,
			id = "width_by_text",
			title = "menu_floating_healthbars_width_by_text",
			desc = "menu_floating_healthbars_width_by_text_desc",
			value = FloatingHealthbars.settings.width_by_text,
			callback = "floating_healthbars_toggle",
			priority = 97
		})

		width_menu_item = MenuHelper:AddSlider({
			menu_id = menu_id,
			id = "width",
			title = "menu_floating_healthbars_width",
			disabled = FloatingHealthbars.settings.width_by_text,
			value = FloatingHealthbars.settings.width,
			min = 8,
			max = 640,
			step = 8,
			show_value = true,
			display_precision = 0,
			callback = "floating_healthbars_value",
			priority = 96
		})

		MenuHelper:AddSlider({
			menu_id = menu_id,
			id = "height",
			title = "menu_floating_healthbars_height",
			value = FloatingHealthbars.settings.height,
			min = 8,
			max = 64,
			step = 4,
			show_value = true,
			display_precision = 0,
			callback = "floating_healthbars_value",
			priority = 95
		})

		MenuHelper:AddDivider({
			menu_id = menu_id,
			size = 16,
			priority = 90
		})

		MenuHelper:AddMultipleChoice({
			menu_id = menu_id,
			id = "font",
			title = "menu_floating_healthbars_font",
			items = table.remap(FloatingHealthbars.fonts, function (k) return k, "menu_floating_healthbars_font_" .. k end),
			value = FloatingHealthbars.settings.font,
			callback = "floating_healthbars_value",
			priority = 89
		})

		MenuHelper:AddToggle({
			menu_id = menu_id,
			id = "allcaps",
			title = "menu_floating_healthbars_allcaps",
			value = FloatingHealthbars.settings.allcaps,
			callback = "floating_healthbars_toggle",
			priority = 88
		})

		MenuHelper:AddToggle({
			menu_id = menu_id,
			id = "outline",
			title = "menu_floating_healthbars_outline",
			value = FloatingHealthbars.settings.outline,
			callback = "floating_healthbars_toggle",
			priority = 87
		})

		MenuHelper:AddDivider({
			menu_id = menu_id,
			size = 16,
			priority = 80
		})

		MenuHelper:AddSlider({
			menu_id = menu_id,
			id = "name_size",
			title = "menu_floating_healthbars_name_size",
			value = FloatingHealthbars.settings.name_size,
			min = 0,
			max = 64,
			step = 4,
			show_value = true,
			display_precision = 0,
			callback = "floating_healthbars_value",
			priority = 79
		})

		MenuHelper:AddSlider({
			menu_id = menu_id,
			id = "name_x_offset",
			title = "menu_floating_healthbars_name_x_offset",
			desc = "menu_floating_healthbars_name_x_offset_desc",
			value = FloatingHealthbars.settings.name_x_offset,
			min = -1,
			max = 1,
			step = 0.05,
			show_value = true,
			display_precision = 0,
			display_scale = 100,
			is_percentage = true,
			callback = "floating_healthbars_value",
			priority = 78
		})

		MenuHelper:AddSlider({
			menu_id = menu_id,
			id = "name_y_offset",
			title = "menu_floating_healthbars_name_y_offset",
			desc = "menu_floating_healthbars_name_y_offset_desc",
			value = FloatingHealthbars.settings.name_y_offset,
			min = -1,
			max = 1,
			step = 0.05,
			show_value = true,
			display_precision = 0,
			display_scale = 100,
			is_percentage = true,
			callback = "floating_healthbars_value",
			priority = 77
		})

		MenuHelper:AddDivider({
			menu_id = menu_id,
			size = 16,
			priority = 70
		})

		MenuHelper:AddSlider({
			menu_id = menu_id,
			id = "hp_size",
			title = "menu_floating_healthbars_hp_size",
			value = FloatingHealthbars.settings.hp_size,
			min = 0,
			max = 64,
			step = 4,
			show_value = true,
			display_precision = 0,
			callback = "floating_healthbars_value",
			priority = 69
		})

		MenuHelper:AddSlider({
			menu_id = menu_id,
			id = "hp_x_offset",
			title = "menu_floating_healthbars_hp_x_offset",
			desc = "menu_floating_healthbars_hp_x_offset_desc",
			value = FloatingHealthbars.settings.hp_x_offset,
			min = -1,
			max = 1,
			step = 0.05,
			show_value = true,
			display_precision = 0,
			display_scale = 100,
			is_percentage = true,
			callback = "floating_healthbars_value",
			priority = 68
		})

		MenuHelper:AddSlider({
			menu_id = menu_id,
			id = "hp_y_offset",
			title = "menu_floating_healthbars_hp_y_offset",
			desc = "menu_floating_healthbars_hp_y_offset_desc",
			value = FloatingHealthbars.settings.hp_y_offset,
			min = -1,
			max = 1,
			step = 0.05,
			show_value = true,
			display_precision = 0,
			display_scale = 100,
			is_percentage = true,
			callback = "floating_healthbars_value",
			priority = 67
		})

		MenuHelper:AddDivider({
			menu_id = menu_id,
			size = 16,
			priority = 60
		})

		MenuHelper:AddMultipleChoice({
			menu_id = menu_id,
			id = "scale_type",
			title = "menu_floating_healthbars_scale_type",
			desc = "menu_floating_healthbars_scale_type_desc",
			items = { "menu_floating_healthbars_scale_none", "menu_floating_healthbars_scale_total_hp", "menu_floating_healthbars_scale_special" },
			value = FloatingHealthbars.settings.scale_type,
			callback = "floating_healthbars_value",
			priority = 59
		})

		max_scale_menu_item = MenuHelper:AddSlider({
			menu_id = menu_id,
			id = "max_scale",
			title = "menu_floating_healthbars_max_scale",
			desc = "menu_floating_healthbars_max_scale_desc",
			disabled = FloatingHealthbars.settings.scale_type == 1,
			value = FloatingHealthbars.settings.max_scale,
			min = 1,
			max = 3,
			step = 0.05,
			show_value = true,
			display_precision = 2,
			callback = "floating_healthbars_value",
			priority = 58
		})

		MenuHelper:AddDivider({
			menu_id = menu_id,
			size = 16,
			priority = 50
		})

		MenuHelper:AddButton({
			menu_id = menu_id,
			id = "units",
			title = "menu_floating_healthbars_units",
			desc = "menu_floating_healthbars_units_desc",
			next_node = menu_id_units,
			priority = 49
		})

		MenuHelper:AddToggle({
			menu_id = menu_id_units,
			id = "enemies",
			title = "menu_floating_healthbars_enemies",
			value = FloatingHealthbars.settings.enemies,
			callback = "floating_healthbars_toggle_unit",
			priority = 10
		})

		MenuHelper:AddToggle({
			menu_id = menu_id_units,
			id = "jokers",
			title = "menu_floating_healthbars_jokers",
			value = FloatingHealthbars.settings.jokers,
			callback = "floating_healthbars_toggle_unit",
			priority = 9
		})

		MenuHelper:AddToggle({
			menu_id = menu_id_units,
			id = "civilians",
			title = "menu_floating_healthbars_civilians",
			value = FloatingHealthbars.settings.civilians,
			callback = "floating_healthbars_toggle_unit",
			priority = 8
		})

		MenuHelper:AddToggle({
			menu_id = menu_id_units,
			id = "hostages",
			title = "menu_floating_healthbars_hostages",
			value = FloatingHealthbars.settings.hostages,
			callback = "floating_healthbars_toggle_unit",
			priority = 7
		})

		MenuHelper:AddToggle({
			menu_id = menu_id_units,
			id = "turrets",
			title = "menu_floating_healthbars_turrets",
			value = FloatingHealthbars.settings.turrets,
			callback = "floating_healthbars_toggle_unit",
			priority = 6
		})

		nodes[menu_id] = MenuHelper:BuildMenu(menu_id, { area_bg = "half", back_callback = "floating_healthbars_save" })
		nodes[menu_id_units] = MenuHelper:BuildMenu(menu_id_units, { area_bg = "half", back_callback = "floating_healthbars_save" })
		MenuHelper:AddMenuItem(nodes["blt_options"], menu_id, "menu_floating_healthbars")
	end)

end

HopLib:run_required(FloatingHealthbars.mod_path .. "lua/")
