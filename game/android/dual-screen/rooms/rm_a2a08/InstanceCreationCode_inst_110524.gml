// Use this location's assigned item for its pickup graphic and message.
itemid = 150;
itemidOriginal = itemid;
itemid = oControl.mod_150;
if (oControl.mod_150 != itemidOriginal) { src_items_rando(itemid); }
scr_item_create_text();