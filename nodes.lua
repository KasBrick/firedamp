-- Code : GPL v3
-- Based on tnt mod of PilzAdam and ShadowNinja
-- Textures : CC-BY-SA 4.0
-- Sounds : CC-BY-SA 4.0

--firedamp block

-- loss probabilities array (one in X will be lost)
local loss_prob = {}

loss_prob["default:cobble"] = 3
loss_prob["default:dirt"] = 4

local radius = tonumber(minetest.setting_get("firedamp_radius") or 3)

-- Fill a list with data for content IDs, after all nodes are registered
local cid_data = {}
minetest.after(0, function()
	for name, def in pairs(minetest.registered_nodes) do
		cid_data[minetest.get_content_id(name)] = {
			name = name,
			drops = def.drops,
			flammable = def.groups.flammable,
			on_blast = def.on_blast,
		}
	end
end)

local function rand_pos(center, pos, radius)
	pos.x = center.x + math.random(-radius, radius)
	pos.z = center.z + math.random(-radius, radius)
end

local function eject_drops(drops, pos, radius)
	local drop_pos = vector.new(pos)
	for _, item in pairs(drops) do
		local count = item:get_count()
		local max = item:get_stack_max()
		if count > max then
			item:set_count(max)
		end
		while count > 0 do
			if count < max then
				item:set_count(count)
			end
			rand_pos(pos, drop_pos, radius)
			local obj = minetest.add_item(drop_pos, item)
			if obj then
				obj:get_luaentity().collect = true
				obj:setacceleration({x=0, y=-10, z=0})
				obj:setvelocity({x=math.random(-3, 3), y=10,
						z=math.random(-3, 3)})
			end
			count = count - max
		end
	end
end

local function add_drop(drops, item)
	item = ItemStack(item)
	local name = item:get_name()
	if loss_prob[name] ~= nil and math.random(1, loss_prob[name]) == 1 then
		return
	end

	local drop = drops[name]
	if drop == nil then
		drops[name] = item
	else
		drop:set_count(drop:get_count() + item:get_count())
	end
end

local fire_node = {name="fire:basic_flame"}

local function destroy(drops, pos, cid)
	if minetest.is_protected(pos, "") then
		return
	end
	local def = cid_data[cid]
	if def and def.on_blast then
		def.on_blast(vector.new(pos), 1)
		return
	end
	if def and def.flammable then
		minetest.set_node(pos, fire_node)
	else
		minetest.remove_node(pos)
		if def then
			local node_drops = minetest.get_node_drops(def.name, "")
			for _, item in ipairs(node_drops) do
				add_drop(drops, item)
			end
		end
	end
end


local function calc_velocity(pos1, pos2, old_vel, power)
	local vel = vector.direction(pos1, pos2)
	vel = vector.normalize(vel)
	vel = vector.multiply(vel, power)

	-- Divide by distance
	local dist = vector.distance(pos1, pos2)
	dist = math.max(dist, 1)
	vel = vector.divide(vel, dist)

	-- Add old velocity
	vel = vector.add(vel, old_vel)
	return vel
end

local function entity_physics(pos, radius)
	-- Make the damage radius larger than the destruction radius
	radius = radius * 2
	local objs = minetest.get_objects_inside_radius(pos, radius)
	for _, obj in pairs(objs) do
		local obj_pos = obj:getpos()
		local obj_vel = obj:getvelocity()
		local dist = math.max(1, vector.distance(pos, obj_pos))

		if obj_vel ~= nil then
			obj:setvelocity(calc_velocity(pos, obj_pos,
					obj_vel, radius * 10))
		end

		local damage = (2 / dist) * radius
		obj:set_hp(obj:get_hp() - damage)
	end
end

local function add_effects(pos, radius)
	minetest.add_particlespawner({
		amount = 128,
		time = 1,
		minpos = vector.subtract(pos, radius / 2),
		maxpos = vector.add(pos, radius / 2),
		minvel = {x=-20, y=-20, z=-20},
		maxvel = {x=20,  y=20,  z=20},
		minacc = vector.new(),
		maxacc = vector.new(),
		minexptime = 1,
		maxexptime = 3,
		minsize = 8,
		maxsize = 16,
		texture = "tnt_smoke.png",
	})
end

local function burn(pos)
	local name = minetest.get_node(pos).name
	if name == "firedamp:firedamp_block" then
		minetest.sound_play("firedamp_leak", {pos=pos, gain=1.5, max_hear_distance=2*64})
		minetest.set_node(pos, {name="firedamp:firedamp_block_burning"})
		minetest.get_node_timer(pos):start(1)
	end
end

