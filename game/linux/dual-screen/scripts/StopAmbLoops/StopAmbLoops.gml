/// @description  StopAmbLoops()
function StopAmbLoops() {
	// Stop the laser, blade and machine ambience loops used by these room effects.
	sfx_stop(sndALLaserLoop);
	sfx_stop(sndALBladesLoop);
	sfx_stop(sndMachineLoop1);



}
