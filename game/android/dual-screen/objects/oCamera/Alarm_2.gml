lockx = 0;
focus = 0;
ratiox = smoothout;
// GM2026 fix (device-probe verified): if snapx survived the lock (zones only clear it when
// actively retargeting), the hard-glue "if (snapx==1) x = targetx" teleports the camera to
// Samus on the frame of release, overriding this smoothout. Drop the glue; it re-arms by
// itself once the eased catch-up converges (the snapx=1 set requires lockx==0 and proximity).
snapx = 0;