local function explode(pos, radius)
	local pos = vector.round(pos)
	local vm = VoxelManip()
	local pr = PseudoRandom(os.time())
	local p1 = vector.subtract(pos, radius)
	local p2 = vector.add(pos, radius)
	local minp, maxp = vm:read_from_map(p1, p2)
	local a = VoxelArea:new({MinEdge = minp, MaxEdge = maxp})
	local data = vm:get_data()

	local drops = {}
	local p = {}

	local c_air = minetest.get_content_id("air")

	for z = -radius, radius do
	for y = -radius, radius do
	local vi = a:index(pos.x + (-radius), pos.y + y, pos.z + z)
	for x = -radius, radius do
		if (x * x) + (y * y) + (z * z) <=
				(radius * radius) + pr:next(-radius, radius) then
			local cid = data[vi]
			p.x = pos.x + x
			p.y = pos.y + y
			p.z = pos.z + z
			if cid ~= c_air then
				destroy(drops, p, cid)
			end
		end
		vi = vi + 1
	end
	end
	end

	return drops
end


local function boom(pos)
	minetest.sound_play("tnt_explode", {pos=pos, gain=1.5, max_hear_distance=2*64})
	minetest.set_node(pos, {name="firedamp:firedamp_boom"})
	minetest.get_node_timer(pos):start(0.5)

	local drops = explode(pos, radius)
	entity_physics(pos, radius)
	eject_drops(drops, pos, radius)
	add_effects(pos, radius)
end

minetest.register_node("firedamp:firedamp_block", {
	description = "Firedamp Block",
	tile_images = {"firedamp_block.png"},
	inventory_image = minetest.inventorycube("firedamp_block.png"),
	is_ground_content = false,
	groups = {cracky=3, stone=1, mesecon=2},
	sounds = default.node_sound_wood_defaults(),
	drop ={
		max_items = 2,
		items = {
			{items = {'firedamp:firedamp_bubble_red'}, rarity=2},
			{items = {'firedamp:firedamp_bubble_green'}, rarity=2},
			{items = {'firedamp:firedamp_bubble_blue'}, rarity=2},

		}
	},
	on_punch = function(pos, node, puncher)
		if puncher:get_wielded_item():get_name() == "default:torch" then
			minetest.sound_play("firedamp_leak", {pos=pos})
			minetest.set_node(pos, {name="firedamp:firedamp_block_burning"})
			minetest.get_node_timer(pos):start(1)
		end
		if puncher:get_wielded_item():get_name() == "default:pick_stone" then
			minetest.sound_play("firedamp_leak", {pos=pos})
			minetest.set_node(pos, {name="firedamp:firedamp_block_burning"})
			minetest.get_node_timer(pos):start(1)
		end
		if puncher:get_wielded_item():get_name() == "default:pick_steel" then
			minetest.sound_play("firedamp_leak", {pos=pos})
			minetest.set_node(pos, {name="firedamp:firedamp_block_burning"})
			minetest.get_node_timer(pos):start(1)
		end
		if puncher:get_wielded_item():get_name() == "default:pick_bronze" then
			minetest.sound_play("firedamp_leak", {pos=pos})
			minetest.set_node(pos, {name="firedamp:firedamp_block_burning"})
			minetest.get_node_timer(pos):start(1)
		end
		if puncher:get_wielded_item():get_name() == "default:pick_mese" then
			minetest.sound_play("firedamp_leak", {pos=pos})
			minetest.set_node(pos, {name="firedamp:firedamp_block_burning"})
			minetest.get_node_timer(pos):start(1)
		end
		if puncher:get_wielded_item():get_name() == "default:pick_diamond" then
			minetest.sound_play("firedamp_leak", {pos=pos})
			minetest.set_node(pos, {name="firedamp:firedamp_block_burning"})
			minetest.get_node_timer(pos):start(1)
		end
	end,
	on_blast = function(pos, intensity)
		burn(pos)
	end,
	mesecons = {effector = {action_on = boom}},
})

minetest.register_node("firedamp:firedamp_block_burning", {
	tile_images = {"firedamp_block.png"},
	light_source = 5,
	drop = "",
	sounds = default.node_sound_wood_defaults(),
	on_timer = boom,
	-- unaffected by explosions
	on_blast = function() end,
})

minetest.register_node("firedamp:firedamp_boom", {
	drawtype = "plantlike",
	tiles = {"tnt_boom.png"},
	light_source = default.LIGHT_MAX,
	walkable = false,
	drop = "",
	groups = {dig_immediate=3},
	on_timer = function(pos, elapsed)
		minetest.remove_node(pos)
	end,
	-- unaffected by explosions
	on_blast = function() end,
})

--gas cylinder

