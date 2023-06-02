EnemyHealthBar = EnemyHealthBar or class()
EnemyHealthBar.PANEL_FADE_TIME = 0.25

local function set_texture_rect(bitmap, x, y, w, h)
	local tex_w, tex_h = bitmap:texture_width(), bitmap:texture_height()
	local x_ratio, y_ratio = tex_w / 128, tex_h / 128
	bitmap:set_texture_rect(x * x_ratio, y * y_ratio, w * x_ratio, h * y_ratio)
end

function EnemyHealthBar:init(panel, unit)
	self._unit = unit

	self._panel = panel:panel({
		alpha = 0,
		layer = -100
	})

	local center_x = math.round(self._panel:w() * 0.5)
	local center_y = math.round(self._panel:h() * 0.5)

	local scale = 1
	if FloatingHealthbars.settings.scale_by_hp then
		scale = math.min(math.max(1, (unit:character_damage()._HEALTH_INIT or 4) / (tweak_data.character.swat.HEALTH_INIT * 0.5)) ^ 0.15, 2)
	end

	local unit_info = HopLib and HopLib:unit_info_manager():get_info(unit)
	local unit_name = unit_info and unit_info:nickname() or (unit:base()._tweak_table or "Unknown"):pretty()
	local name = self._panel:text({
		layer = 2,
		text = FloatingHealthbars.settings.allcaps and unit_name:upper() or unit_name,
		font = tweak_data.menu.default_font,
		font_size = FloatingHealthbars.settings.name_size * scale,
		color = Color.white
	})
	local _, _, w, h = name:text_rect()
	name:set_size(w, h)

	local healthbar_path = FloatingHealthbars.variants[FloatingHealthbars.settings.variant] or FloatingHealthbars.variants.default

	self._health_width = math.round(math.max(FloatingHealthbars.settings.width_by_text and name:w() or scale * FloatingHealthbars.settings.width, 8))
	self._health_height = math.round(scale * math.max(FloatingHealthbars.settings.height, 8))

	-- Background
	local bg = self._panel:panel({
		w = self._health_width + self._health_height * 2,
		h = self._health_height
	})

	local bg_left = bg:bitmap({
		layer = -1,
		texture = healthbar_path,
		w = self._health_height,
		h = self._health_height,
	})
	set_texture_rect(bg_left, 0, 0, 32, 32)

	local bg_right = bg:bitmap({
		layer = -1,
		texture = healthbar_path,
		x = self._health_width + self._health_height,
		w = self._health_height,
		h = self._health_height,
	})
	set_texture_rect(bg_right, 96, 0, 32, 32)

	local bg_center = bg:bitmap({
		layer = -1,
		texture = healthbar_path,
		x = self._health_height,
		w = self._health_width,
		h = self._health_height,
	})
	set_texture_rect(bg_center, 48, 0, 32, 32)

	-- Foreground
	local fg = self._panel:panel({
		w = self._health_width + self._health_height * 2,
		h = self._health_height
	})

	local fg_left = fg:bitmap({
		layer = 1,
		texture = healthbar_path,
		w = self._health_height,
		h = self._health_height,
	})
	set_texture_rect(fg_left, 0, 96, 32, 32)

	local fg_right = fg:bitmap({
		layer = 1,
		texture = healthbar_path,
		x = self._health_width + self._health_height,
		w = self._health_height,
		h = self._health_height,
	})
	set_texture_rect(fg_right, 96, 96, 32, 32)

	local fg_center = fg:bitmap({
		layer = 1,
		texture = healthbar_path,
		x = self._health_height,
		w = self._health_width,
		h = self._health_height,
	})
	set_texture_rect(fg_center, 48, 96, 32, 32)

	-- Healthbar
	self._hp_panel = self._panel:panel({
		w = self._health_width + self._health_height * 2,
		h = self._health_height
	})

	self._hp_left = self._hp_panel:bitmap({
		layer = 0,
		texture = healthbar_path,
		w = self._health_height,
		h = self._health_height,
	})
	set_texture_rect(self._hp_left, 0, 48, 32, 32)

	self._hp_right = self._hp_panel:bitmap({
		layer = 0,
		texture = healthbar_path,
		x = self._health_width + self._health_height,
		w = self._health_height,
		h = self._health_height,
	})
	set_texture_rect(self._hp_right, 96, 48, 32, 32)

	self._hp_center = self._hp_panel:bitmap({
		layer = 0,
		texture = healthbar_path,
		x = self._health_height,
		w = self._health_width,
		h = self._health_height,
	})
	set_texture_rect(self._hp_center, 48, 48, 32, 32)

	bg:set_center(center_x, center_y)
	fg:set_center(center_x, center_y)
	self._hp_panel:set_center(center_x, center_y)

	local x_off = name:w() >= self._hp_center:w() and 0 or FloatingHealthbars.settings.name_x_offset * (self._hp_center:w() - name:w()) * 0.5
	local y_off = FloatingHealthbars.settings.name_y_offset * (name:h() + self._hp_panel:h()) * 0.5
	name:set_center(center_x + x_off, center_y + y_off)

	self._panel:set_h(math.max(self._hp_panel:bottom(), name:bottom()))

	local events = {}
	for _, v in pairs(CopDamage._all_event_types) do
		events[v] = true
	end
	for _, v in pairs(CopDamage._ATTACK_VARIANTS) do
		events[v] = true
	end

	unit:unit_data()._healthbar = self

	self._key = "health_bar" .. tostring(unit:key())

	if unit:character_damage().add_listener then
		unit:character_damage():add_listener(self._key, table.map_keys(events), callback(self, self, "update_hp"))
	end
	if unit:base().add_destroy_listener then
		unit:base():add_destroy_listener(self._key, callback(self, self, "destroy"))
	end
	managers.hud:add_updator(self._key, callback(self, self, "update"))

	self:update_hp()
