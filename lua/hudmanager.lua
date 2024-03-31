function HUDManager:reset_floating_healthbar()
	if self._unit_healthbar and self._unit_healthbar:alive() then
		self._unit_healthbar:destroy()
		self._unit_healthbar = nil
	end

	self._unit_slotmask_no_walls = FloatingHealthbars:character_slot_mask()
	self._unit_slotmask = self._unit_slotmask_no_walls + managers.slot:get_mask("bullet_blank_impact_targets")
end

Hooks:PostHook(HUDManager, "init_finalize", "init_finalize_enemy_health_bars", function (self)
	self._healthbar_panel = self._healthbar_panel or managers.hud:panel(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN_PD2)

	self._next_unit_raycast_t = 0

	self:reset_floating_healthbar()
end)

local mvec_add = mvector3.add
local mvec_mul = mvector3.multiply
local mvec_set = mvector3.set
local to_vec = Vector3()
Hooks:PostHook(HUDManager, "update", "update_enemy_health_bars", function (self, t, dt)
	if self._next_unit_raycast_t > t then
		return
	end

	self._next_unit_raycast_t = t + 0.05

	local player = managers.player:local_player()
	if not alive(player) then
		if self._unit_healthbar and self._unit_healthbar:alive() then
			self._unit_healthbar:destroy()
			self._unit_healthbar = nil
		end
		return
	end

	local cam = player:camera()
	local from = cam:position()
	mvec_set(to_vec, cam:forward())
	mvec_mul(to_vec, player:movement():current_state():in_steelsight() and FloatingHealthbars.settings.max_distance_ads or FloatingHealthbars.settings.max_distance)
	mvec_add(to_vec, from)
	local ray1 = World:raycast("ray", from, to_vec, "slot_mask", self._unit_slotmask_no_walls, "sphere_cast_radius", 30)
	local ray2 = World:raycast("ray", from, to_vec, "slot_mask", self._unit_slotmask)

	local unit = ray1 and (not ray2 or ray2.unit == ray1.unit or ray2.distance > ray1.distance + 60) and ray1.unit or ray2 and ray2.unit
	unit = unit and unit:in_slot(8) and unit:parent() or unit

	if self._unit_healthbar and (self._unit_healthbar._unit ~= unit or not self._unit_healthbar:alive()) then
		self._unit_healthbar:hide()
		self._unit_healthbar = nil
	end

	local dmg = alive(unit) and unit:character_damage()
	if not self._unit_healthbar and dmg and dmg.health_ratio and not dmg._dead then
		self._unit_healthbar = unit:unit_data()._healthbar or EnemyHealthBar:new(self._healthbar_panel, unit)
		self._unit_healthbar:show()
	end
end)
