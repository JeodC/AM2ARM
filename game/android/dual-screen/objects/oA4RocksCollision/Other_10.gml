// Throw the loose rocks aside and remove the solid that made the pile block Samus.
with (oA4Rock) event_user(0);
with (oA4RockTop) event_user(0);
with (mysolid) instance_destroy();
global.event[206] = 1;
instance_destroy();