end

function EnemyHealthBar:_anim_fade_panel(panel, start_alpha, alpha, done_cb)
	over(math.abs(alpha - start_alpha) * self.PANEL_FADE_TIME, function (t)
		panel:set_alpha(math.lerp(start_alpha, alpha, t))
	end)
	if done_cb then
		done_cb()
	end
end

function EnemyHealthBar:_anim_hp_change(hp_center, hp_left, hp_right, start_ratio, ratio)
	over(not self._health_ratio and 0 or ratio > self._health_ratio and 0.2 or 0.05, function (t)
		self._health_ratio = math.lerp(start_ratio, ratio, t)
		hp_center:set_w(math.round(self._health_width * self._health_ratio))
		if FloatingHealthbars.settings.fill_direction == 1 then
			hp_center:set_x(math.round(self._health_height))
		elseif FloatingHealthbars.settings.fill_direction == 1 then
			hp_center:set_right(math.round(self._health_height + self._health_width))
		else
			hp_center:set_center_x(math.round(self._health_height + self._health_width * 0.5))
		end
		hp_left:set_right(hp_center:x())
		hp_right:set_x(hp_center:right())
	end)
end

function EnemyHealthBar:_anim_hp_fade(hp_panel, start_alpha)
	over(start_alpha * 0.05, function (t)
		hp_panel:set_alpha(math.lerp(start_alpha, 0, t))
	end)
end

function EnemyHealthBar:show()
	if not self:alive() then
		return
	end

	self._panel:stop()
	self._panel:animate(callback(self, self, "_anim_fade_panel"), self._panel:alpha(), 1)
end

function EnemyHealthBar:hide()
	if not self:alive() then
		return
	end

	self._panel:stop()
	self._panel:animate(callback(self, self, "_anim_fade_panel"), self._panel:alpha(), 0, callback(self, self, "destroy"))
end

local tmp_vec = Vector3()
function EnemyHealthBar:update(t, dt)
	if not self:alive() then
		return
	end

	local ws = managers.hud._workspace
	local cam = managers.viewport:get_current_camera()

	if cam then
		local movement = self._unit:movement()
		local pos = movement._obj_head and movement._obj_head:position() or movement:m_head_pos()

		mvector3.set(tmp_vec, pos)
		mvector3.add_scaled(tmp_vec, math.UP, 30)

		local screen_pos = ws:world_to_screen(cam, tmp_vec)
		self._panel:set_center_x(math.round(screen_pos.x))
		self._panel:set_bottom(math.round(screen_pos.y + mvector3.distance(cam:position(), pos) / 1000))
		self._panel:set_visible(screen_pos.z > 0)
	end
end

function EnemyHealthBar:update_hp()
	if not self:alive() then
		return
	end

	local ratio = self._unit:character_damage():health_ratio()
	self._hp_center:stop()
	self._hp_center:animate(callback(self, self, "_anim_hp_change"), self._hp_left, self._hp_right, self._health_ratio or 0, ratio)

	if ratio <= 0 or self._unit:character_damage()._dead then
		self._hp_panel:stop()
		self._hp_panel:animate(callback(self, self, "_anim_hp_fade"), self._hp_panel:alpha())
	end
end

function EnemyHealthBar:alive()
	return alive(self._panel)
end

function EnemyHealthBar:destroy()
	if not self:alive() then
		return
	end

	if managers.hud then
		managers.hud:remove_updator(self._key)
	end

	if alive(self._unit) then
		if self._unit:character_damage().remove_listener then
			self._unit:character_damage():remove_listener(self._key)
		end
		if self._unit:base().remove_destroy_listener then
			self._unit:base():remove_destroy_listener(self._key)
		end
		self._unit:unit_data()._healthbar = nil
	end

	self._panel:parent():remove(self._panel)
end