minetest.register_node("firedamp:gas_cylinder_empty", {
	description = "Gas Cylinder (Empty)",
	drawtype = 'nodebox',
	tiles = {"gas_cylinder.png"},
	inventory_image = "gas_cylinder_inv.png",
	paramtype = "light",
	paramtype2 = 'facedir',
	stack_max = 1,
	walkable = true,
	groups = {dig_immediate=3,attached_node=1},
	sounds = default.node_sound_stone_defaults(),
	node_box = {
		type = 'fixed',
		fixed = {
				{-0.4, -0.5, 0.2, 0.4, 0.2, -0.2}, -- NodeBox1
				{-0.2, -0.5, 0.4, 0.2, 0.2, -0.4}, -- NodeBox2
				{-0.3, -0.5, 0.3, 0.3, 0.3, -0.3}, -- NodeBox3
				{-0.1, 0.3, 0.1, 0.1, 0.5, -0.1}, -- NodeBox4
		}
	},
	selection_box = {
		type = 'fixed',
		fixed = {
				{-0.4, -0.5, 0.2, 0.4, 0.2, -0.2}, -- NodeBox1
				{-0.2, -0.5, 0.4, 0.2, 0.2, -0.4}, -- NodeBox2
				{-0.3, -0.5, 0.3, 0.3, 0.3, -0.3}, -- NodeBox3
				{-0.1, 0.3, 0.1, 0.1, 0.5, -0.1}, -- NodeBox4
		}
	},
})

minetest.register_node("firedamp:gas_cylinder", {
	description = "Gas Cylinder",
	drawtype = 'nodebox',
	tiles = {"gas_cylinder.png"},
	inventory_image = "gas_cylinder_inv.png",
	paramtype = "light",
	paramtype2 = 'facedir',
	stack_max = 1,
	walkable = true,
	groups = {dig_immediate=3,attached_node=1},
	sounds = default.node_sound_stone_defaults(),
	node_box = {
		type = 'fixed',
		fixed = {
				{-0.4, -0.5, 0.2, 0.4, 0.2, -0.2}, -- NodeBox1
				{-0.2, -0.5, 0.4, 0.2, 0.2, -0.4}, -- NodeBox2
				{-0.3, -0.5, 0.3, 0.3, 0.3, -0.3}, -- NodeBox3
				{-0.1, 0.3, 0.1, 0.1, 0.5, -0.1}, -- NodeBox4
		}
	},
	selection_box = {
		type = 'fixed',
		fixed = {
				{-0.4, -0.5, 0.2, 0.4, 0.2, -0.2}, -- NodeBox1
				{-0.2, -0.5, 0.4, 0.2, 0.2, -0.4}, -- NodeBox2
				{-0.3, -0.5, 0.3, 0.3, 0.3, -0.3}, -- NodeBox3
				{-0.1, 0.3, 0.1, 0.1, 0.5, -0.1}, -- NodeBox4
		}
	},
})

minetest.register_node("firedamp:rusty_gas_cylinder", {
	description = "Rusty Gas Cylinder",
	drawtype = 'nodebox',
	tiles = {"rusty_gas_cylinder.png"},
	inventory_image = "rusty_gas_cylinder_inv.png",
	paramtype = "light",
	paramtype2 = 'facedir',
	stack_max = 1,
	walkable = true,
	groups = {dig_immediate=3,attached_node=1},
	sounds = default.node_sound_stone_defaults(),
	node_box = {
		type = 'fixed',
		fixed = {
				{-0.4, -0.5, 0.2, 0.4, 0.2, -0.2}, -- NodeBox1
				{-0.2, -0.5, 0.4, 0.2, 0.2, -0.4}, -- NodeBox2
				{-0.3, -0.5, 0.3, 0.3, 0.3, -0.3}, -- NodeBox3
				{-0.1, 0.3, 0.1, 0.1, 0.5, -0.1}, -- NodeBox4
		}
	},
	selection_box = {
		type = 'fixed',
		fixed = {
				{-0.4, -0.5, 0.2, 0.4, 0.2, -0.2}, -- NodeBox1
				{-0.2, -0.5, 0.4, 0.2, 0.2, -0.4}, -- NodeBox2
				{-0.3, -0.5, 0.3, 0.3, 0.3, -0.3}, -- NodeBox3
				{-0.1, 0.3, 0.1, 0.1, 0.5, -0.1}, -- NodeBox4
		}
	},
})

--lamp

