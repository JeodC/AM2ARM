/// @description  sv6_add_itemsA6()
function sv6_add_itemsA6() {
	var list, i, str_list;
	list = ds_list_create();
	// Serialize collected-item flags for indices 600 through 619 in their stored order.
	i = 600;
	repeat (20) {
	    ds_list_add(list, global.item[i]);
	    i += 1;
	}
	str_list = ds_list_write(list);
	ds_list_clear(list);
	return str_list;



}
