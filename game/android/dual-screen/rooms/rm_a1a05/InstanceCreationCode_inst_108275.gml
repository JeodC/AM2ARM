// Use this location's assigned item for its pickup graphic and message.
itemid = 101;
itemidOriginal = itemid;
itemid = oControl.mod_101;
if (oControl.mod_101 != itemidOriginal) { src_items_rando(itemid); }
scr_item_create_text();