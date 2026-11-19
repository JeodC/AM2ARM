// Use this location's assigned item for its pickup graphic and message.
itemid = 211;
itemidOriginal = itemid;
itemid = oControl.mod_211;
if (oControl.mod_211 != itemidOriginal) { src_items_rando(itemid); }
scr_item_create_text();