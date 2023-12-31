-- vi: noexpandtab

local has_digilines = minetest.get_modpath("digilines")

ialazor.update_formspec = function(meta, is_th)
	local formspec = ""

	if not is_th then
		formspec = formspec ..
			"formspec_version[4]" ..
			"size[10.5,9;]"

		-- Ammo inventory
		formspec = formspec ..
			"list[current_name;src;0.375,0.5;1,1;]" ..
			"list[current_player;main;0.375,4;8,4;]" ..
			"listring[]" ..
			"item_image[0.375,0.5;1,1;ialazor:coilgun_slug]" ..
			"label[1.75,1;Ammunition]"

		-- Manual "fire" button
		formspec = formspec ..
			"button_exit[5.125,0.5;5,1;fire;Fire]"

		-- Digiline channel
		if has_digilines then
			local channel = meta:get_string("channel") or ""
			formspec = formspec ..
				"field[0.375,2.375;4,1;digiline_channel;Digiline Channel;" .. channel .. "]" ..
				"button_exit[4.5,2.375;1,1;set_digiline_channel;Set]"
		end
	else
		formspec = formspec .. "formspec_version[4]"

		if has_digilines then
			formspec = formspec .. "size[6,4;]"
		else
			formspec = formspec .. "size[6,2;]"
		end

		-- Manual "fire" button
		formspec = formspec ..
			"button_exit[0.5,0.5;5,1;fire;Fire]"

		-- Digiline channel
		if has_digilines then
			local channel = meta:get_string("channel") or ""
			formspec = formspec ..
				"field[0.5,2.5;3.5,1;digiline_channel;Digiline Channel;" .. channel .. "]" ..
				"button_exit[4.5,2.5;1,1;set_digiline_channel;Set]"
		end
	end

	meta:set_string("formspec", formspec)
end

ialazor.can_shoot = function()
	-- arguments: pos, playername
	return true
end

ialazor.can_destroy = function()
	-- arguments: pos
	return true
end

ialazor.can_damage = function(_obj)
	return true
end

ialazor.fire_2 = function(pos, playername, color, speed, is_th, storage_require_mod)
	if not ialazor.can_shoot(pos, playername) then
		return
	end

	-- check fuel/power
	local meta = minetest.get_meta(pos)

	local config_store = ialazor.config.ki_powerstorage * storage_require_mod
	if is_th then config_store = ialazor.config.th_powerstorage * storage_require_mod end

	if meta:get_int("powerstorage") < config_store then
		-- not enough power
		return
	end

	-- check ammunition
	if not is_th then
		local inv = meta:get_inventory()
		if inv:is_empty("src") then
			--minetest.chat_send_player(playername, "No ammunition loaded!")
			return false
		end
		local src_stack = inv:get_list("src")[1]
		if not src_stack or src_stack:get_name() ~= "ialazor:coilgun_slug" then
			--minetest.chat_send_player(playername, "Incorrect ammunition!")
			return
		end
	end

	-- use power
	meta:set_int("powerstorage", 0)

	-- use ammo
	if not is_th then
		local src_stack = meta:get_inventory():get_list("src")[1]
		src_stack:take_item();
		meta:get_inventory():set_stack("src", 1, src_stack)
	end

	minetest.sound_play("spacecannon_shoot", {
		pos = pos,
		gain = 1.0,
		max_hear_distance = 16
	})

	local node = minetest.get_node(pos)
	local dir = ialazor.facedir_to_down_dir(node.param2)
	local obj = minetest.add_entity({x=pos.x+dir.x, y=pos.y+dir.y, z=pos.z+dir.z}, "ialazor:energycube_" .. color)
	obj:setvelocity({x=dir.x*speed, y=dir.y*speed, z=dir.z*speed})
end

