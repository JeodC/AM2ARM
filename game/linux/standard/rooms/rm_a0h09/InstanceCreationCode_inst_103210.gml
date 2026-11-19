
// Match this collision barrier to the current lava-recession stage.
if (global.lavastate > 2) {
    tile_layer_delete(-99);
    instance_destroy();
}
