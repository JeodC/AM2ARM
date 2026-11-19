// Use this location's assigned item for its pickup graphic and message.
itemid = 55;
itemidOriginal = itemid;
itemid = oControl.mod_55;
if (oControl.mod_55 != itemidOriginal) { src_items_rando(itemid); }
scr_item_create_text();
