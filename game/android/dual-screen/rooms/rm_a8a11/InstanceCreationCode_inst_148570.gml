// Use this location's assigned item for its pickup graphic and message.
itemid = 50;
itemidOriginal = itemid;
itemid = oControl.mod_50;
if (oControl.mod_50 != itemidOriginal) { src_items_rando(itemid); }
scr_item_create_text();