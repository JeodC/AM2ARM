/// @description  Load tip text

if (os_type != os_android) {
    tip[opFullscreen] = get_text("OptionsDisplay", "Fullscreen_Tip");
    tip[opScale] = get_text("OptionsDisplay", "DisplayScale_Tip");
}
// Keep help text indexed by the same row IDs used for navigation and value changes.
tip[opVSync] = get_text("OptionsDisplay", "VSync_Tip");
tip[opSensitivity] = get_text("Misc", "SensitivityMode_Tip");
tip[opNano] = nano_option_text("Nano_Tip", "Fewer effects; lighter water. Static idle map.");
tip[opWidescreen] = port_caption("Aspect ratio of the gameplay screen.");
tip[opDeviceProfile] = port_caption("Choose your dual-screen handheld.");
tip[opShowHUD] = port_caption("Choose the screen for health and ammunition.");
tip[opShowMap] = get_text("OptionsDisplay", "HUDMap_Tip");
tip[opCounterStyle] = get_text("OptionsDisplay", "MonsterCounter_Tip");
tip[opShowHints] = get_text("OptionsDisplay", "Hints_Tip");
if (buttonsEnabled) {
    tip[opButtonType] = get_text("ExtrasMenu", "Controller_Tip");
}
tip[opShowScans] = get_text("OptionsDisplay", "ScanNotifications_Tip");
tip[opLanguage] = get_text("OptionsDisplay", "Language_Tip");
tip[menuSize] = get_text("GlobalOptions", "ExitMain_Tip");

tip[opSwapScreens] = port_caption(oControl.thor_profile == 2 ? "Send gameplay to the USB screen and the map to this device." : "Swap the gameplay and map screens on RG DS.");
