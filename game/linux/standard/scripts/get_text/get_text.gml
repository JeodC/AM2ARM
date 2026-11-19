/// @description Read a selected-language key, falling back to bundled English.
function get_text(argument0, argument1) {
    ini_open(global.language[global.currentlanguage]);
    var text = ini_read_string(argument0, argument1, "[!]");
    ini_close();
    if (text == "[!]" && global.currentlanguage != 0) {
        ini_open(global.language[0]);
        text = ini_read_string(argument0, argument1, "[!]");
        ini_close();
    }
    return text;
}
