// Set world-map placement and liquid state.
global.mapoffsetx = 36;
global.mapoffsety = 21;
global.waterlevel = 0;
global.watertype = 0;
// Recreate the water-jet stream and its spawner while the launch system is active.
if (global.event[102] == 1) {
    instance_create(0, -64, oA2WaterSpawner);
    instance_create(136, 200, oA2WJWaterA);
    instance_create(136, 216, oA2WJWaterA);
    instance_create(136, 232, oA2WJWaterA);
    instance_create(136, 248, oA2WJWaterA);
}