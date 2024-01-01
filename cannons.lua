local MP = minetest.get_modpath("ialazor")
local cannon = dofile(MP.."/cannon.lua")
local cable_entry = "^technic_cable_connection_overlay.png"

local       range_factor =   10
local     timeout_factor = 1000
local      damage_factor =  100
local   intensity_factor =  100
local       speed_factor =    2
local penetration_factor =   10

cannon.register_spacecannon_1({
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

cannon.register_spacecannon_1({
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

cannon.register_spacecannon_1({
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

--      range_factor =   10
--    timeout_factor =   1000
--     damage_factor =   10
--  intensity_factor =   10
--      speed_factor =    2
--penetration_factor =  100

-- Regular railgun
cannon.register_spacecannon_2({
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
cannon.register_spacecannon_2({
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
cannon.register_spacecannon_2({
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
	storage_require_mod =  2,
	intensity           =  8 *   intensity_factor,
	damage              =  6 *      damage_factor,
	timeout             = 20 *     timeout_factor,
	speed               = 11 *       speed_factor,
	penetration         =  8 * penetration_factor,
	ingredient          = "ialazor:cannon_purple"
})
