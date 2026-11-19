for (var i = 0; i < 5; i += 1) {
    if (instance_exists(item_card[i])) with (item_card[i]) instance_destroy();
    if (instance_exists(item_row[i])) with (item_row[i]) instance_destroy();
}

var names = ["save1", "save2", "save3", "data.sav", "extras.sav"];
for (var n = 0; n < array_length(names); n++) file_delete("restorestage_" + names[n]);
