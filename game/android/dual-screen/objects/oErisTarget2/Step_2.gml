// Once the head exists, copy this room waypoint into its route and remove the marker.
if (instance_exists(oErisHead)) {
    oErisHead.tgt2x[point] = x;
    oErisHead.tgt2y[point] = y;
    instance_destroy();
}

