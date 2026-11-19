// Use this location's assigned item for its pickup graphic and message.
itemid = 252;
itemidOriginal = itemid;
itemid = oControl.mod_252;
if (oControl.mod_252 != itemidOriginal) { src_items_rando(itemid); }
scr_item_create_text();