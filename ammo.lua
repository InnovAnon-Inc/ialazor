minetest.register_craftitem("ialazor:coilgun_slug", {
	description = "Coilgun slug",
    inventory_image = "spacecannon_railgun_slug.png", -- TODO distinct image
})

minetest.register_craft({
	output = "ialazor:coilgun_slug 2",
	recipe = {
        {                                "",            "group:kyber_active",                                 ""},
        {"basic_materials:carbon_steel_bar", "technic:stainless_steel_ingot", "basic_materials:carbon_steel_bar"},
        {   "technic:stainless_steel_ingot", "technic:stainless_steel_ingot",    "technic:stainless_steel_ingot"}
	},
})
