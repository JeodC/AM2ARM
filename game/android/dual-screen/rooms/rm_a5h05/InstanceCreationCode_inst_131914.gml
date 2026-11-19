// Use this location's assigned item for its pickup graphic and message.
itemid = 302;
itemidOriginal = itemid;
itemid = oControl.mod_302;
if (oControl.mod_302 != itemidOriginal) { src_items_rando(itemid); }
scr_item_create_text();