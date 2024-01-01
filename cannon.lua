-- vi: noexpandtab

local cannon = {}

--local has_digilines = minetest.get_modpath("digilines") and true
local has_pipeworks = minetest.get_modpath("pipeworks") and true

local cable_entry = "^technic_cable_connection_overlay.png"

local groups_base = {
	cracky = 3,
	oddly_breakable_by_hand = 3,
	technic_machine = 1,
	technic_hv = 1
}

local groups_rail = table.copy(groups_base)
if has_pipeworks then
	groups_rail.tubedevice = 1
	groups_rail.tubedevice_receiver = 1
end

local register_spacecannon_2 = function(def)

	local entity_texture = "energycube_" .. def.color .. ".png"

	minetest.register_entity("ialazor:energycube_" .. def.color, {
		initial_properties = {
			visual = "cube",
			visual_size = {x=0.25, y=0.25},
			textures = {
				entity_texture,
				entity_texture,
				entity_texture,
				entity_texture,
				entity_texture,
				entity_texture
			},
			collisionbox = {-0.25,-0.25,-0.25, 0.25,0.25,0.25},
			physical = false
		},
		timer = 0,
		lifetime = 0,
		static_save = false,
		penetrated = 0,

		on_step = function(self, dtime)
			self.timer = self.timer + dtime
			self.lifetime = self.lifetime + dtime

			if self.lifetime > def.timeout then
				self.object:remove()
				return
			end

			local pos = self.object:getpos()

			if self.timer > 0.5 then
				-- add sparks along the way
				minetest.add_particlespawner({
						amount = 5,
						time = 0.5,
						minpos = pos,
						maxpos = pos,
						minvel = {x = -2, y = -2, z = -2},
						maxvel = {x = 2, y = 2, z = 2},
						minacc = {x = -3, y = -3, z = -3},
						maxacc = {x = 3, y = 3, z = 3},
						minexptime = 1,
						maxexptime = 2.5,
						minsize = 0.5,
						maxsize = 0.75,
						texture = "spacecannon_spark.png",
						glow = 5
				})
				self.timer = 0
			end

			local node = minetest.get_node(pos)
			local node_def = minetest.registered_nodes[node.name]

			local goes_through = not node_def.walkable

			if goes_through then
				local objs = minetest.get_objects_inside_radius({x=pos.x,y=pos.y,z=pos.z}, 1)
				local collided = false
				for _, obj in pairs(objs) do
					if (obj:is_player() or (obj:get_luaentity() ~= nil
						and obj:get_luaentity().name ~= self.name
						and obj:get_luaentity().name ~= "__builtin:item"))
						and ialazor.can_damage(obj)
					then
						collided = true
						obj:punch(self.object, 1.0, {
								full_punch_interval=1.0,
								damage_groups={fleshy=def.damage},
							}, nil)
					end
				end

				if collided then
					ialazor.destroy_2(pos, def.range, def.intensity)
					self.penetrated = self.penetrated + 1
					if self.penetrated >= def.penetration then
						self.object:remove()
					end
				end

			else
				-- collision
				ialazor.destroy_2(pos, def.range, def.intensity)
				self.penetrated = self.penetrated + 1
				if self.penetrated >= def.penetration then
					self.object:remove()
				end
			end
		end
	})

	-- top, bottom
	local textures = {
		"cannon_blank.png" .. cable_entry,
		"cannon_front_" .. def.color .. ".png",
		"cannon_blank.png" .. cable_entry,
		"cannon_blank.png" .. cable_entry,
		"cannon_blank.png" .. cable_entry,
		"cannon_blank.png" .. cable_entry
	}
	if def.textures then
		textures = def.textures
	end

	local def_cannon = {
		description = def.name .. " (" .. def.desc .. ")",
		tiles = textures,
		groups = def.is_th and groups_base or groups_rail,
		drop = "ialazor:cannon_" .. def.color,
		sounds = default.node_sound_glass_defaults(),
		paramtype2 = "facedir",
		legacy_facedir_simple = true,

		mesecons = {effector = {
			action_on = function (pos)
				local meta = minetest.get_meta(pos)
				local owner = meta:get_string("owner")
				ialazor.fire_2(pos, owner, def.color, def.speed, def.is_th, def.storage_require_mod)
			end
		}},

		connects_to = {"group:technic_hv_cable"},
		connect_sides = {"bottom", "top", "left", "right", "front", "back"},

		digiline = {
			receptor = {
				rules = ialazor.digiline_rules,
				action = function() end
			},
			effector = {
				rules = ialazor.digiline_rules,
				action = ialazor.digiline_effector
			},
		},

		after_place_node = function(pos, placer)
			local meta = minetest.get_meta(pos)
			meta:set_string("owner", placer:get_player_name() or "")
			if has_pipeworks then
				pipeworks.after_place(pos)
			end
		end,

		on_construct = function(pos)
			local meta = minetest.get_meta(pos)
			meta:set_int("powerstorage", 0)

			meta:set_int("HV_EU_input", 0)
			meta:set_int("HV_EU_demand", 0)

			-- Set default digiline channel (do before updating formspec).
			meta:set_string("channel", "spacecannon")

			-- Set inventory (not used for thermal cannons)
			if not def.is_th then
				local inv = meta:get_inventory()
				inv:set_size("src", 1)
			end

			ialazor.update_formspec(meta, def.is_th)
		end,

		technic_run = function(pos)
			local meta = minetest.get_meta(pos)
			local eu_input = meta:get_int("HV_EU_input")
			local demand = meta:get_int("HV_EU_demand")
			local store = meta:get_int("powerstorage")

			local config_store = ialazor.config.ki_powerstorage * def.storage_require_mod
			if def.is_th then config_store = ialazor.config.th_powerstorage * def.storage_require_mod end
			local config_require = ialazor.config.ki_powerrequirement
			if def.is_th then config_require = ialazor.config.th_powerrequirement end

			local infotext =
				"Power: " .. eu_input .. "/" .. demand .. " " ..
				"Store: " .. store .. "\n" ..
				def.name .. ": " .. def.desc
			meta:set_string("infotext", infotext)

			if store < config_store then
				-- charge
				meta:set_int("HV_EU_demand", config_require)
				meta:set_int("powerstorage", store + eu_input)
			else
				-- charged
				meta:set_int("HV_EU_demand", 0)
			end
		end,

		on_receive_fields = function(pos, _, fields, sender)
			local playername = sender and sender:get_player_name() or ""
			if minetest.is_protected(pos, playername) then
				-- only allow protection-owner to fire and configure
				return
			end

			local meta = minetest.get_meta(pos)

			if fields.fire then
				ialazor.fire_2(pos, playername, def.color, def.speed, def.is_th, def.storage_require_mod)
			end

			if fields.set_digiline_channel and fields.digiline_channel then
				meta:set_string("channel", fields.digiline_channel)
			end

			ialazor.update_formspec(meta, def.is_th)
		end,

		after_dig_node = function(pos, _node, meta, _digger)
			if meta.inventory and meta.inventory.src and meta.inventory.src[1] then
				minetest.add_item(pos, ItemStack(meta.inventory.src[1]))
			end
			if has_pipeworks then
				pipeworks.after_dig(pos)
			end
		end
	}

	if has_pipeworks and not def.is_th then
		def_cannon.tube = {
			insert_object = function(pos, _, stack)
				local meta = minetest.get_meta(pos)
				local inv = meta:get_inventory()
				return inv:add_item("src", stack)
			end,
			can_insert = function(pos, _, stack)
				local meta = minetest.get_meta(pos)
				local inv = meta:get_inventory()
				stack = stack:peek_item(1)

				return inv:room_for_item("src", stack)
			end,
			input_inventory = "src",
			connect_sides = {
				left = 1, back = 1, top = 1,
				right = 1, front = 1, bottom = nil
			}
		}
	end

	minetest.register_node("ialazor:cannon_" .. def.color, def_cannon)

	technic.register_machine("HV", "ialazor:cannon_" .. def.color, technic.receiver)

	minetest.register_craft({
		output = 'ialazor:cannon_' .. def.color,
		recipe = {
			{'', 'default:steelblock', ''},
			{ def.ingredient, def.ingredient, def.ingredient},
			{'', 'default:steelblock', ''}
		}
	})