minetest.register_node("firedamp:lamp_white", {
	description = "White Lamp",
	drawtype = "nodebox",
	tiles = {"light_white.png"},
	inventory_image = {"light_white.png"},
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	is_ground_content = false,
	walkable = false,
	groups = {cracky = 3, oddly_breakable_by_hand = 3},
	sounds = default.node_sound_glass_defaults(),
	light_source = default.LIGHT_MAX,
	node_box = {
		type = "wallmounted",
		wall_top    = {-0.1, 0.5, -0.1, 0.1, 0.3, 0.1},
		wall_bottom = {-0.1, -0.5, -0.1, 0.1, -0.3, 0.1},
		wall_side   = {-0.5, -0.1, -0.1, -0.3, 0.1, 0.1},
	},
	selection_box = {
		type = "wallmounted",
		wall_top    = {-0.1, 0.5, -0.1, 0.1, 0.3, 0.1},
		wall_bottom = {-0.1, -0.5, -0.1, 0.1, -0.3, 0.1},
		wall_side   = {-0.5, -0.1, -0.1, -0.3, 0.1, 0.1},
	}
})

minetest.register_node("firedamp:lamp_red", {
	description = "Red Lamp",
	drawtype = "nodebox",
	tiles = {"light_red.png"},
	inventory_image = {"light_red.png"},
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	is_ground_content = false,
	walkable = false,
	groups = {cracky = 3, oddly_breakable_by_hand = 3},
	sounds = default.node_sound_glass_defaults(),
	light_source = default.LIGHT_MAX,
	node_box = {
		type = "wallmounted",
		wall_top    = {-0.1, 0.5, -0.1, 0.1, 0.3, 0.1},
		wall_bottom = {-0.1, -0.5, -0.1, 0.1, -0.3, 0.1},
		wall_side   = {-0.5, -0.1, -0.1, -0.3, 0.1, 0.1},
	},
	selection_box = {
		type = "wallmounted",
		wall_top    = {-0.1, 0.5, -0.1, 0.1, 0.3, 0.1},
		wall_bottom = {-0.1, -0.5, -0.1, 0.1, -0.3, 0.1},
		wall_side   = {-0.5, -0.1, -0.1, -0.3, 0.1, 0.1},
	}
})

minetest.register_node("firedamp:lamp_green", {
	description = "Green Lamp",
	drawtype = "nodebox",
	tiles = {"light_green.png"},
	inventory_image = {"light_green.png"},
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	is_ground_content = false,
	walkable = false,
	groups = {cracky = 3, oddly_breakable_by_hand = 3},
	sounds = default.node_sound_glass_defaults(),
	light_source = default.LIGHT_MAX,
	node_box = {
		type = "wallmounted",
		wall_top    = {-0.1, 0.5, -0.1, 0.1, 0.3, 0.1},
		wall_bottom = {-0.1, -0.5, -0.1, 0.1, -0.3, 0.1},
		wall_side   = {-0.5, -0.1, -0.1, -0.3, 0.1, 0.1},
	},
	selection_box = {
		type = "wallmounted",
		wall_top    = {-0.1, 0.5, -0.1, 0.1, 0.3, 0.1},
		wall_bottom = {-0.1, -0.5, -0.1, 0.1, -0.3, 0.1},
		wall_side   = {-0.5, -0.1, -0.1, -0.3, 0.1, 0.1},
	}
})

minetest.register_node("firedamp:lamp_blue", {
	description = "Blue Lamp",
	drawtype = "nodebox",
	tiles = {"light_blue.png"},
	inventory_image = {"light_blue.png"},
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	is_ground_content = false,
	walkable = false,
	groups = {cracky = 3, oddly_breakable_by_hand = 3},
	sounds = default.node_sound_glass_defaults(),
	light_source = default.LIGHT_MAX,
	node_box = {
		type = "wallmounted",
		wall_top    = {-0.1, 0.5, -0.1, 0.1, 0.3, 0.1},
		wall_bottom = {-0.1, -0.5, -0.1, 0.1, -0.3, 0.1},
		wall_side   = {-0.5, -0.1, -0.1, -0.3, 0.1, 0.1},
	},
	selection_box = {
		type = "wallmounted",
		wall_top    = {-0.1, 0.5, -0.1, 0.1, 0.3, 0.1},
		wall_bottom = {-0.1, -0.5, -0.1, 0.1, -0.3, 0.1},
		wall_side   = {-0.5, -0.1, -0.1, -0.3, 0.1, 0.1},
	}
})

