local power_factor = 1000

local colors = {"green", "blue", "red",}
for _,color in ipairs(colors) do
	local name   = "adv_lightsabers:kyber_crystal_"..color
	local def    = minetest.registered_items[name]
	local groups = table.copy(def.groups)
	assert(groups ~= nil)
	groups.kyber_active = 1
	minetest.override_item(name, { groups=groups, })
end

ialazor = {
	config = {
		-- technic EU storage value
		th_powerstorage     = 10000 * power_factor,
		ki_powerstorage     =   300 * power_factor,

		-- charge value in EU
		th_powerrequirement = 2500 * power_factor,
		ki_powerrequirement =  300 * power_factor,
	},
	node_resilience = {}
}

local MP = minetest.get_modpath("ialazor")

dofile(MP.."/util.lua")
dofile(MP.."/digiline.lua")
dofile(MP.."/cannon.lua")
dofile(MP.."/ammo.lua")
dofile(MP.."/node_resilience.lua")

print("[OK] IA Lazor")

