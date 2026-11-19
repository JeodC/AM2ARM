// Use this location's assigned item for its pickup graphic and message.
itemid = 203;
itemidOriginal = itemid;
itemid = oControl.mod_203;
if (oControl.mod_203 != itemidOriginal) { src_items_rando(itemid); }
scr_item_create_text();