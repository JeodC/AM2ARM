y -= 8; // Moved from user 0 to avoid reset issues.
// Change to object creation position instead!

global.curropt = 0;
active = 0;
targetY = y;
timer = 0;
SPACER = 16;
buttonsEnabled = true;
if (os_type != os_android && !gamepad_is_connected(global.gamepadIndex)) || (os_type == os_android && (!global.joydetected || global.compatibilitymode)) {
    buttonsEnabled = false;
}

__view_set( e__VW.Object, 0, id );

// Active in 5
alarm[0] = 5;

var i = 0;

/*
    This list dictates the order of selection in the Display Menu. 
    Also, the lists in User Defined 0 and 3 need to be in order.
*/

// DISPLAY OPTIONS

// Fullscreen and scale should NOT exist on Android
if (os_type != os_android) {
    opFullscreen = i++;
    opScale = i++;
}
opVSync = i++;
opSensitivity = i++;
opNano = i++;
opWidescreen = i++;
opDeviceProfile = i++;
opSwapScreens = i++;
// HUD
opShowHUD = i++;
opShowMap = i++;
opCounterStyle = i++;
// NOTIFICATIONS
opShowHints = i++;
if (buttonsEnabled) {
    opButtonType = i++;
}
opShowScans = i++;
opLanguage = i++;

menuSize = i; // 1 larger than last item

vTargetY = 18 * menuSize + 72;

i = 0;

// Enable menu
repeat (menuSize + 1) {
    canEdit[i] = 1;
    i++;
}
// A hardware profile with a fixed upper aspect removes that row from editable menu navigation.
canEdit[opWidescreen] = !oControl.thor_aspect_locked;
canEdit[opSwapScreens] = oControl.thor_enabled && thor_swap_supported(oControl.thor_profile);
// Health and ammunition can move above; the map and counters remain below.
canEdit[opShowMap] = 0;
canEdit[opCounterStyle] = 0;

// Get lang info
langCount = array_length_1d(global.language);
for (i = 0; i < langCount; i += 1) {
    ini_open(global.language[i]);
    // A display label may differ from the legacy artwork's language prefix.
    lang[i] = ini_read_string("Header", "DisplayName", ini_read_string("Header", "Language", "[!]"));
    langAuthor[i] = ini_read_string("Header", "Author", "[!]");
    langAuthor2[i] = ini_read_string("Header", "Author2", "[!]");
    ini_close();
}

// Create menu items
event_user(0);

// Load tip text
event_user(3);

// Load current tip text
global.tiptext = tip[global.curropt];

/* */
/*  */