-- destroy stuff in range
-- TODO: resilient material list
ialazor.destroy_2 = function(pos, range, intensity)

	if not ialazor.can_destroy(pos) then
		return
	end

	local particle_texture = nil

	for x=-range,range do
		for y=-range,range do
			for z=-range,range do
				if x*x+y*y+z*z <= range * range + range then
					local np={x=pos.x+x,y=pos.y+y,z=pos.z+z}

					if minetest.is_protected(np, "") then
						return -- fail fast
					end

					local n = minetest.get_node_or_nil(np)

					if n and n.name ~= "air" then
						local node_def = minetest.registered_nodes[n.name]

						if node_def and node_def.tiles and node_def.tiles[1] then
							particle_texture = node_def.tiles[1]
						end

						if node_def.on_blast then
							-- custom on_blast
							node_def.on_blast(np, intensity)

						else
							-- default behavior
							local resilience = ialazor.node_resilience[n.name] or 1
							if resilience <= 1 or math.random(resilience) == resilience then
								minetest.set_node(np, {name="air"})
								local itemstacks = minetest.get_node_drops(n.name)
								for _, itemname in ipairs(itemstacks) do
									if math.random(5) == 5 * range * range * range then
										-- chance drop
										minetest.add_item(np, itemname)
									end
								end
							end
						end

					end
				end
			end
		end
	end

	local radius = range

	-- https://github.com/minetest/minetest_game/blob/master/mods/tnt/init.lua
	minetest.add_particlespawner({
			amount = 64,
			time = 0.5,
			minpos = vector.subtract(pos, radius / 2),
			maxpos = vector.add(pos, radius / 2),
			minvel = {x = -10, y = -10, z = -10},
			maxvel = {x = 10, y = 10, z = 10},
			minacc = vector.new(),
			maxacc = vector.new(),
			minexptime = 1,
			maxexptime = 2.5,
			minsize = radius * 3,
			maxsize = radius * 5,
			texture = "spacecannon_spark.png",
			glow = 5
	})

	if particle_texture then
		minetest.add_particlespawner({
				amount = 64,
				time = 0.5,
				minpos = vector.subtract(pos, radius / 2),
				maxpos = vector.add(pos, radius / 2),
				minvel = {x = -10, y = -10, z = -10},
				maxvel = {x = 10, y = 10, z = 10},
				minacc = vector.new(),
				maxacc = vector.new(),
				minexptime = 1,
				maxexptime = 2.5,
				minsize = radius * 3,
				maxsize = radius * 5,
				texture = particle_texture,
				glow = 5
		})
	end

	minetest.sound_play("tnt_explode", {pos = pos, gain = 1.5, max_hear_distance = math.min(radius * 20, 128)})

end


-- convert face dir to vector
ialazor.facedir_to_down_dir = function(facing)
	return (
		{[0]={x=0, y=-1, z=0},
		{x=0, y=0, z=-1},
		{x=0, y=0, z=1},
		{x=-1, y=0, z=0},
		{x=1, y=0, z=0},
		{x=0, y=1, z=0}})[math.floor(facing/4)]
end





















ialazor.fire_1 = function(pos, playername, color, speed, is_th, storage_require_mod)
	if not ialazor.can_shoot(pos, playername) then
		return
	end

	-- check fuel/power
	local meta = minetest.get_meta(pos)

	local config_store = ialazor.config.ki_powerstorage * storage_require_mod
	if is_th then config_store = ialazor.config.th_powerstorage * storage_require_mod end

	if meta:get_int("powerstorage") < config_store then
		-- not enough power
		return
	end

	-- check ammunition
	if not is_th then
		local inv = meta:get_inventory()
		if inv:is_empty("src") then
			--minetest.chat_send_player(playername, "No ammunition loaded!")
			return false
		end
		local src_stack = inv:get_list("src")[1]
		if not src_stack or src_stack:get_name() ~= "ialazor:coilgun_slug" then
			--minetest.chat_send_player(playername, "Incorrect ammunition!")
			return
		end
	end

	-- use power
	meta:set_int("powerstorage", 0)

	-- use ammo
	if not is_th then
		local src_stack = meta:get_inventory():get_list("src")[1]
		src_stack:take_item();
		meta:get_inventory():set_stack("src", 1, src_stack)
	end

	minetest.sound_play("spacecannon_shoot", {
		pos = pos,
		gain = 1.0,
		max_hear_distance = 16
	})

	-- TODO fire lazer beam
	local node = minetest.get_node(pos)
	local dir = ialazor.facedir_to_down_dir(node.param2)
	local obj = minetest.add_entity({x=pos.x+dir.x, y=pos.y+dir.y, z=pos.z+dir.z}, "ialazor:energycube_" .. color)
	obj:setvelocity({x=dir.x*speed, y=dir.y*speed, z=dir.z*speed})