minetest.register_node("firedamp:lamp_cyan", {
	description = "Cyan Lamp",
	drawtype = "nodebox",
	tiles = {"light_cyan.png"},
	inventory_image = {"light_cyan.png"},
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	is_ground_content = false,
	walkable = false,
	groups = {cracky = 3, oddly_breakable_by_hand = 3},
	sounds = default.node_sound_glass_defaults(),
	light_source = default.LIGHT_MAX,
	node_box = {
		type = "wallmounted",
		wall_top    = {-0.1, 0.5, -0.1, 0.1, 0.3, 0.1},
		wall_bottom = {-0.1, -0.5, -0.1, 0.1, -0.3, 0.1},
		wall_side   = {-0.5, -0.1, -0.1, -0.3, 0.1, 0.1},
	},
	selection_box = {
		type = "wallmounted",
		wall_top    = {-0.1, 0.5, -0.1, 0.1, 0.3, 0.1},
		wall_bottom = {-0.1, -0.5, -0.1, 0.1, -0.3, 0.1},
		wall_side   = {-0.5, -0.1, -0.1, -0.3, 0.1, 0.1},
	}
})

minetest.register_node("firedamp:lamp_magenta", {
	description = "Magneta Lamp",
	drawtype = "nodebox",
	tiles = {"light_magenta.png"},
	inventory_image = {"light_magenta.png"},
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	is_ground_content = false,
	walkable = false,
	groups = {cracky = 3, oddly_breakable_by_hand = 3},
	sounds = default.node_sound_glass_defaults(),
	light_source = default.LIGHT_MAX,
	node_box = {
		type = "wallmounted",
		wall_top    = {-0.1, 0.5, -0.1, 0.1, 0.3, 0.1},
		wall_bottom = {-0.1, -0.5, -0.1, 0.1, -0.3, 0.1},
		wall_side   = {-0.5, -0.1, -0.1, -0.3, 0.1, 0.1},
	},
	selection_box = {
		type = "wallmounted",
		wall_top    = {-0.1, 0.5, -0.1, 0.1, 0.3, 0.1},
		wall_bottom = {-0.1, -0.5, -0.1, 0.1, -0.3, 0.1},
		wall_side   = {-0.5, -0.1, -0.1, -0.3, 0.1, 0.1},
	}
})

minetest.register_node("firedamp:lamp_yellow", {
	description = "Yellow Lamp",
	drawtype = "nodebox",
	tiles = {"light_yellow.png"},
	inventory_image = {"light_yellow.png"},
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	is_ground_content = false,
	walkable = false,
	groups = {cracky = 3, oddly_breakable_by_hand = 3},
	sounds = default.node_sound_glass_defaults(),
	light_source = default.LIGHT_MAX,
	node_box = {
		type = "wallmounted",
		wall_top    = {-0.1, 0.5, -0.1, 0.1, 0.3, 0.1},
		wall_bottom = {-0.1, -0.5, -0.1, 0.1, -0.3, 0.1},
		wall_side   = {-0.5, -0.1, -0.1, -0.3, 0.1, 0.1},
	},
	selection_box = {
		type = "wallmounted",
		wall_top    = {-0.1, 0.5, -0.1, 0.1, 0.3, 0.1},
		wall_bottom = {-0.1, -0.5, -0.1, 0.1, -0.3, 0.1},
		wall_side   = {-0.5, -0.1, -0.1, -0.3, 0.1, 0.1},
	}
})

minetest.register_node("firedamp:neon_white", {
	description = "White Neon",
	drawtype = "nodebox",
	tiles = {"light_white.png"},
	inventory_image = {"light_white.png"},
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	is_ground_content = false,
	walkable = false,
	groups = {cracky = 3, oddly_breakable_by_hand = 3},
	sounds = default.node_sound_glass_defaults(),
	light_source = default.LIGHT_MAX,
	node_box = {
		type = "wallmounted",
		wall_top    = {-0.5, 0.5, -0.1, 0.5, 0.3, 0.1},
		wall_bottom = {-0.5, -0.5, -0.1, 0.5, -0.3, 0.1},
		wall_side   = {-0.5, -0.1, -0.5, -0.3, 0.1, 0.5},
	},
	selection_box = {
		type = "wallmounted",
		wall_top    = {-0.5, 0.5, -0.1, 0.5, 0.3, 0.1},
		wall_bottom = {-0.5, -0.5, -0.1, 0.5, -0.3, 0.1},
		wall_side   = {-0.5, -0.1, -0.5, -0.3, 0.1, 0.5},
	}
})

minetest.register_node("firedamp:neon_red", {
	description = "Red Neon",
	drawtype = "nodebox",
	tiles = {"light_red.png"},
	inventory_image = {"light_red.png"},
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	is_ground_content = false,
	walkable = false,
	groups = {cracky = 3, oddly_breakable_by_hand = 3},
	sounds = default.node_sound_glass_defaults(),
	light_source = default.LIGHT_MAX,
	node_box = {
		type = "wallmounted",
		wall_top    = {-0.5, 0.5, -0.1, 0.5, 0.3, 0.1},
		wall_bottom = {-0.5, -0.5, -0.1, 0.5, -0.3, 0.1},
		wall_side   = {-0.5, -0.1, -0.5, -0.3, 0.1, 0.5},
	},
	selection_box = {
		type = "wallmounted",
		wall_top    = {-0.5, 0.5, -0.1, 0.5, 0.3, 0.1},
		wall_bottom = {-0.5, -0.5, -0.1, 0.5, -0.3, 0.1},
		wall_side   = {-0.5, -0.1, -0.5, -0.3, 0.1, 0.5},
	}
})

