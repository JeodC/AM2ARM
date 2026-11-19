
// Match this collision barrier to the current lava-recession stage.
if (global.lavastate > 5) {
    tile_layer_delete(-98);
    instance_destroy();
}
