--MapGen firedamp_block

minetest.register_ore({
	ore_type       = "scatter",
	ore            = "firedamp:firedamp_block",
	wherein        = "default:stone",
	clust_scarcity = 15 * 15 * 15,
	clust_num_ores = 3,
	clust_size     = 2,
	y_min          = -255,
	y_max          = -64,
})
minetest.register_ore({
	ore_type       = "scatter",
	ore            = "firedamp:firedamp_block",
	wherein        = "default:stone",
	clust_scarcity = 13 * 13 * 13,
	clust_num_ores = 5,
	clust_size     = 3,
	y_min          = -31000,
	y_max          = -256,
})