minetest.register_node("firedamp:neon_green", {
	description = "Green Neon",
	drawtype = "nodebox",
	tiles = {"light_green.png"},
	inventory_image = {"light_green.png"},
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	is_ground_content = false,
	walkable = false,
	groups = {cracky = 3, oddly_breakable_by_hand = 3},
	sounds = default.node_sound_glass_defaults(),
	light_source = default.LIGHT_MAX,
	node_box = {
		type = "wallmounted",
		wall_top    = {-0.5, 0.5, -0.1, 0.5, 0.3, 0.1},
		wall_bottom = {-0.5, -0.5, -0.1, 0.5, -0.3, 0.1},
		wall_side   = {-0.5, -0.1, -0.5, -0.3, 0.1, 0.5},
	},
	selection_box = {
		type = "wallmounted",
		wall_top    = {-0.5, 0.5, -0.1, 0.5, 0.3, 0.1},
		wall_bottom = {-0.5, -0.5, -0.1, 0.5, -0.3, 0.1},
		wall_side   = {-0.5, -0.1, -0.5, -0.3, 0.1, 0.5},
	}
})

minetest.register_node("firedamp:neon_blue", {
	description = "Blue Neon",
	drawtype = "nodebox",
	tiles = {"light_blue.png"},
	inventory_image = {"light_blue.png"},
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	is_ground_content = false,
	walkable = false,
	groups = {cracky = 3, oddly_breakable_by_hand = 3},
	sounds = default.node_sound_glass_defaults(),
	light_source = default.LIGHT_MAX,
	node_box = {
		type = "wallmounted",
		wall_top    = {-0.5, 0.5, -0.1, 0.5, 0.3, 0.1},
		wall_bottom = {-0.5, -0.5, -0.1, 0.5, -0.3, 0.1},
		wall_side   = {-0.5, -0.1, -0.5, -0.3, 0.1, 0.5},
	},
	selection_box = {
		type = "wallmounted",
		wall_top    = {-0.5, 0.5, -0.1, 0.5, 0.3, 0.1},
		wall_bottom = {-0.5, -0.5, -0.1, 0.5, -0.3, 0.1},
		wall_side   = {-0.5, -0.1, -0.5, -0.3, 0.1, 0.5},
	}
})

minetest.register_node("firedamp:neon_cyan", {
	description = "Cyan Neon",
	drawtype = "nodebox",
	tiles = {"light_cyan.png"},
	inventory_image = {"light_cyan.png"},
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	is_ground_content = false,
	walkable = false,
	groups = {cracky = 3, oddly_breakable_by_hand = 3},
	sounds = default.node_sound_glass_defaults(),
	light_source = default.LIGHT_MAX,
	node_box = {
		type = "wallmounted",
		wall_top    = {-0.5, 0.5, -0.1, 0.5, 0.3, 0.1},
		wall_bottom = {-0.5, -0.5, -0.1, 0.5, -0.3, 0.1},
		wall_side   = {-0.5, -0.1, -0.5, -0.3, 0.1, 0.5},
	},
	selection_box = {
		type = "wallmounted",
		wall_top    = {-0.5, 0.5, -0.1, 0.5, 0.3, 0.1},
		wall_bottom = {-0.5, -0.5, -0.1, 0.5, -0.3, 0.1},
		wall_side   = {-0.5, -0.1, -0.5, -0.3, 0.1, 0.5},
	}
})

minetest.register_node("firedamp:neon_magenta", {
	description = "Magenta Neon",
	drawtype = "nodebox",
	tiles = {"light_magenta.png"},
	inventory_image = {"light_magenta.png"},
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	is_ground_content = false,
	walkable = false,
	groups = {cracky = 3, oddly_breakable_by_hand = 3},
	sounds = default.node_sound_glass_defaults(),
	light_source = default.LIGHT_MAX,
	node_box = {
		type = "wallmounted",
		wall_top    = {-0.5, 0.5, -0.1, 0.5, 0.3, 0.1},
		wall_bottom = {-0.5, -0.5, -0.1, 0.5, -0.3, 0.1},
		wall_side   = {-0.5, -0.1, -0.5, -0.3, 0.1, 0.5},
	},
	selection_box = {
		type = "wallmounted",
		wall_top    = {-0.5, 0.5, -0.1, 0.5, 0.3, 0.1},
		wall_bottom = {-0.5, -0.5, -0.1, 0.5, -0.3, 0.1},
		wall_side   = {-0.5, -0.1, -0.5, -0.3, 0.1, 0.5},
	}
})

