// Use this location's assigned item for its pickup graphic and message.
itemid = 200;
itemidOriginal = itemid;
itemid = oControl.mod_200;
if (oControl.mod_200 != itemidOriginal) { src_items_rando(itemid); }
scr_item_create_text();