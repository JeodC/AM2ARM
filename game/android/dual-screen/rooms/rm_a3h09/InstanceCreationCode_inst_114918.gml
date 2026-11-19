// Use this location's assigned item for its pickup graphic and message.
itemid = 213;
itemidOriginal = itemid;
itemid = oControl.mod_213;
if (oControl.mod_213 != itemidOriginal) { src_items_rando(itemid); }
scr_item_create_text();