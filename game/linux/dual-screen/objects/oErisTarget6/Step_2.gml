// Once the head exists, copy this room waypoint into its route and remove the marker.
if (instance_exists(oErisHead)) {
    oErisHead.tgt6x[point] = x;
    oErisHead.tgt6y[point] = y;
    instance_destroy();
}

