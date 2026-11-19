// Inside the room-defined zone, keep the selected camera axes locked until Samus leaves.
if (oCharacter.x >= x && oCharacter.x <= x + areax && oCharacter.y - 12 <= y && oCharacter.y - 12 >= y + areay) {
    oCamera.smootin = smoothin;
    if (oCamera.focus == 0) {
        oCamera.focus = 1;
        oCamera.focustime = 0;
    }
    oCamera.focustime += 1;
    if (lockx != 0) {
        oCamera.lockx = 1;
        oCamera.targetx = lockx;
        oCamera.snapx = 0;
        // GM2026: was alarm[2]=1, which FIRES the unlock alarm (lockx=0) every frame. In
        // GMS1.4 this limiter happened to Step before oCamera, so the re-lock landed in
        // time; GM2026 runs oCamera first, so it saw lockx/locky==0 every frame and the
        // camera never locked (probe: lock=1 tgt=120 but cam stuck at follow-y).
        // 2 never fires while we keep refreshing it — the pattern oCameraLimitV already uses.
        oCamera.alarm[2] = 2;
    }
    if (locky != 0) {
        oCamera.locky = 1;
        oCamera.targety = locky;
        oCamera.snapy = 0;
        oCamera.alarm[3] = 2; // GM2026: was 1 — see comment above
    }
    oCamera.smoothout = smoothout * 2.5;
}

