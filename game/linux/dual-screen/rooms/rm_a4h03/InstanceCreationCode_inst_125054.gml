// Use this location's assigned item for its pickup graphic and message.
itemid = 251;
itemidOriginal = itemid;
itemid = oControl.mod_251;
if (oControl.mod_251 != itemidOriginal) { src_items_rando(itemid); }
scr_item_create_text();