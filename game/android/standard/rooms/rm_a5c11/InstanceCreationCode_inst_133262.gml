
// Remove this crumble block and its covering tile after the saved room event.
link_tile(tlArea5A, 112, 144);
regentime = -1;
if(global.event[253] == 1) {
    tile_delete(tileid);
    instance_destroy();
}
