if (active && global.itemtype == 0 && (oControl.kStart && oControl.kStartPushedSteps == 0 || oControl.kJump && oControl.kJumpPushedSteps == 0 || oControl.kFire && oControl.kFirePushedSteps == 0)) event_user(0);
if (ealpha < 1 && fadeout == 0) ealpha += 0.05;
if (ealpha > 0 && fadeout) ealpha -= 0.05;
if (ealpha >= 1 && fadeout == 0) active = 1;
if (ealpha <= 0 && fadeout) {
    global.ingame = 1;
    global.transitiontype = 3;
    // GM2026 fix: free our snapshot (see Create) — it is a private copy, never the live surface
    if (surface_exists(surf)) surface_free(surf);
    room_goto(global.currentroom);
}
size = ealpha * 24;