end



local register_spacecannon_1 = function(def)

	-- TODO use laser beam
	local entity_texture = "energycube_" .. def.color .. ".png"

	minetest.register_entity("ialazor:energycube_" .. def.color, {
		initial_properties = {
			visual = "cube",
			visual_size = {x=0.25, y=0.25},
			textures = {
				entity_texture,
				entity_texture,
				entity_texture,
				entity_texture,
				entity_texture,
				entity_texture
			},
			collisionbox = {-0.25,-0.25,-0.25, 0.25,0.25,0.25},
			physical = false
		},
		timer = 0,
		lifetime = 0,
		static_save = false,
		penetrated = 0,

		on_step = function(self, dtime)
			self.timer = self.timer + dtime
			self.lifetime = self.lifetime + dtime

			if self.lifetime > def.timeout then
				self.object:remove()
				return
			end

			local pos = self.object:getpos()

			if self.timer > 0.5 then
				-- add sparks along the way
				minetest.add_particlespawner({
						amount = 5,
						time = 0.5,
						minpos = pos,
						maxpos = pos,
						minvel = {x = -2, y = -2, z = -2},
						maxvel = {x = 2, y = 2, z = 2},
						minacc = {x = -3, y = -3, z = -3},
						maxacc = {x = 3, y = 3, z = 3},
						minexptime = 1,
						maxexptime = 2.5,
						minsize = 0.5,
						maxsize = 0.75,
						texture = "spacecannon_spark.png",
						glow = 5
				})
				self.timer = 0
			end

			local node = minetest.get_node(pos)
			local node_def = minetest.registered_nodes[node.name]

			local goes_through = not node_def.walkable

			if goes_through then
				local objs = minetest.get_objects_inside_radius({x=pos.x,y=pos.y,z=pos.z}, 1)
				local collided = false
				for _, obj in pairs(objs) do
					if (obj:is_player() or (obj:get_luaentity() ~= nil
						and obj:get_luaentity().name ~= self.name
						and obj:get_luaentity().name ~= "__builtin:item"))
						and ialazor.can_damage(obj)
					then
						collided = true
						obj:punch(self.object, 1.0, {
								full_punch_interval=1.0,
								damage_groups={fleshy=def.damage},
							}, nil)
					end
				end

				if collided then
					-- TODO destroy_1
					ialazor.destroy_1(pos, def.range, def.intensity)
					self.penetrated = self.penetrated + 1
					if self.penetrated >= def.penetration then
						self.object:remove()
					end
				end

			else
				-- collision
				-- TODO destroy_1
				ialazor.destroy_1(pos, def.range, def.intensity)
				self.penetrated = self.penetrated + 1
				if self.penetrated >= def.penetration then
					self.object:remove()
				end
			end
		end
	})

	-- top, bottom
	local textures = {
		"cannon_blank.png" .. cable_entry,
		"cannon_front_" .. def.color .. ".png",
		"cannon_blank.png" .. cable_entry,
		"cannon_blank.png" .. cable_entry,
		"cannon_blank.png" .. cable_entry,
		"cannon_blank.png" .. cable_entry
	}
	if def.textures then
		textures = def.textures
	end

	local def_cannon = {
		description = def.name .. " (" .. def.desc .. ")",
		tiles = textures,
		groups = def.is_th and groups_base or groups_rail,
		drop = "ialazor:cannon_" .. def.color,
		sounds = default.node_sound_glass_defaults(),
		paramtype2 = "facedir",
		legacy_facedir_simple = true,

		mesecons = {effector = {
			action_on = function (pos)
				local meta = minetest.get_meta(pos)
				local owner = meta:get_string("owner")
				-- TODO fire_1
				ialazor.fire_1(pos, owner, def.color, def.speed, def.is_th, def.storage_require_mod)
			end
		}},

		connects_to = {"group:technic_hv_cable"},
		connect_sides = {"bottom", "top", "left", "right", "front", "back"},

		digiline = {
			receptor = {
				rules = ialazor.digiline_rules,
				action = function() end
			},
			effector = {
				rules = ialazor.digiline_rules,
				action = ialazor.digiline_effector
			},
		},

		after_place_node = function(pos, placer)
			local meta = minetest.get_meta(pos)
			meta:set_string("owner", placer:get_player_name() or "")
			if has_pipeworks then
				pipeworks.after_place(pos)
			end
		end,

		on_construct = function(pos)
			local meta = minetest.get_meta(pos)
			meta:set_int("powerstorage", 0)

			meta:set_int("HV_EU_input", 0)
			meta:set_int("HV_EU_demand", 0)

			-- Set default digiline channel (do before updating formspec).
			meta:set_string("channel", "spacecannon")

			-- Set inventory (not used for thermal cannons)
			if not def.is_th then
				local inv = meta:get_inventory()
				inv:set_size("src", 1)
			end

			ialazor.update_formspec(meta, def.is_th)
		end,

		technic_run = function(pos)
			local meta = minetest.get_meta(pos)
			local eu_input = meta:get_int("HV_EU_input")
			local demand = meta:get_int("HV_EU_demand")
			local store = meta:get_int("powerstorage")

			local config_store = ialazor.config.ki_powerstorage * def.storage_require_mod
			if def.is_th then config_store = ialazor.config.th_powerstorage * def.storage_require_mod end
			local config_require = ialazor.config.ki_powerrequirement
			if def.is_th then config_require = ialazor.config.th_powerrequirement end

			local infotext =
				"Power: " .. eu_input .. "/" .. demand .. " " ..
				"Store: " .. store .. "\n" ..
				def.name .. ": " .. def.desc
			meta:set_string("infotext", infotext)

			if store < config_store then
				-- charge
				meta:set_int("HV_EU_demand", config_require)
				meta:set_int("powerstorage", store + eu_input)
			else
				-- charged
				meta:set_int("HV_EU_demand", 0)
			end
		end,

		on_receive_fields = function(pos, _, fields, sender)
			local playername = sender and sender:get_player_name() or ""
			if minetest.is_protected(pos, playername) then
				-- only allow protection-owner to fire and configure
				return
			end

			local meta = minetest.get_meta(pos)

			if fields.fire then
				-- TODO fire_1
				ialazor.fire_1(pos, playername, def.color, def.speed, def.is_th, def.storage_require_mod)
			end

			if fields.set_digiline_channel and fields.digiline_channel then
				meta:set_string("channel", fields.digiline_channel)
			end

			ialazor.update_formspec(meta, def.is_th)
		end,

		after_dig_node = function(pos, _node, meta, _digger)
			if meta.inventory and meta.inventory.src and meta.inventory.src[1] then
				minetest.add_item(pos, ItemStack(meta.inventory.src[1]))
			end
			if has_pipeworks then
				pipeworks.after_dig(pos)
			end
		end
	}

	if has_pipeworks and not def.is_th then
		def_cannon.tube = {
			insert_object = function(pos, _, stack)
				local meta = minetest.get_meta(pos)
				local inv = meta:get_inventory()
				return inv:add_item("src", stack)
			end,
			can_insert = function(pos, _, stack)
				local meta = minetest.get_meta(pos)
				local inv = meta:get_inventory()
				stack = stack:peek_item(1)

				return inv:room_for_item("src", stack)
			end,
			input_inventory = "src",
			connect_sides = {
				left = 1, back = 1, top = 1,
				right = 1, front = 1, bottom = nil
			}
		}
	end

	minetest.register_node("ialazor:cannon_" .. def.color, def_cannon)

	technic.register_machine("HV", "ialazor:cannon_" .. def.color, technic.receiver)

	minetest.register_craft({
		output = 'ialazor:cannon_' .. def.color,
		recipe = {
			{'', 'default:steelblock', ''},
			{ def.ingredient, def.ingredient, def.ingredient},
			{'', 'default:steelblock', ''}
		}
	})

end

cannon.register_spacecannon_1 = register_spacecannon_1
cannon.register_spacecannon_2 = register_spacecannon_2
return cannon
