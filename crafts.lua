--Code : GPL v3
--Textures : CC-BY-SA 4.0
--Sounds : CC-BY-SA 4.0

--Firedamp bubble

minetest.register_craft({
	type = "fuel",
	recipe = "group:bubble",
	burntime = 50,
})

minetest.register_craft({
	output = "firedamp:firedamp_bubble_white 3",
	type = "shapeless",
	recipe = { "firedamp:firedamp_bubble_red", "firedamp:firedamp_bubble_green", "firedamp:firedamp_bubble_blue" }
})

minetest.register_craft({
	output = "firedamp:firedamp_bubble_cyan 2",
	type = "shapeless",
	recipe = { "firedamp:firedamp_bubble_green", "firedamp:firedamp_bubble_blue"}
})

minetest.register_craft({
	output = "firedamp:firedamp_bubble_magenta 2",
	type = "shapeless",
	recipe = { "firedamp:firedamp_bubble_red", "firedamp:firedamp_bubble_blue" }
})

minetest.register_craft({
	output = "firedamp:firedamp_bubble_yellow 2",
	type = "shapeless",
	recipe = {"firedamp:firedamp_bubble_red", "firedamp:firedamp_bubble_green" }
})

--gaz cylinder

minetest.register_craft( {
	output = "firedamp:gas_cylinder_empty",
	recipe = {
		{ "", "", "" },
		{ "", "", "" },
		{ "vessels:steel_bottle", "dye:blue", "" }
	}
})

minetest.register_craft( {
	output = "firedamp:gas_cylinder",
	recipe = {
		{ "group:bubble", "group:bubble", "group:bubble" },
		{ "group:bubble", "group:bubble", "group:bubble" },
		{ "group:bubble", "firedamp:gas_cylinder_empty", "group:bubble" }
	}
})

minetest.register_craft({
	type = "fuel",
	recipe = "firedamp:gas_cylinder",
	burntime = 400,
	replacements = {{"firedamp:gas_cylinder", "firedamp:rusty_gas_cylinder"}}, -- cylinder and bootle aren't homogeneous...
})

--recycling

minetest.register_craft({
	type = 'cooking',
	cooktime = 5,
	output = 'default:steel_ingot 1',
	recipe = 'firedamp:rusty_gas_cylinder',	
})

--light

minetest.register_craft({
	output = "firedamp:lamp_white 4",
	recipe = {
{ "", "default:glass", "" },
{ "default:glass", "firedamp:firedamp_bubble_white", "default:glass" },
{ "", "default:mese_crystal_fragment", "" },
	}
})

minetest.register_craft({
	output = "firedamp:lamp_red 4",
	recipe = {
{ "", "default:glass", "" },
{ "default:glass", "firedamp:firedamp_bubble_red", "default:glass" },
{ "", "default:mese_crystal_fragment", "" },
	}
})

minetest.register_craft({
	output = "firedamp:lamp_green 4",
	recipe = {
{ "", "default:glass", "" },
{ "default:glass", "firedamp:firedamp_bubble_green", "default:glass" },
{ "", "default:mese_crystal_fragment", "" },
	}
})

minetest.register_craft({
	output = "firedamp:lamp_blue 4",
	recipe = {
{ "", "default:glass", "" },
{ "default:glass", "firedamp:firedamp_bubble_blue", "default:glass" },
{ "", "default:mese_crystal_fragment", "" },
	}
})

minetest.register_craft({
	output = "firedamp:lamp_cyan 4",
	recipe = {
{ "", "default:glass", "" },
{ "default:glass", "firedamp:firedamp_bubble_cyan", "default:glass" },
{ "", "default:mese_crystal_fragment", "" },
	}
})

minetest.register_craft({
	output = "firedamp:lamp_magenta 4",
	recipe = {
{ "", "default:glass", "" },
{ "default:glass", "firedamp:firedamp_bubble_magenta", "default:glass" },
{ "", "default:mese_crystal_fragment", "" },
	}
})

minetest.register_craft({
	output = "firedamp:lamp_yellow 4",
	recipe = {
{ "", "default:glass", "" },
{ "default:glass", "firedamp:firedamp_bubble_yellow", "default:glass" },
{ "", "default:mese_crystal_fragment", "" },
	}
})

