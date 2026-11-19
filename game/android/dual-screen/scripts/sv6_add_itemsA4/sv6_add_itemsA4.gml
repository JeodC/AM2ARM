/// @description  sv6_add_itemsA4()
function sv6_add_itemsA4() {
	var list, i, str_list;
	list = ds_list_create();
	// Serialize collected-item flags for indices 400 through 419 in their stored order.
	i = 400;
	repeat (20) {
	    ds_list_add(list, global.item[i]);
	    i += 1;
	}
	str_list = ds_list_write(list);
	ds_list_clear(list);
	return str_list;



}
