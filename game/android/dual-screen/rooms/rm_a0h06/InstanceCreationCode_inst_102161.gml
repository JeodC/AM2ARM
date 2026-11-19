
// Match this collision barrier to the current lava-recession stage.
if (global.lavastate > 0) {
    tile_layer_delete(-150);
    instance_destroy();
}
