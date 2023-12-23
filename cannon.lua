-- vi: noexpandtab

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

minetest.register_lbm({
	label             = "Cleanup leftover beacon lights",
	name              = "ialazor:cleanup_beacon_light",
	nodenames         = { "group:beacon_light", },
	run_at_every_load = true,
	action            = function(pos, node)
		minetest.after(1, minetest.remove_node, pos)
	end
})

local register_spacecannon = function(def)

	local entity_texture = "energycube_" .. def.color .. ".png"

    minetest.register_node("ialazor:light_" .. def.color, {
        description = def.color_desc .. " Beacon Light",
        --drawtype = "plantlike",
        --drawtype = "normal",
        --drawtype = "glasslike",
        drawtype = "nodebox",
        --tiles = {
	--	"beacons_light.png",
	--},
	node_box = {
		type = "fixed",
		fixed = {
			{-0.1, -0.1, -0.5, 0.1, 0.1, 0.5}, -- Adjust the Y-axis range as needed
		},
	},
        --color = def.color:gsub("_", ""),
        color = def.color,
        paramtype = "light",
        --paramtype2 = "degrotate",
        paramtype2 = "facedir",
        sunlight_propagates = true,
        light_source = minetest.LIGHT_MAX,
        walkable = false,
        pointable = false,
        diggable = false,
        buildable_to = true,
        floodable = false,
        drop = "",
        groups = {beacon_light = 1, not_in_creative_inventory = 1},
        damage_per_second = 20,
        post_effect_color = def.color,
        on_blast = function() end,

	on_construct = function(pos)
		--print('constructing color: '..def.color)
	    local pr = 0.9
            minetest.add_particlespawner({
                amount = 20,
                time = 2,
                minpos = {x = pos.x - pr, y = pos.y - pr, z = pos.z - pr},
                maxpos = {x = pos.x + pr, y = pos.y + pr, z = pos.z + pr},
                --minvel = beam_vel,
                --maxvel = beam_vel,
                --minacc = {x = 0, y = 0, z = 0},
                --maxacc = {x = 0, y = 0, z = 0},
						minvel = {x = -2, y = -2, z = -2},
						maxvel = {x = 2, y = 2, z = 2},
						minacc = {x = -3, y = -3, z = -3},
						maxacc = {x = 3, y = 3, z = 3},
                minexptime = 0.2,
                maxexptime = 0.4,
                minsize = 0.1,
                maxsize = 0.2,
                texture = entity_texture,
                --glow = 5,
		glow = minetest.LIGHT_MAX,
                collisiondetection = true,
                collision_removal = true
            })

        	minetest.get_node_timer(pos):start(1)
	end,
        on_timer = function(pos)
		minetest.remove_node(pos)
		return false
	end,

	--on_rotate = function(pos, node, user, mode, new_param2)
	--		end,
    })
    
