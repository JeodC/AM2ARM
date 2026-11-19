for (var n = 0; n <= lastitem; n++) {
    if (instance_exists(op[n])) with (op[n]) instance_destroy();
}
