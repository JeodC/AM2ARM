// Use this location's assigned item for its pickup graphic and message.
itemid = 100
itemidOriginal = itemid;
itemid = oControl.mod_100;
if (oControl.mod_100 != itemidOriginal) { src_items_rando(itemid); }
scr_item_create_text();