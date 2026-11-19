// The shared intro timeline owns this caption while the sequence is present.
if (instance_exists(oTitleAnimation)) exit;
if (statetime < 100 && image_alpha < 1) image_alpha += 0.05;
if (statetime > 300) {
    if (image_alpha > 0) {
        image_alpha -= 0.02;
    } else instance_destroy();
}
statetime += 1;

