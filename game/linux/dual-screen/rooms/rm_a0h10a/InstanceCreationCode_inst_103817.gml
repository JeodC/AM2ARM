
// Match this collision barrier to the current lava-recession stage.
if (global.lavastate > 4) {
    tile_layer_delete(-99);
    instance_destroy();
}
