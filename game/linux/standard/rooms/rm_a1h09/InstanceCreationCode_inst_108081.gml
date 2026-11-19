// Use this location's assigned item for its pickup graphic and message.
itemid = 111;
itemidOriginal = itemid;
itemid = oControl.mod_111;
if (oControl.mod_111 != itemidOriginal) { src_items_rando(itemid); }
scr_item_create_text();