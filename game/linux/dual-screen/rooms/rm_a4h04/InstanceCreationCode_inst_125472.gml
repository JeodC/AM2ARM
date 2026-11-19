// Use this location's assigned item for its pickup graphic and message.
itemid = 258;
itemidOriginal = itemid;
itemid = oControl.mod_258;
if (oControl.mod_258 != itemidOriginal) { src_items_rando(itemid); }
scr_item_create_text();