end

-- destroy stuff in range
-- TODO: resilient material list
ialazor.destroy_1 = function(pos, range, intensity)

	if not ialazor.can_destroy(pos) then
		return
	end

	local particle_texture = nil

	local step = 10
	local k    = 1
	print('range: '..range)
	print('step : '..step)
	print('iter : '..(range / step))

	ialazor.destroy_2(pos, step, intensity)

	--local step2 = step
	--local step2 = step / 2
	local step2 = math.sqrt(step)
	local I = math.ceil(range / step2)

	for i=1,I do
		for dx=-1,1 do
			for dy=-1,1 do
				for dz=-1,1 do
					if dx ~= 0 or dy ~= 0 or dz ~= 0 then
						local n = i * step2
						local np={x=pos.x+dx*n,y=pos.y+dy*n,z=pos.z+dz*n}
						print('n : '..n)
						print('dx: '..dx)
						print('dy: '..dy)
						print('dz: '..dz)
						print('np: '..dump(np))
						minetest.after(k, ialazor.destroy_2, np, step, intensity)
						k = k + 1
					end
				end
			end
		end
	end
end


































































ialazor.fire_3 = function(pos, playername, color, speed, is_th, storage_require_mod)
	if not ialazor.can_shoot(pos, playername) then
		return
	end

	-- check fuel/power
	local meta = minetest.get_meta(pos)

	local config_store = ialazor.config.ki_powerstorage * storage_require_mod
	if is_th then config_store = ialazor.config.th_powerstorage * storage_require_mod end

	if meta:get_int("powerstorage") < config_store then
		-- not enough power
		return
	end

	-- check ammunition
	if not is_th then
		local inv = meta:get_inventory()
		if inv:is_empty("src") then
			--minetest.chat_send_player(playername, "No ammunition loaded!")
			return false
		end
		local src_stack = inv:get_list("src")[1]
		if not src_stack or src_stack:get_name() ~= "ialazor:coilgun_slug" then
			--minetest.chat_send_player(playername, "Incorrect ammunition!")
			return
		end
	end

	-- use power
	meta:set_int("powerstorage", 0)

	-- use ammo
	if not is_th then
		local src_stack = meta:get_inventory():get_list("src")[1]
		src_stack:take_item();
		meta:get_inventory():set_stack("src", 1, src_stack)
	end

	minetest.sound_play("spacecannon_shoot", {
		pos = pos,
		gain = 1.0,
		max_hear_distance = 16
	})

	local node = minetest.get_node(pos)
	local dir = ialazor.facedir_to_down_dir(node.param2)
	local obj = minetest.add_entity({x=pos.x+dir.x, y=pos.y+dir.y, z=pos.z+dir.z}, "ialazor:fireenergycube_" .. color)
	obj:setvelocity({x=dir.x*speed, y=dir.y*speed, z=dir.z*speed})
end