minetest.register_node("firedamp:neon_yellow", {
	description = "Yellow Neon",
	drawtype = "nodebox",
	tiles = {"light_yellow.png"},
	inventory_image = {"light_yellow.png"},
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	is_ground_content = false,
	walkable = false,
	groups = {cracky = 3, oddly_breakable_by_hand = 3},
	sounds = default.node_sound_glass_defaults(),
	light_source = default.LIGHT_MAX,
	node_box = {
		type = "wallmounted",
		wall_top    = {-0.5, 0.5, -0.1, 0.5, 0.3, 0.1},
		wall_bottom = {-0.5, -0.5, -0.1, 0.5, -0.3, 0.1},
		wall_side   = {-0.5, -0.1, -0.5, -0.3, 0.1, 0.5},
	},
	selection_box = {
		type = "wallmounted",
		wall_top    = {-0.5, 0.5, -0.1, 0.5, 0.3, 0.1},
		wall_bottom = {-0.5, -0.5, -0.1, 0.5, -0.3, 0.1},
		wall_side   = {-0.5, -0.1, -0.5, -0.3, 0.1, 0.5},
	}
})

--slab
minetest.register_node("firedamp:slap_light_white", {
	description = "White Slap Light",
	drawtype = "nodebox",
	tiles = {"light_white.png"},
	inventory_image = {"light_white.png"},
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	is_ground_content = false,
	walkable = true,
	groups = {cracky = 3, oddly_breakable_by_hand = 3},
	sounds = default.node_sound_glass_defaults(),
	light_source = default.LIGHT_MAX,
	node_box = {
		type = "wallmounted",
		wall_top    = {-0.5, 0.5, -0.5, 0.5, 0.3, 0.5},
		wall_bottom = {-0.5, -0.5, -0.5, 0.5, -0.3, 0.5},
		wall_side   = {-0.5, -0.5, -0.5, -0.3, 0.5, 0.5},
	},
	selection_box = {
		type = "wallmounted",
		wall_top    = {-0.5, 0.5, -0.5, 0.5, 0.3, 0.5},
		wall_bottom = {-0.5, -0.5, -0.5, 0.5, -0.3, 0.5},
		wall_side   = {-0.5, -0.5, -0.5, -0.3, 0.5, 0.5},
	}
})

minetest.register_node("firedamp:slap_light_red", {
	description = "Red Slap Light",
	drawtype = "nodebox",
	tiles = {"light_red.png"},
	inventory_image = {"light_red.png"},
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	is_ground_content = false,
	walkable = true,
	groups = {cracky = 3, oddly_breakable_by_hand = 3},
	sounds = default.node_sound_glass_defaults(),
	light_source = default.LIGHT_MAX,
	node_box = {
		type = "wallmounted",
		wall_top    = {-0.5, 0.5, -0.5, 0.5, 0.3, 0.5},
		wall_bottom = {-0.5, -0.5, -0.5, 0.5, -0.3, 0.5},
		wall_side   = {-0.5, -0.5, -0.5, -0.3, 0.5, 0.5},
	},
	selection_box = {
		type = "wallmounted",
		wall_top    = {-0.5, 0.5, -0.5, 0.5, 0.3, 0.5},
		wall_bottom = {-0.5, -0.5, -0.5, 0.5, -0.3, 0.5},
		wall_side   = {-0.5, -0.5, -0.5, -0.3, 0.5, 0.5},
	}
})

minetest.register_node("firedamp:slap_light_green", {
	description = "Green Slap Light",
	drawtype = "nodebox",
	tiles = {"light_green.png"},
	inventory_image = {"light_green.png"},
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	is_ground_content = false,
	walkable = true,
	groups = {cracky = 3, oddly_breakable_by_hand = 3},
	sounds = default.node_sound_glass_defaults(),
	light_source = default.LIGHT_MAX,
	node_box = {
		type = "wallmounted",
		wall_top    = {-0.5, 0.5, -0.5, 0.5, 0.3, 0.5},
		wall_bottom = {-0.5, -0.5, -0.5, 0.5, -0.3, 0.5},
		wall_side   = {-0.5, -0.5, -0.5, -0.3, 0.5, 0.5},
	},
	selection_box = {
		type = "wallmounted",
		wall_top    = {-0.5, 0.5, -0.5, 0.5, 0.3, 0.5},
		wall_bottom = {-0.5, -0.5, -0.5, 0.5, -0.3, 0.5},
		wall_side   = {-0.5, -0.5, -0.5, -0.3, 0.5, 0.5},
	}
})

