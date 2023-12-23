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

--function bullet_first_step(object)
--        local pos = object:get_pos()
--
--            local beam_pos = {x = pos.x, y = pos.y, z = pos.z}
--	    local beam_vel = object:get_velocity()
--	    assert(beam_vel ~= nil)
--
--	    local node_rotation = minetest.dir_to_facedir(beam_vel, true)
--	    assert(node_rotation ~= nil)
--            local next_pos = vector.add(beam_pos, beam_vel)
--	    assert(next_pos ~= nil)
--
--	    --local prev_pos = self._prev_pos
--	    --if prev_pos ~= nil then
--	    --	minetest.after(2, minetest.forceload_free_block, prev_pos, true)
--            --end
--	    --self._prev_pos = pos
--	    minetest.forceload_block(next_pos, true)
--
--	    minetest.set_node(next_pos, {name="ialazor:light_"..def.color, param2 = node_rotation })
--
--	    beam_vel = vector.multiply(beam_vel, 0.1)
--end


ialazor.fire = function(pos, playername, color, speed, is_th, storage_require_mod)
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
	obj:set_velocity({x=dir.x*speed, y=dir.y*speed, z=dir.z*speed})
	--bullet_first_step(obj)
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

local function perimeter(range, cond)
	local result = {}
	if range == 0 then
		table.insert(result, {x=0, y=0, z=0})
		return result
	end

	for x=-range,range do
		local miny, maxy, minz, maxz
		if x == -range or x == range then
			miny = -range
			maxy =  range
			minz = -range
			maxz =  range
		else
			miny = -range+1
			maxy =  range-1
			minz = -range+1
			maxz =  range-1
		end
		for y=miny,maxy do
			for z=minz,maxz do
				local np = {x=x, y=y, z=z}
				if cond(np, range) then
					table.insert(result, np)
				end
			end
		end
	end

	for y=-range,range do
		local minx, maxx, minz, maxz
		if y == -range or y == range then
			minx = -range
			maxx =  range
			minz = -range
			maxz =  range
		else
			minx = -range+1
			maxx =  range-1
			minz = -range+1
			maxz =  range-1
		end
		for x=minx,maxx do
			for z=minz,maxz do
				local np = {x=x, y=y, z=z}
				if cond(np, range) then
					table.insert(result, np)
				end
			end
		end
	end

	for z=-range,range do
		local minx, maxx, miny, maxy
		if z == -range or z == range then
			minx = -range
			maxx =  range
			miny = -range
			maxy =  range
		else
			minx = -range+1
			maxx =  range-1
			miny = -range+1
			maxy =  range-1
		end
		for x=minx,maxx do
			for y=miny,maxy do
				local np = {x=x, y=y, z=z}
				if cond(np, range) then
					table.insert(result, np)
				end
			end
		end
	end

	return result
end

local function within_range(dp, max_range)
    return dp.x*dp.x + dp.y*dp.y + dp.z*dp.z <= max_range
end
--local max_nodes_factor = 5
--local max_nodes = max_nodes_factor * max_nodes_factor * max_nodes_factor
-- destroy stuff in range
-- TODO: resilient material list
local function destroy_helper(pos, range, intensity, is_ir)
	local start = os.clock()
	local resum = nil

    local collided = ialazor.punch_parade(pos, range, nil)
    if collided then
	    print('destroy_helper() punch parade!')
    end

	if not ialazor.can_destroy(pos) then
		return
	end

	local particle_texture = nil
	--local cur_nodes = 0

	local mr = range * range + range
	for _,dp in ipairs(perimeter(range, within_range)) do
	--for x=-range,range do
	--	local x2 = x*x
	--	for y=-range,range do
	--		local y2   = y*y
	--		local x2y2 = x2 + y2
	--		for z=-range,range do
	--			--if is_ir or x*x+y*y+z*z <= range * range + range then
	--			if is_ir or x2y2+z*z <= mr then
				--if --is_ir or
				--   dp.x*dp.x + dp.y*dp.y + dp.z*dp.z <= mr then
					local np={x=pos.x+dp.x,y=pos.y+dp.y,z=pos.z+dp.z}

					if minetest.is_protected(np, "") then
						return -- fail fast
					end

					local n = minetest.get_node_or_nil(np)

					if  n and n.name ~= "air"
					--and n.name ~= "ialazor:explosion"
					then
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
									if math.random(5 * 10 * 10 * 10) == 0 then
										-- chance drop
										minetest.add_item(np, itemname)
									end
								end
							end
						end

					end
						--if cur_nodes == max_nodes then
							local leave = os.clock()
							local total = leave - start

						if (resum == nil and total         > 1)
						or (resum ~= nil and leave - resum > 1) then
	local radius = range
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
				--glow = 5
				glow = minetest.LIGHT_MAX,
		})
	end

	minetest.sound_play("tnt_explode", {pos = pos, gain = 1.5, max_hear_distance = math.min(radius * 20, 128)})

							print('destroy_helper('..range..')[yield]: '..total)

							--cur_nodes = 0
							coroutine.yield()
							local new_resum = os.clock()
							if resum ~= nil then
								print('destroy_helper('..range..')[resum]: '..(new_resum - resum))
							end
							resum = new_resum
						--else
						--	cur_nodes = cur_nodes + 1
						end
					--end
		--		end
		--	end
		--end
		--end
	end


	local leave = os.clock()
	local total = leave - start
	print('destroy_helper('..range..')[done]: '..total)