-- destroy stuff in range
-- TODO: resilient material list
ialazor.destroy_3 = function(pos, range, intensity)

	if not ialazor.can_destroy(pos) then
		return
	end

	local particle_texture = nil

	local minp  = {x=pos.x-range,y=pos.y-range,z=pos.z-range}
	local maxp  = {x=pos.x+range,y=pos.y+range,z=pos.z+range}
	--local nodes, _ = minetest.find_nodes_in_area_under_air(minp, maxp, {"air",})
	--local nodes, _ = minetest.find_nodes_in_area_under_air(minp, maxp, {
	local nodes, _ = minetest.find_nodes_in_area(minp, maxp, {
		"group:flammable",
		"group:tree", "group:leafdecay", "group:flora",
		"group:soil",
		"group:wood","group:leaves",
	})
	for _, np in ipairs(nodes) do
		local npp = {x=np.x, y=np.y+1, z=np.z}
		minetest.set_node(npp, {name="fire:basic_flame",})
	end
	
	local nodes, _ = minetest.find_nodes_in_area(minp, maxp, {"default:snow","default:ice",})
	for _, np in ipairs(nodes) do
		minetest.set_node(np, {name="default:water_flowing",})
	end

	local nodes, _ = minetest.find_nodes_in_area(minp, maxp, {"group:water",})
	for _, np in ipairs(nodes) do
		minetest.set_node(np, {name="default:lava_flowing",})
	end

	local nodes, _ = minetest.find_nodes_in_area(minp, maxp, {"group:soil",})
	for _, np in ipairs(nodes) do
		minetest.set_node(np, {name="default:dry_dirt",})
	end

	local nodes, _ = minetest.find_nodes_in_area(minp, maxp, {"group:sand",})
	for _, np in ipairs(nodes) do
		minetest.set_node(np, {name="default:glass",})
	end

	local nodes, _ = minetest.find_nodes_in_area(minp, maxp, {"default:cobble","default:mossycobble","default:gravel",})
	for _, np in ipairs(nodes) do
		minetest.set_node(np, {name="default:stone",})
	end
	
	local radius = range

	minetest.add_particlespawner({
			amount = 64,
			time = 0.5,
			minpos = vector.subtract(pos, radius / 2),
			maxpos = vector.add(pos, radius / 2),
			minvel = {x = -10, y = -10, z = -10},
			maxvel = {x = 10, y = 10, z = 10},
			minacc = vector.new(),
			maxacc = vector.new(),
			minexptime = 1,
			maxexptime = 2.5,
			minsize = radius * 3,
			maxsize = radius * 5,
			texture = "fire_basic_flame.png",
			glow = 5
	})

	-- TODO other particle texture ?

	minetest.sound_play("tnt_explode", {pos = pos, gain = 1.5, max_hear_distance = math.min(radius * 20, 128)})
end

ialazor.destroy_4 = function(pos, range, intensity)

	if not ialazor.can_destroy(pos) then
		return
	end

	local particle_texture = nil

	--local step = 10
	local step = 20
	local k    = 1
	print('range: '..range)
	print('step : '..step)
	print('iter : '..(range / step))

	ialazor.destroy_3(pos, step, intensity)

	local step2 = step
	--local step2 = step / 2
	--local step2 = math.sqrt(step)
	local I = math.ceil(range / step2)

	for i=1,I do
		for dx=-1,1 do
			for dy=-1,1 do
				for dz=-1,1 do
					if dx ~= 0 or dy ~= 0 or dz ~= 0 then
						local n = i * step2
						local np={x=pos.x+dx*n,y=pos.y+dy*n,z=pos.z+dz*n}
						print('n : '..n)
						print('dx: '..dx)
						print('dy: '..dy)
						print('dz: '..dz)
						print('np: '..dump(np))
						minetest.after(k, ialazor.destroy_3, np, step, intensity)
						k = k + 1
					end
				end
			end
		end
	end
end





























ialazor.fire_4 = function(pos, playername, color, speed, is_th, storage_require_mod)
	if not ialazor.can_shoot(pos, playername) then
		return
	end

	-- check fuel/power
	local meta = minetest.get_meta(pos)

	local config_store = ialazor.config.ki_powerstorage * storage_require_mod
	if is_th then config_store = ialazor.config.th_powerstorage * storage_require_mod end

	if meta:get_int("powerstorage") < config_store then
		-- not enough power
		return
	end

	-- check ammunition
	if not is_th then
		local inv = meta:get_inventory()
		if inv:is_empty("src") then
			--minetest.chat_send_player(playername, "No ammunition loaded!")
			return false
		end
		local src_stack = inv:get_list("src")[1]
		if not src_stack or src_stack:get_name() ~= "ialazor:coilgun_slug" then
			--minetest.chat_send_player(playername, "Incorrect ammunition!")
			return
		end
	end

	-- use power
	meta:set_int("powerstorage", 0)

	-- use ammo
	if not is_th then
		local src_stack = meta:get_inventory():get_list("src")[1]
		src_stack:take_item();
		meta:get_inventory():set_stack("src", 1, src_stack)
	end

	minetest.sound_play("spacecannon_shoot", {
		pos = pos,
		gain = 1.0,
		max_hear_distance = 16
	})

	local node = minetest.get_node(pos)
	local dir = ialazor.facedir_to_down_dir(node.param2)
	local obj = minetest.add_entity({x=pos.x+dir.x, y=pos.y+dir.y, z=pos.z+dir.z}, "ialazor:fireenergycube2_" .. color)
	obj:setvelocity({x=dir.x*speed, y=dir.y*speed, z=dir.z*speed})
end

-- destroy stuff in range
-- TODO: resilient material list
local air = "air"
local def = minetest.registered_nodes[air]
def = table.copy(def)
def.description = "Natural Gas" -- S("Natural Gas")
def.walkable = false
def.groups.flammable = 5
def.groups.air = 1
def.drowning = 1
def.color = "green"
def.post_effect_color = def.color
local MODNAME = minetest.get_current_modname()
minetest.register_node(MODNAME..":natural_gas", def)
minetest.register_abm({
	label = "Gas Leak",
	nodenames = {MODNAME..":natural_gas",},
	neighbors = {"group:igniter",},
	interval = 1.0,
	chance = 1,
	--catchup = true,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local range     = 10
		local intensity = 10
		ialazor.destroy_1(pos, range, intensity)
	end,
})
ialazor.destroy_5 = function(pos, range, intensity)

	if not ialazor.can_destroy(pos) then
		return
	end

	local particle_texture = nil

	local minp  = {x=pos.x-range,y=pos.y-range,z=pos.z-range}
	local maxp  = {x=pos.x+range,y=pos.y+range,z=pos.z+range}
	local nodes, _ = minetest.find_nodes_in_area(minp, maxp, {"air",})
	for _, np in ipairs(nodes) do
		minetest.set_node(np, {name="ialazor:natural_gas",})
	end
	
	local nodes, _ = minetest.find_nodes_in_area(minp, maxp, {"default:snow","default:ice",})
	for _, np in ipairs(nodes) do
		minetest.set_node(np, {name="default:water_flowing",})
	end

	local nodes, _ = minetest.find_nodes_in_area(minp, maxp, {"group:water",})
	for _, np in ipairs(nodes) do
		minetest.set_node(np, {name="default:lava_flowing",})
	end

	local nodes, _ = minetest.find_nodes_in_area(minp, maxp, {"group:stone",})
	for _, np in ipairs(nodes) do
		minetest.set_node(np, {name="default:lava_source",})
	end

	
	local radius = range

	minetest.add_particlespawner({
			amount = 64,
			time = 0.5,
			minpos = vector.subtract(pos, radius / 2),
			maxpos = vector.add(pos, radius / 2),
			minvel = {x = -10, y = -10, z = -10},
			maxvel = {x = 10, y = 10, z = 10},
			minacc = vector.new(),
			maxacc = vector.new(),
			minexptime = 1,
			maxexptime = 2.5,
			minsize = radius * 3,
			maxsize = radius * 5,
			texture = "fire_basic_flame.png",
			glow = 5
	})

	-- TODO other particle texture ?

	minetest.sound_play("tnt_explode", {pos = pos, gain = 1.5, max_hear_distance = math.min(radius * 20, 128)})
end




