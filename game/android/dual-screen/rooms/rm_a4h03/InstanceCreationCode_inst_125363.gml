// Use this location's assigned item for its pickup graphic and message.
itemid = 257;
itemidOriginal = itemid;
itemid = oControl.mod_257;
if (oControl.mod_257 != itemidOriginal) { src_items_rando(itemid); }
scr_item_create_text();