minetest.register_node("firedamp:slap_light_blue", {
	description = "Blue Slap Light",
	drawtype = "nodebox",
	tiles = {"light_blue.png"},
	inventory_image = {"light_blue.png"},
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	is_ground_content = false,
	walkable = true,
	groups = {cracky = 3, oddly_breakable_by_hand = 3},
	sounds = default.node_sound_glass_defaults(),
	light_source = default.LIGHT_MAX,
	node_box = {
		type = "wallmounted",
		wall_top    = {-0.5, 0.5, -0.5, 0.5, 0.3, 0.5},
		wall_bottom = {-0.5, -0.5, -0.5, 0.5, -0.3, 0.5},
		wall_side   = {-0.5, -0.5, -0.5, -0.3, 0.5, 0.5},
	},
	selection_box = {
		type = "wallmounted",
		wall_top    = {-0.5, 0.5, -0.5, 0.5, 0.3, 0.5},
		wall_bottom = {-0.5, -0.5, -0.5, 0.5, -0.3, 0.5},
		wall_side   = {-0.5, -0.5, -0.5, -0.3, 0.5, 0.5},
	}
})

minetest.register_node("firedamp:slap_light_cyan", {
	description = "Cyan Slap Light",
	drawtype = "nodebox",
	tiles = {"light_cyan.png"},
	inventory_image = {"light_cyan.png"},
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	is_ground_content = false,
	walkable = true,
	groups = {cracky = 3, oddly_breakable_by_hand = 3},
	sounds = default.node_sound_glass_defaults(),
	light_source = default.LIGHT_MAX,
	node_box = {
		type = "wallmounted",
		wall_top    = {-0.5, 0.5, -0.5, 0.5, 0.3, 0.5},
		wall_bottom = {-0.5, -0.5, -0.5, 0.5, -0.3, 0.5},
		wall_side   = {-0.5, -0.5, -0.5, -0.3, 0.5, 0.5},
	},
	selection_box = {
		type = "wallmounted",
		wall_top    = {-0.5, 0.5, -0.5, 0.5, 0.3, 0.5},
		wall_bottom = {-0.5, -0.5, -0.5, 0.5, -0.3, 0.5},
		wall_side   = {-0.5, -0.5, -0.5, -0.3, 0.5, 0.5},
	}
})

minetest.register_node("firedamp:slap_light_magenta", {
	description = "Magenta Slap Light",
	drawtype = "nodebox",
	tiles = {"light_magenta.png"},
	inventory_image = {"light_magenta.png"},
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	is_ground_content = false,
	walkable = true,
	groups = {cracky = 3, oddly_breakable_by_hand = 3},
	sounds = default.node_sound_glass_defaults(),
	light_source = default.LIGHT_MAX,
	node_box = {
		type = "wallmounted",
		wall_top    = {-0.5, 0.5, -0.5, 0.5, 0.3, 0.5},
		wall_bottom = {-0.5, -0.5, -0.5, 0.5, -0.3, 0.5},
		wall_side   = {-0.5, -0.5, -0.5, -0.3, 0.5, 0.5},
	},
	selection_box = {
		type = "wallmounted",
		wall_top    = {-0.5, 0.5, -0.5, 0.5, 0.3, 0.5},
		wall_bottom = {-0.5, -0.5, -0.5, 0.5, -0.3, 0.5},
		wall_side   = {-0.5, -0.5, -0.5, -0.3, 0.5, 0.5},
	}
})

minetest.register_node("firedamp:slap_light_yellow", {
	description = "Yellow Slap Light",
	drawtype = "nodebox",
	tiles = {"light_yellow.png"},
	inventory_image = {"light_yellow.png"},
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	is_ground_content = false,
	walkable = true,
	groups = {cracky = 3, oddly_breakable_by_hand = 3},
	sounds = default.node_sound_glass_defaults(),
	light_source = default.LIGHT_MAX,
	node_box = {
		type = "wallmounted",
		wall_top    = {-0.5, 0.5, -0.5, 0.5, 0.3, 0.5},
		wall_bottom = {-0.5, -0.5, -0.5, 0.5, -0.3, 0.5},
		wall_side   = {-0.5, -0.5, -0.5, -0.3, 0.5, 0.5},
	},
	selection_box = {
		type = "wallmounted",
		wall_top    = {-0.5, 0.5, -0.5, 0.5, 0.3, 0.5},
		wall_bottom = {-0.5, -0.5, -0.5, 0.5, -0.3, 0.5},
		wall_side   = {-0.5, -0.5, -0.5, -0.3, 0.5, 0.5},
	}
})
