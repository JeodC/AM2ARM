// Once the head exists, copy this room waypoint into its route and remove the marker.
if (instance_exists(oErisHead)) {
    oErisHead.tgt1x[point] = x;
    oErisHead.tgt1y[point] = y;
    instance_destroy();
}

