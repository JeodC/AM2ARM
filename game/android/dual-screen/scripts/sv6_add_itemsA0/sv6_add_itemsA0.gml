/// @description  sv6_add_itemsA0()
function sv6_add_itemsA0() {
	var list, str_list;
	list = ds_list_create();
	// Serialize collected-item flags for indices 0 through 19 in their stored order.
	i = 0;
	repeat (20) {
	    ds_list_add(list, global.item[i]);
	    i += 1;
	}
	str_list = ds_list_write(list);
	ds_list_clear(list);
	return str_list;



}