end

local function prune_dead(cos)
    for i=#cos,1,-1 do
        local co     = cos[i]
        local status = coroutine.status(co)
        if status == "dead" then
            table.remove(cos, i)
        end
	coroutine.resume(co)
	return #cos -- only resume one
    end
    return #cos
end

local function get_mapblocks_within_radius(pos, range)
    local mapblock_size = 16
    local mapblocks = {}

    local min_x = math.floor((pos.x - range) / mapblock_size)
    local min_y = math.floor((pos.y - range) / mapblock_size)
    local min_z = math.floor((pos.z - range) / mapblock_size)

    local max_x = math.floor((pos.x + range) / mapblock_size)
    local max_y = math.floor((pos.y + range) / mapblock_size)
    local max_z = math.floor((pos.z + range) / mapblock_size)

    for x = min_x, max_x do
        for y = min_y, max_y do
            for z = min_z, max_z do
                local mapblock_pos = {x = x, y = y, z = z}
                table.insert(mapblocks, mapblock_pos)
            end
        end
    end

    return mapblocks
end

ialazor.punch_parade = function(pos, radius, puncher)
            local objs = minetest.get_objects_inside_radius({x=pos.x,y=pos.y,z=pos.z}, radius)
            local collided = false
            for _, obj in pairs(objs) do
                if (obj:is_player() or (obj:get_luaentity() ~= nil
                    and (puncher == nil or obj:get_luaentity().name ~= puncher.name)
                    and obj:get_luaentity().name ~= "__builtin:item"))
                        and ialazor.can_damage(obj)
                then
                    collided = true
		    local pobj = nil
		    if puncher ~= nil then pobj = puncher.obj end
                    obj:punch(pobj, 1.0, {
                        full_punch_interval=1.0,
                        damage_groups={fleshy=def.damage},
                    }, nil)
                end
            end
	return collided
end

local function destruction_manager(pos, range, cos)
    local mapblocks = get_mapblocks_within_radius(pos, range)
    for _, mapblock_pos in ipairs(mapblocks) do
    	minetest.forceload_block(mapblock_pos, true)
    end

    --local collided = ialazor.punch_parade(pos, range, nil)
    --if collided then
--	    print('destruction_manager() punch parade!')
    --end

    if prune_dead(cos) == 0 then
	print('destruction_manager() done')
        for _, mapblock_pos in ipairs(mapblocks) do
            minetest.forceload_free_block(mapblock_pos, true)
        end
        return
    end

    local radius = range
    local pause  = 0.1
    -- https://github.com/minetest/minetest_game/blob/master/mods/tnt/init.lua
    minetest.add_particlespawner({
            amount = 64,
            time = pause,
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
            --glow = 5
            glow = minetest.LIGHT_MAX,
    })

    minetest.after(pause, destruction_manager, pos, range, cos)
end

-- TODO it may be better to restart the inner radii periodically
function ialazor.destroy(pos, range, intensity)
    local cos = {}
    local ir = range / math.sqrt(2)
    for r=range,1,-1 do
	local co = coroutine.create(function()
            coroutine.yield()
            destroy_helper(pos, r, intensity, r <= ir)
        end)
	table.insert(cos, co)
    end

    destruction_manager(pos, range, cos)


    --minetest.set_node(pos, {name="ialazor:explosion"})
    --local meta = minetest.get_meta(pos)
    --meta:set_int("range",             1)
    --meta:set_int("radius",        range)
    --meta:set_int("intensity", intensity)
end

minetest.register_node("ialazor:explosion", {
    description = "Unreasonably Large Explosion",
    drawtype = "airlike",
    --tiles = { "blank.png", },
    --color = def.color,
    paramtype = "light",
    --paramtype2 = "facedir",
    sunlight_propagates = true,
    light_source = minetest.LIGHT_MAX,
    walkable = false,
    pointable = false,
    diggable = false,
    buildable_to = true,
    floodable = false,
    drop = "",
    groups = {beacon_light = 1, not_in_creative_inventory = 1},
    damage_per_second = 100,
    color             = "yellow",
    post_effect_color = "yellow",
    on_blast = function() end,
    on_construct = function(pos)
        minetest.get_node_timer(pos):start(1)
    end,
    on_timer = function(pos)
	local meta      = minetest.get_meta(pos)
	local range     = meta:get_int("range")  -- current range
	local intensity = meta:get_int("intensity")
	local radius    = meta:get_int("radius") -- max     range
	if range > radius then
	    minetest.remove_node(pos)
	    return false
        end
        local start = os.clock()

        destroy_helper(pos, range, intensity)
        meta:set_int("range", range + 1)

        local leave = os.clock()
        local total = leave - start
        print('explosion iteration took '..total)

        return true
    end,
})










