// Use this location's assigned item for its pickup graphic and message.
itemid = 110;
itemidOriginal = itemid;
itemid = oControl.mod_110;
if (oControl.mod_110 != itemidOriginal) { src_items_rando(itemid); }
scr_item_create_text();