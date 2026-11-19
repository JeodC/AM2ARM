// Each flame starts the next one outward, stopping at the boss arena boundary.
if (oBoss1Head.myhealth > 0 && x > oBoss1Head.edge_l) instance_create(x - 12, y, oBoss1FBExplL);

