// Use this location's assigned item for its pickup graphic and message.
itemid = 54;
itemidOriginal = itemid;
itemid = oControl.mod_54;
if (oControl.mod_54 != itemidOriginal) { src_items_rando(itemid); }
scr_item_create_text();