minetest.register_entity("ialazor:energycube_" .. def.color, {
    initial_properties = {
        --visual = "cube",
        visual = "sprite",
        visual_size = {x=0.25, y=0.25},
        textures = {
            --entity_texture,
            --entity_texture,
            --entity_texture,
            --entity_texture,
            --entity_texture,
            --entity_texture,
	    "blank.png",
        },
        collisionbox = {-0.25,-0.25,-0.25, 0.25,0.25,0.25},
        physical = false
    },
    timer = 0,
    lifetime = 0,
    static_save = false,
    penetrated = 0,

    on_activate = function(self, staticdata, dtime_s)

        local pos = self.object:get_pos()
	print("Imma firin ma lazor at: "..dump(pos))
	--self._prev_pos = pos

            local beam_pos = {x = pos.x, y = pos.y, z = pos.z}
	    --local beam_vel = self.object:get_velocity()
	    --assert(beam_vel ~= nil)

	    --local node_rotation = minetest.dir_to_facedir(beam_vel, true)
	    --assert(node_rotation ~= nil)
            --local next_pos = vector.add(beam_pos, beam_vel)
	    --assert(next_pos ~= nil)

	    local pr = 0.9
            minetest.add_particlespawner({
                amount = 20,
                time = 2,
                minpos = {x = pos.x - pr, y = pos.y - pr, z = pos.z - pr},
                maxpos = {x = pos.x + pr, y = pos.y + pr, z = pos.z + pr},
                --minvel = beam_vel,
                --maxvel = beam_vel,
                --minacc = {x = 0, y = 0, z = 0},
                --maxacc = {x = 0, y = 0, z = 0},
						minvel = {x = -2, y = -2, z = -2},
						maxvel = {x = 2, y = 2, z = 2},
						minacc = {x = -3, y = -3, z = -3},
						maxacc = {x = 3, y = 3, z = 3},
                minexptime = 0.2,
                maxexptime = 0.4,
                minsize = 0.1,
                maxsize = 0.2,
                texture = entity_texture,
                --glow = 5,
		glow = minetest.LIGHT_MAX,
                collisiondetection = true,
                collision_removal = true
            })

	    --local prev_pos = self._prev_pos
	    --if prev_pos ~= nil then
	    --	minetest.after(2, minetest.forceload_free_block, prev_pos, true)
            --end
	    --self._prev_pos = pos
	    --minetest.forceload_block(next_pos, true)

	    --minetest.set_node(next_pos, {name="ialazor:light_"..def.color, param2 = node_rotation })
    end,

    on_step = function(self, dtime)
        self.timer = self.timer + dtime
        self.lifetime = self.lifetime + dtime

        if self.lifetime > def.timeout then
            print('lifetime exceeded: '..dump(self.lifetime))
            self.object:remove()
            return
        end

        local pos = self.object:get_pos()

--        if self.timer > 0.01 then
--            -- add particles along the way to simulate a beam effect
--            minetest.add_particlespawner({
--                amount = 100,
--                time = 0.5,
--                minpos = {x = pos.x - 0.1, y = pos.y - 0.1, z = pos.z - 0.1},
--                maxpos = {x = pos.x + 0.1, y = pos.y + 0.1, z = pos.z + 0.1},
--                minvel = {x = 0, y = 0, z = 0},
--                maxvel = {x = 0, y = 0, z = 0},
--                minacc = {x = 0, y = 0, z = 0},
--                maxacc = {x = 0, y = 0, z = 0},
--                minexptime = 0.2,
--                maxexptime = 0.4,
--                minsize = 0.1,
--                maxsize = 0.2,
--                texture = entity_texture, --"spacecannon_beam.png",
--                glow = 5,
--                collisiondetection = true,
--                collision_removal = true
--            })
--            self.timer = 0
--        end

         --if self.timer > 0.05 then
            -- Adjust the particle spawn position and velocity for a continuous appearance
            local beam_pos = {x = pos.x, y = pos.y, z = pos.z}
            --local beam_vel = {x = (pos.x - prev_pos.x) / dtime,
            --                  y = (pos.y - prev_pos.y) / dtime,
            --                  z = (pos.z - prev_pos.z) / dtime}
	    local beam_vel = self.object:get_velocity()
	    assert(beam_vel ~= nil)



	    --local node_rotation = get_node_rotation(beam_vel)
	    --print(dump(beam_vel))
	    local node_rotation = minetest.dir_to_facedir(beam_vel, true)
	    --print(dump(node_rotation))
	    assert(node_rotation ~= nil)
            local next_pos = vector.add(beam_pos, beam_vel)
	    assert(next_pos ~= nil)

	    local prev_pos = self._prev_pos
	    if prev_pos ~= nil then
	    	minetest.after(2, minetest.forceload_free_block, prev_pos, true)
            end
	    self._prev_pos = pos
	    minetest.forceload_block(next_pos, true)



	    --print('placing color: '..def.color)
	    minetest.set_node(next_pos, {name="ialazor:light_"..def.color, param2 = node_rotation })

	    beam_vel = vector.multiply(beam_vel, 0.1)

--	    local pr = 0.25
--            minetest.add_particlespawner({
--                amount = 20,
--                time = 0.9,
--                minpos = {x = pos.x - pr, y = pos.y - pr, z = pos.z - pr},
--                maxpos = {x = pos.x + pr, y = pos.y + pr, z = pos.z + pr},
--                minvel = beam_vel,
--                maxvel = beam_vel,
--                minacc = {x = 0, y = 0, z = 0},
--                maxacc = {x = 0, y = 0, z = 0},
--                minexptime = 0.2,
--                maxexptime = 0.4,
--                minsize = 0.1,
--                maxsize = 0.2,
--                texture = entity_texture,
--                --glow = 5,
--		glow = minetest.LIGHT_MAX,
--                collisiondetection = true,
--                collision_removal = true
--            })

            --self.timer = 0
        --end

        local node = minetest.get_node(pos)
        local node_def = minetest.registered_nodes[node.name]

        local goes_through = false
	if node_def == nil then
		goes_through = false -- TODO
	else
		goes_through = not node_def.walkable
		--goes_through = node_def.walkable
	end

        if goes_through then
            --local objs = minetest.get_objects_inside_radius({x=pos.x,y=pos.y,z=pos.z}, 1)
            --local collided = false
            --for _, obj in pairs(objs) do
            --    if (obj:is_player() or (obj:get_luaentity() ~= nil
            --        and obj:get_luaentity().name ~= self.name
            --        and obj:get_luaentity().name ~= "__builtin:item"))
            --            and ialazor.can_damage(obj)
            --    then
            --        collided = true
            --        obj:punch(self.object, 1.0, {
            --            full_punch_interval=1.0,
            --            damage_groups={fleshy=def.damage},
            --        }, nil)
            --    end
            --end
	    local collided = ialazor.punch_parade(pos, 1, self)

            if collided then
                print('collision with entity at: '..dump(pos))
                ialazor.destroy(pos, def.range, def.intensity)
                self.penetrated = self.penetrated + 1
                if self.penetrated >= def.penetration then
                    self.object:remove()
	            minetest.after(2, minetest.forceload_free_block, next_pos, true)
                end
            end

        else
            -- collision
            print('collision with node at: '..dump(pos))
            ialazor.destroy(pos, def.range, def.intensity)
            self.penetrated = self.penetrated + 1
            if self.penetrated >= def.penetration then
                self.object:remove()
	        minetest.after(2, minetest.forceload_free_block, next_pos, true)
            end
        end
    end
})

	-- top, bottom
	local textures = { -- TODO distinct images
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
				ialazor.fire(pos, owner, def.color, def.speed, def.is_th, def.storage_require_mod)
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
				ialazor.fire(pos, playername, def.color, def.speed, def.is_th, def.storage_require_mod)
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

local       range_factor = 100
local     timeout_factor = 100
local      damage_factor = 100
local   intensity_factor = 100
local       speed_factor =  3--10 TODO
local penetration_factor =  10

register_spacecannon({
	color               = "green",
	color_desc          = "Green",
	name                = "Ion laser",
	desc                = "fast, low damage",
	is_th               = true,
	range               =  1 *       range_factor,
	storage_require_mod =  1,
	damage              =  5 *      damage_factor,
	intensity           =  1 *   intensity_factor,
	timeout             =  8 *     timeout_factor,
	speed               = 10 *       speed_factor,
	penetration         =  0 * penetration_factor,
	ingredient          = "group:kyber_active"
})

register_spacecannon({
	color               = "yellow",
	color_desc          = "Yellow",
	name                = "Plasma laser",
	desc                = "medium speed, medium damage",
	is_th               = true,
	range               =  3 *       range_factor,
	storage_require_mod =  3,
	intensity           =  2 *   intensity_factor,
	damage              =  8 *      damage_factor,
	timeout             =  8 *     timeout_factor,
	speed               =  5 *       speed_factor,
	penetration         =  0 * penetration_factor,
	ingredient          = "ialazor:cannon_green"
})

register_spacecannon({
	color               = "red",
	color_desc          = "Red",
	name                = "Nova laser",
	desc                = "slow, heavy damage",
	is_th               = true,
	range               =  5 *       range_factor,
	storage_require_mod =  5,
	intensity           =  4 *   intensity_factor,
	damage              = 10 *      damage_factor,
	timeout             = 15 *     timeout_factor,
	speed               =  3 *       speed_factor,
	penetration         =  0 * penetration_factor,
	ingredient          = "ialazor:cannon_yellow"
})

-- TODO these can use the normal spacecannon explosion, but with ridiculous penetration and timeout
-- Railguns

-- Regular railgun
register_spacecannon({
	color               = "blue",
	color_desc          = "Blue",
	name                = "Coilgun cannon",
	desc                = "fast, 2x penetrating damage",
	textures            = { -- TODO distinct images
		"railgun_blank.png" .. cable_entry,
		"railgun_front.png",
		"railgun_blank.png" .. cable_entry,
		"railgun_blank.png" .. cable_entry,
		"railgun_top_bottom.png",
		"railgun_top_bottom.png",
	},
	is_th               = false,
	range               =  0 *       range_factor,
	storage_require_mod =  1,
	intensity           =  2 *   intensity_factor,
	damage              =  6 *      damage_factor,
	timeout             = 10 *     timeout_factor,
	speed               =  9 *       speed_factor,
	penetration         =  2 * penetration_factor,
	ingredient          = "spacecannon:cannon_purple"
})

-- Helical railgun
register_spacecannon({
	color               = "purple",
	color_desc          = "Purple",
	name                = "Helical coilgun cannon",
	desc                = "fast, 4x penetrating damage",
	textures            = { -- TODO distinct images
		"railgun_blank.png" .. cable_entry,
		"helical_railgun_front.png",
		"railgun_blank.png" .. cable_entry,
		"railgun_blank.png" .. cable_entry,
		"helical_railgun_top_bottom.png",
		"helical_railgun_top_bottom.png",
	},
	is_th               = false,
	range               =  0 *       range_factor,
	storage_require_mod =  1.5,
	intensity           =  4 *   intensity_factor,
	damage              =  6 *      damage_factor,
	timeout             = 15 *     timeout_factor,
	speed               = 10 *       speed_factor,
	penetration         =  4 * penetration_factor,
	ingredient          = "ialazor:cannon_blue"
})

-- 
register_spacecannon({
	color               = "orange",
	color_desc          = "Orange",
	name                = "Helical coilgun cannon", --
	desc                = "fast, 8x penetrating damage",
	textures            = { -- TODO distinct images
		"railgun_blank.png" .. cable_entry,
		"helical_railgun_front.png",
		"railgun_blank.png" .. cable_entry,
		"railgun_blank.png" .. cable_entry,
		"helical_railgun_top_bottom.png",
		"helical_railgun_top_bottom.png",
	},
	is_th               = false,
	range               =  0 *       range_factor,
	storage_require_mod =  1.5,
	intensity           =  8 *   intensity_factor,
	damage              =  6 *      damage_factor,
	timeout             = 20 *     timeout_factor,
	speed               = 27 *       speed_factor,
	penetration         =  8 * penetration_factor,
	ingredient          = "ialazor:cannon_purple"
})
