/// @description  sv6_add_itemsA7()
function sv6_add_itemsA7() {
	var list, i, str_list;
	list = ds_list_create();
	// Serialize collected-item flags for indices 700 through 719 in their stored order.
	i = 700;
	repeat (20) {
	    ds_list_add(list, global.item[i]);
	    i += 1;
	}
	str_list = ds_list_write(list);
	ds_list_clear(list);
	return str_list;



}
