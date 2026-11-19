// Use this location's assigned item for its pickup graphic and message.
itemid = 215;
itemidOriginal = itemid;
itemid = oControl.mod_215;
if (oControl.mod_215 != itemidOriginal) { src_items_rando(itemid); }
scr_item_create_text();