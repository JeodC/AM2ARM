// Once the head exists, copy this room waypoint into its route and remove the marker.
if (instance_exists(oErisHead)) {
    oErisHead.tgt3x[point] = x;
    oErisHead.tgt3y[point] = y;
    instance_destroy();
}