--Neon

minetest.register_craft({
	output = "firedamp:neon_white 6",
	recipe = {
{ "default:glass", "default:mese_crystal_fragment", "default:glass" },
{ "default:glass", "firedamp:firedamp_bubble_white", "default:glass" },
{ "default:glass", "default:mese_crystal_fragment", "default:glass" },
	}
})

minetest.register_craft({
	output = "firedamp:neon_red 6",
	recipe = {
{ "default:glass", "default:mese_crystal_fragment", "default:glass" },
{ "default:glass", "firedamp:firedamp_bubble_white", "default:glass" },
{ "default:glass", "default:mese_crystal_fragment", "default:glass" },
	}
})

minetest.register_craft({
	output = "firedamp:neon_green 6",
	recipe = {
{ "default:glass", "default:mese_crystal_fragment", "default:glass" },
{ "default:glass", "firedamp:firedamp_bubble_white", "default:glass" },
{ "default:glass", "default:mese_crystal_fragment", "default:glass" },
	}
})

minetest.register_craft({
	output = "firedamp:neon_blue 6",
	recipe = {
{ "default:glass", "default:mese_crystal_fragment", "default:glass" },
{ "default:glass", "firedamp:firedamp_bubble_white", "default:glass" },
{ "default:glass", "default:mese_crystal_fragment", "default:glass" },
	}
})

minetest.register_craft({
	output = "firedamp:neon_cyan 6",
	recipe = {
{ "default:glass", "default:mese_crystal_fragment", "default:glass" },
{ "default:glass", "firedamp:firedamp_bubble_white", "default:glass" },
{ "default:glass", "default:mese_crystal_fragment", "default:glass" },
	}
})

minetest.register_craft({
	output = "firedamp:neon_magenta 6",
	recipe = {
{ "default:glass", "default:mese_crystal_fragment", "default:glass" },
{ "default:glass", "firedamp:firedamp_bubble_white", "default:glass" },
{ "default:glass", "default:mese_crystal_fragment", "default:glass" },
	}
})

minetest.register_craft({
	output = "firedamp:neon_yellow 6",
	recipe = {
{ "default:glass", "default:mese_crystal_fragment", "default:glass" },
{ "default:glass", "firedamp:firedamp_bubble_yellow", "default:glass" },
{ "default:glass", "default:mese_crystal_fragment", "default:glass" },
	}
})

--slap

minetest.register_craft({
	output = "firedamp:slap_light_white",
	recipe = {
{ "", "", "" },
{ "", "", "" },
{ "firedamp:neon_white", "firedamp:neon_white", "firedamp:neon_white" },
	}
})

minetest.register_craft({
	output = "firedamp:slap_light_red",
	recipe = {
{ "", "", "" },
{ "", "", "" },
{ "firedamp:neon_red", "firedamp:neon_red", "firedamp:neon_red" },
	}
})

minetest.register_craft({
	output = "firedamp:slap_light_blue",
	recipe = {
{ "", "", "" },
{ "", "", "" },
{ "firedamp:neon_blue", "firedamp:neon_blue", "firedamp:neon_blue" },
	}
})

minetest.register_craft({
	output = "firedamp:slap_light_green",
	recipe = {
{ "", "", "" },
{ "", "", "" },
{ "firedamp:neon_green", "firedamp:neon_green", "firedamp:neon_green" },
	}
})

minetest.register_craft({
	output = "firedamp:slap_light__cyan",
	recipe = {
{ "", "", "" },
{ "", "", "" },
{ "firedamp:neon_cyan", "firedamp:neon_cyan", "firedamp:neon_cyan" },
	}
})

minetest.register_craft({
	output = "firedamp:slap_light__magenta",
	recipe = {
{ "", "", "" },
{ "", "", "" },
{ "firedamp:neon_magenta", "firedamp:neon_magenta", "firedamp:neon_magenta" },
	}
})

minetest.register_craft({
	output = "firedamp:slap_light__yellow",
	recipe = {
{ "", "", "" },
{ "", "", "" },
{ "firedamp:neon_yellow", "firedamp:neon_yellow", "firedamp:neon_yellow" },
	}
})
