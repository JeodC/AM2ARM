// Use this location's assigned item for its pickup graphic and message.
itemid = 254;
itemidOriginal = itemid;
itemid = oControl.mod_254;
if (oControl.mod_254 != itemidOriginal) { src_items_rando(itemid); }
scr_item_create_text();
