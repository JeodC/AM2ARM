package ${YYAndroidPackageName};

import android.content.Context;
import android.graphics.Rect;
import android.opengl.EGL14;
import android.opengl.EGLConfig;
import android.opengl.EGLContext;
import android.opengl.EGLDisplay;
import android.opengl.EGLSurface;
import android.opengl.GLES20;
import android.opengl.GLES30;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;

/** Share lower-display textures while preserving GameMaker's GL state. */
final class AM2RGpuOutput extends SurfaceView implements SurfaceHolder.Callback {
    private final Object surfaceLock = new Object();
    private final AM2RThor owner;
    private Surface window;
    private int generation, boundGeneration = -1, physicalWidth, physicalHeight;
    private EGLDisplay display = EGL14.EGL_NO_DISPLAY;
    private EGLContext producer = EGL14.EGL_NO_CONTEXT, context = EGL14.EGL_NO_CONTEXT;
    private EGLSurface output = EGL14.EGL_NO_SURFACE;
    private int program, vertices, sampler, texture;
    private EGLContext capabilityContext = EGL14.EGL_NO_CONTEXT;
    private boolean supportsSharedOutput;
    private boolean sharedOutputSupported(EGLContext current) {
        if (current.equals(EGL14.EGL_NO_CONTEXT)) return false;
        if (!current.equals(capabilityContext)) {
            String version = GLES20.glGetString(GLES20.GL_VERSION);
            supportsSharedOutput = version != null && version.startsWith("OpenGL ES 3");
            capabilityContext = current;
        }
        return supportsSharedOutput;
    }
    private EGLContext screenProducer = EGL14.EGL_NO_CONTEXT;
    private int screenTexture, screenWidth, screenHeight, screenFramebuffer;
    private boolean screenOrigin, screenUseBlit;
    private volatile long presentedFrames, failedFrames, copiedFrames, copyFailures;
    private volatile long blittedFrames, blitFailures;
    private static final int SCREEN_ERROR_DRAIN_LIMIT = 16;
    private volatile long preexistingErrors, preexistingDrainLimits, setupFailures, restoreFailures;
    private volatile long contextChanges, textureAllocations, screenResizes;
    private volatile String lastPreexistingError = "";
    private volatile int sourceFramebuffer;
    private int uvRegion, brightness, hudTexture, hudWidth, hudHeight, hudTop, hudBottom;
    private float hudBrightness = 1;
    private int hudPhysicalScale, titleScale, hudHints;
    private float titleX, titleY;
    // One synchronized snapshot for the two GML layout values.
    double hudMetrics(int width, int height) {
        synchronized (surfaceLock) {
            if (width < 1 || height < 1 || physicalWidth < 1 || physicalHeight < 1) return 0;
            int sceneScale = outputScale(width, height);
            int pixels = Math.max(1, width * sceneScale / 177);
            return pixels * 65536.0 + sceneScale;
        }
    }
    int hudPixels(int width, int height) {
        synchronized (surfaceLock) {
            return Math.max(1, width * outputScale(width, height) / 177);
        }
    }
    void hudTitlePosition(float x, float y) { titleX = x; titleY = y; }
    void hudTitleScale(int scale) { titleScale = Math.max(0, scale); }
    void hudHints(int mask) { hudHints = mask & 7; }

    private int outputScale(int width, int height) {
        int scale = Math.max(1, Math.min(physicalWidth / width, physicalHeight / height));
        int next = scale + 1;
        if (width * next - physicalWidth <= 2 && height * next - physicalHeight <= 2) scale = next;
        return scale;
    }
    double hudScale(int width, int height) {
        synchronized (surfaceLock) {
            if (physicalWidth < 1 || physicalHeight < 1) return 0;
            int sceneScale = outputScale(width, height);
            int scale = Math.max(1, width * sceneScale / 177);
            return (double) scale / sceneScale;
        }
    }
    void captureHud(int width, int height) {
        int scene = texture;
        boolean origin = screenOrigin;
        captureTarget();
        hudTexture = texture; hudWidth = width; hudHeight = height;
        texture = scene;
        screenOrigin = origin;
    }
    void hudBands(int top, int bottom) { hudTop = top; hudBottom = bottom; }
    void hudBrightness(float value) { hudBrightness = Math.max(0, Math.min(1, value)); }
    private void drawHudBand(int x, int y, int scale, int sourceY, int rows) {
        if (rows < 1) return;
        GLES20.glViewport(x, y, hudWidth * scale, rows * scale);
        GLES20.glUniform4f(uvRegion, 0, (float) sourceY / hudHeight, 1, (float) rows / hudHeight);
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4);
    }
    private boolean requested, failed;
    private volatile String failure = "";
    private final int[] value = new int[4];

    AM2RGpuOutput(Context context, AM2RThor owner) {
        super(context);
        this.owner = owner;
        setFocusable(false);
        setVisibility(INVISIBLE);
        setZOrderOnTop(true);
        getHolder().setFormat(android.graphics.PixelFormat.OPAQUE);
        getHolder().addCallback(this);
    }
    @Override public void surfaceCreated(SurfaceHolder holder) {
        synchronized (surfaceLock) { window = holder.getSurface(); generation++; }
    }
    @Override public void surfaceChanged(SurfaceHolder holder, int format, int w, int h) {
        synchronized (surfaceLock) { physicalWidth = w; physicalHeight = h; }
    }
    @Override public void surfaceDestroyed(SurfaceHolder holder) {
        synchronized (surfaceLock) { window = null; generation++; }
    }
    void request(boolean enable) {
        if (requested == enable) return;
        requested = enable;
        post(() -> { setVisibility(enable ? VISIBLE : INVISIBLE); if (!enable) owner.gpuShown(false); });
    }
    void captureTarget() {
        texture = 0;
        screenOrigin = false;
        if (failed) return;
        if (!sharedOutputSupported(EGL14.eglGetCurrentContext())) return;
        GLES20.glGetIntegerv(GLES20.GL_FRAMEBUFFER_BINDING, value, 0);
        if (value[0] == 0) return;
        GLES20.glGetFramebufferAttachmentParameteriv(GLES20.GL_FRAMEBUFFER, GLES20.GL_COLOR_ATTACHMENT0,
                GLES20.GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE, value, 0);
        if (value[0] != GLES20.GL_TEXTURE) return;
        GLES20.glGetFramebufferAttachmentParameteriv(GLES20.GL_FRAMEBUFFER, GLES20.GL_COLOR_ATTACHMENT0,
                GLES20.GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME, value, 0);
        texture = value[0];
        if (texture != 0) request(true);
    }

    boolean captureScreen(int x, int y, int width, int height) {
        texture = 0;
        if (failed || width < 1 || height < 1) return false;
        EGLContext current = EGL14.eglGetCurrentContext();
        if (current.equals(EGL14.EGL_NO_CONTEXT)) return false;
        // GL errors remain pending until read. Separate the runner's prior work
        // from this bridge before attributing any later error to our own calls.
        if (!drainPreexistingScreenErrors()) return false;
        if (!sharedOutputSupported(current)) return false;
        if (!current.equals(screenProducer)) {
            // A lost producer context invalidates its texture names; never reuse
            // a matching numeric name from a new context after an app return.
            if (!screenProducer.equals(EGL14.EGL_NO_CONTEXT)) contextChanges++;
            screenTexture = screenWidth = screenHeight = screenFramebuffer = 0;
            screenUseBlit = false;
            screenProducer = current;
        }
        GLES20.glGetIntegerv(GLES20.GL_TEXTURE_BINDING_2D, value, 0);
        int previousTexture = value[0];
        GLES20.glGetIntegerv(GLES20.GL_FRAMEBUFFER_BINDING, value, 0);
        sourceFramebuffer = value[0];
        GLES20.glGetIntegerv(GLES30.GL_READ_FRAMEBUFFER_BINDING, value, 0);
        int previousReadFramebuffer = value[0];
        if (previousReadFramebuffer != sourceFramebuffer)
            GLES30.glBindFramebuffer(GLES30.GL_READ_FRAMEBUFFER, sourceFramebuffer);
        boolean copied = false;
        try {
            if (screenTexture == 0) {
                GLES20.glGenTextures(1, value, 0);
                screenTexture = value[0];
            }
            GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, screenTexture);
            boolean allocate = screenWidth != width || screenHeight != height;
            if (allocate) {
                GLES20.glGetIntegerv(GLES30.GL_PIXEL_UNPACK_BUFFER_BINDING, value, 0);
                int previousUnpackBuffer = value[0];
                if (previousUnpackBuffer != 0) GLES30.glBindBuffer(GLES30.GL_PIXEL_UNPACK_BUFFER, 0);
                try {
                    GLES20.glTexImage2D(GLES20.GL_TEXTURE_2D, 0, GLES20.GL_RGBA,
                            width, height, 0, GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE, null);
                } finally {
                    if (previousUnpackBuffer != 0)
                        GLES30.glBindBuffer(GLES30.GL_PIXEL_UNPACK_BUFFER, previousUnpackBuffer);
                }
                GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_NEAREST);
                GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_NEAREST);
                GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE);
                GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE);
            }
            if (screenStageSucceeded("setup")) {
                if (allocate) {
                    if (screenWidth > 0 && screenHeight > 0) screenResizes++;
                    textureAllocations++;
                    screenWidth = width; screenHeight = height;
                }
                // Some window/driver combinations reject texture copies even though
                // the framebuffer can be read. Try another GPU operation before the
                // CPU bitmap route, and remember it for this producer context.
                if (!screenUseBlit) {
                    GLES20.glCopyTexSubImage2D(GLES20.GL_TEXTURE_2D, 0, 0, 0, x, y, width, height);
                    copied = screenStageSucceeded("copy");
                    if (!copied) screenUseBlit = true;
                }
                if (screenUseBlit) copied = blitScreen(x, y, width, height);
            }
        } finally {
            // GameMaker caches this binding, so restore it on the same active
            // texture unit. No shader, buffer, viewport, or matrix state changed.
            GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, previousTexture);
            if (previousReadFramebuffer != sourceFramebuffer)
                GLES30.glBindFramebuffer(GLES30.GL_READ_FRAMEBUFFER, previousReadFramebuffer);
            if (!screenStageSucceeded("restore")) copied = false;
        }
        if (!copied) return false;
        texture = screenTexture;
        screenOrigin = true;
        copiedFrames++;
        request(true);
        return true;
    }

    private boolean blitScreen(int x, int y, int width, int height) {
        boolean scissor = GLES20.glIsEnabled(GLES20.GL_SCISSOR_TEST);
        try {
            if (screenFramebuffer == 0) {
                GLES20.glGenFramebuffers(1, value, 0);
                screenFramebuffer = value[0];
                GLES30.glBindFramebuffer(GLES30.GL_DRAW_FRAMEBUFFER, screenFramebuffer);
                GLES20.glFramebufferTexture2D(GLES30.GL_DRAW_FRAMEBUFFER, GLES20.GL_COLOR_ATTACHMENT0,
                        GLES20.GL_TEXTURE_2D, screenTexture, 0);
            } else {
                GLES30.glBindFramebuffer(GLES30.GL_DRAW_FRAMEBUFFER, screenFramebuffer);
            }
            if (GLES20.glCheckFramebufferStatus(GLES30.GL_DRAW_FRAMEBUFFER) != GLES20.GL_FRAMEBUFFER_COMPLETE) {
                blitFailures++;
                failure = "Screen blit framebuffer incomplete";
                return false;
            }
            // The runner may leave a scissor set for HUD/menu rendering. A blit
            // must copy the requested picture, independently of that drawing state.
            if (scissor) GLES20.glDisable(GLES20.GL_SCISSOR_TEST);
            GLES30.glBlitFramebuffer(x, y, x + width, y + height, 0, 0, width, height,
                    GLES20.GL_COLOR_BUFFER_BIT, GLES20.GL_NEAREST);
            if (!screenStageSucceeded("blit")) return false;
            blittedFrames++;
            return true;
        } finally {
            GLES30.glBindFramebuffer(GLES30.GL_DRAW_FRAMEBUFFER, sourceFramebuffer);
            if (scissor) GLES20.glEnable(GLES20.GL_SCISSOR_TEST);
        }
    }

    private boolean drainPreexistingScreenErrors() {
        for (int i = 0; i < SCREEN_ERROR_DRAIN_LIMIT; i++) {
            int error = GLES20.glGetError();
            if (error == GLES20.GL_NO_ERROR) return true;
            preexistingErrors++;
            lastPreexistingError = Integer.toHexString(error);
        }
        // A driver that never clears its error flag must not stall the game or
        // let an unclean boundary mislabel inherited errors as copy failures.
        preexistingDrainLimits++;
        failure = "Pending GL errors exceeded the bounded screen-capture drain";
        return false;
    }

    private boolean screenStageSucceeded(String stage) {
        int firstError = GLES20.GL_NO_ERROR;
        for (int i = 0; i < SCREEN_ERROR_DRAIN_LIMIT; i++) {
            int error = GLES20.glGetError();
            if (error == GLES20.GL_NO_ERROR) break;
            if (firstError == GLES20.GL_NO_ERROR) firstError = error;
        }
        if (firstError == GLES20.GL_NO_ERROR) return true;
        if (stage.equals("setup")) setupFailures++;
        else if (stage.equals("copy")) copyFailures++;
        else if (stage.equals("restore")) restoreFailures++;
        else if (stage.equals("blit")) blitFailures++;
        failure = "Screen " + stage + " GL " + Integer.toHexString(firstError);
        return false;
    }

    org.json.JSONObject observations() throws org.json.JSONException {
        org.json.JSONObject result = new org.json.JSONObject();
        result.put("gpu_frames", presentedFrames);
        result.put("gpu_failures", failedFrames);
        result.put("screen_copies", copiedFrames);
        result.put("screen_copy_failures", copyFailures);
        result.put("screen_blits", blittedFrames);
        result.put("screen_blit_failures", blitFailures);
        result.put("screen_copy_method", screenUseBlit ? "framebuffer-blit" : "texture-copy");
        result.put("preexisting_gl_errors", preexistingErrors);
        result.put("last_preexisting_gl_error", lastPreexistingError);
        result.put("preexisting_gl_drain_limits", preexistingDrainLimits);
        result.put("screen_setup_failures", setupFailures);
        result.put("screen_restore_failures", restoreFailures);
        result.put("screen_context_changes", contextChanges);
        result.put("screen_texture_allocations", textureAllocations);
        result.put("screen_resizes", screenResizes);
        result.put("source_framebuffer", sourceFramebuffer);
        result.put("last_failure", failure);
        return result;
    }
    boolean present(int width, int height) {
        if (failed || texture == 0) {
            // An opaque SurfaceView must leave the bitmap fallback visible.
            request(false);
            owner.gpuShown(false);
            return false;
        }
        if (!requested) return false;
        synchronized (surfaceLock) {
            if (window == null || !window.isValid() || physicalWidth < 1 || physicalHeight < 1) {
                // Keep the request alive while Android creates the new surface.
                owner.gpuShown(false);
                return false;
            }
            EGLDisplay previousDisplay = EGL14.eglGetCurrentDisplay();
            EGLContext previousContext = EGL14.eglGetCurrentContext();
            EGLSurface previousDraw = EGL14.eglGetCurrentSurface(EGL14.EGL_DRAW);
            EGLSurface previousRead = EGL14.eglGetCurrentSurface(EGL14.EGL_READ);
            long ready = 0, consumed = 0;
            boolean switched = false, success = false;
            try {
                if (!previousContext.equals(producer) || boundGeneration != generation) {
                    release(previousContext);
                    display = previousDisplay; producer = previousContext;
                    EGLConfig[] configs = new EGLConfig[1];
                    int[] count = new int[1];
                    require(EGL14.eglChooseConfig(display, new int[]{EGL14.EGL_RED_SIZE, 8, EGL14.EGL_GREEN_SIZE, 8,
                            EGL14.EGL_BLUE_SIZE, 8, EGL14.EGL_ALPHA_SIZE, 0, EGL14.EGL_DEPTH_SIZE, 0,
                            EGL14.EGL_STENCIL_SIZE, 0, EGL14.EGL_SURFACE_TYPE, EGL14.EGL_WINDOW_BIT,
                            EGL14.EGL_RENDERABLE_TYPE, android.opengl.EGLExt.EGL_OPENGL_ES3_BIT_KHR, EGL14.EGL_NONE}, 0, configs, 0, 1, count, 0)
                            && count[0] == 1, "No matching window configuration");
                    context = EGL14.eglCreateContext(display, configs[0], producer,
                            new int[]{EGL14.EGL_CONTEXT_CLIENT_VERSION, 3, EGL14.EGL_NONE}, 0);
                    require(!context.equals(EGL14.EGL_NO_CONTEXT), "Shared context unavailable");
                    output = EGL14.eglCreateWindowSurface(display, configs[0], window, new int[]{EGL14.EGL_NONE}, 0);
                    require(!output.equals(EGL14.EGL_NO_SURFACE), "Lower output unavailable");
                    boundGeneration = generation;
                }
                // The normal surface reset has already submitted the lower drawing.
                ready = GLES30.glFenceSync(GLES30.GL_SYNC_GPU_COMMANDS_COMPLETE, 0);
                require(ready != 0, "Producer fence unavailable");
                GLES20.glFlush();
                require(EGL14.eglMakeCurrent(display, output, output, context), "Unable to bind lower output");
                switched = true;
                GLES30.glWaitSync(ready, 0, GLES30.GL_TIMEOUT_IGNORED);
                GLES30.glDeleteSync(ready); ready = 0;
                if (program == 0) createDrawing();
                GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT);
                // A copied game window can be larger than the USB display.
                // Fit that complete image uniformly; native map/HUD pixels keep
                // their existing integer scale on every handheld profile.
                float scale = screenOrigin
                        ? Math.min((float) physicalWidth / width, (float) physicalHeight / height)
                        : outputScale(width, height);
                int w = Math.max(1, Math.round(width * scale)), h = Math.max(1, Math.round(height * scale));
                GLES20.glViewport((physicalWidth-w)/2, (physicalHeight-h)/2, w, h);
                GLES20.glDisable(GLES20.GL_BLEND);
                // GameMaker surfaces and a copied Android window have opposite
                // vertical origins. Flip only the copied full-window image.
                GLES20.glUniform4f(uvRegion, 0, screenOrigin ? 1 : 0, 1, screenOrigin ? -1 : 1);
                GLES20.glUniform1f(brightness, 1);
                GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, texture);
                GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4);
                if (hudTexture != 0 && hudWidth > 0 && hudHeight > 0 && (hudTop > 0 || hudBottom > 0)) {
                    // Keep each artwork pixel square. Only empty layout space
                    // expands on wider profiles; the map keeps its own scale.
                    hudPhysicalScale = Math.max(1, w / 177);
                    int left = (physicalWidth - hudWidth * hudPhysicalScale) / 2;
                    int bottom = (physicalHeight - h) / 2;
                    GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, hudTexture);
                    GLES20.glEnable(GLES20.GL_BLEND);
                    GLES20.glUniform1f(brightness, hudBrightness);
                    drawHudBand(left, bottom + h - hudTop * hudPhysicalScale, hudPhysicalScale, 0, hudTop);
                    drawHudBand(left, bottom, hudPhysicalScale, hudHeight - hudBottom, hudBottom);
                    if (hudBottom > 0 && hudHints != 0) {
                        // A separate integer output scale preserves every glyph
                        // pixel while keeping labels on their original grid.
                        float hintScale = Math.max(0.5f, hudPhysicalScale / 2);
                        int hintWidth = Math.round(32 * hintScale), hintHeight = Math.round(8 * hintScale);
                        for (int i = 0; i < 3; i++) if ((hudHints & (1 << i)) != 0) {
                            int end = i == 2 ? hudWidth : hudWidth * (i + 1) / 3 - 1;
                            int x = left + (end - 2) * hudPhysicalScale - hintWidth;
                            int y = bottom + 14 * hudPhysicalScale - hintHeight;
                            GLES20.glViewport(x, y, hintWidth, hintHeight);
                            GLES20.glUniform4f(uvRegion, (float) (i * 32) / hudWidth,
                                    56f / hudHeight, 32f / hudWidth, 8f / hudHeight);
                            GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4);
                        }
                    }
                    if (hudTop > 0 && titleScale > 0) {
                        int x = left + Math.round(titleX * hudPhysicalScale - hudWidth * titleScale / 2f);
                        int y = bottom + h - Math.round(titleY * hudPhysicalScale + 16 * titleScale);
                        drawHudBand(x, y, titleScale, 64, 32);
                    }
                }
                consumed = GLES30.glFenceSync(GLES30.GL_SYNC_GPU_COMMANDS_COMPLETE, 0);
                require(consumed != 0, "Consumer fence unavailable");
                GLES20.glFlush();
                require(EGL14.eglSwapBuffers(display, output), "Lower swap failed");
                success = true;
                presentedFrames++;
            } catch (RuntimeException error) {
                failedFrames++;
                failed = true; failure = error.getMessage();
                android.util.Log.w("AM2RGpuOutput", failure, error);
            } finally {
                if (switched) {
                    // Restoring both surfaces and the original context preserves all runner state.
                    if (!EGL14.eglMakeCurrent(previousDisplay, previousDraw, previousRead, previousContext)) {
                        throw new IllegalStateException("Unable to restore game graphics context");
                    }
                    if (consumed != 0) {
                        GLES30.glWaitSync(consumed, 0, GLES30.GL_TIMEOUT_IGNORED);
                        GLES30.glDeleteSync(consumed);
                    }
                }
                if (ready != 0) GLES30.glDeleteSync(ready);
            }
            if (!success) request(false);
            owner.gpuShown(success);
            return success;
        }
    }
    void disable() {
        capabilityContext = EGL14.EGL_NO_CONTEXT;
        supportsSharedOutput = false;
        texture = hudTexture = hudTop = hudBottom = titleScale = hudHints = 0;
        failed = false;
        failure = "";
        request(false);
        owner.gpuShown(false);
        synchronized (surfaceLock) {
            EGLContext current = EGL14.eglGetCurrentContext();
            release(current);
            if (screenTexture != 0 && current.equals(screenProducer)
                    && !current.equals(EGL14.EGL_NO_CONTEXT)) {
                if (screenFramebuffer != 0)
                    GLES20.glDeleteFramebuffers(1, new int[]{screenFramebuffer}, 0);
                GLES20.glDeleteTextures(1, new int[]{screenTexture}, 0);
            }
            screenTexture = screenWidth = screenHeight = screenFramebuffer = 0;
            screenUseBlit = false;
            screenProducer = EGL14.EGL_NO_CONTEXT;
        }
    }
    private void release(EGLContext current) {
        // These shared objects can be deleted from the producer context without rebinding its state.
        if (current.equals(producer) && !current.equals(EGL14.EGL_NO_CONTEXT)) {
            if (program != 0) GLES20.glDeleteProgram(program);
            if (vertices != 0) GLES20.glDeleteBuffers(1, new int[]{vertices}, 0);
            if (sampler != 0) GLES30.glDeleteSamplers(1, new int[]{sampler}, 0);
        }
        if (!output.equals(EGL14.EGL_NO_SURFACE)) EGL14.eglDestroySurface(display, output);
        if (!context.equals(EGL14.EGL_NO_CONTEXT)) EGL14.eglDestroyContext(display, context);
        output = EGL14.EGL_NO_SURFACE; context = EGL14.EGL_NO_CONTEXT;
        program = vertices = sampler = 0; boundGeneration = -1;
    }
    private static void require(boolean value, String message) {
        if (!value) throw new IllegalStateException(message + " (EGL " + Integer.toHexString(EGL14.eglGetError()) + ")");
    }
    private int shader(int type, String code) {
        int shader = GLES20.glCreateShader(type);
        GLES20.glShaderSource(shader, code); GLES20.glCompileShader(shader);
        GLES20.glGetShaderiv(shader, GLES20.GL_COMPILE_STATUS, value, 0);
        if (value[0] == 0) throw new IllegalStateException(GLES20.glGetShaderInfoLog(shader));
        return shader;
    }
    private void createDrawing() {
        int vertex = shader(GLES20.GL_VERTEX_SHADER,
            "attribute vec2 p; attribute vec2 t; varying vec2 uv; void main(){gl_Position=vec4(p,0.,1.);uv=t;}");
        int fragment = shader(GLES20.GL_FRAGMENT_SHADER,
            "precision highp float; varying vec2 uv; uniform sampler2D image; uniform vec4 region; uniform float brightness; void main(){vec4 color=texture2D(image,region.xy+uv*region.zw);gl_FragColor=vec4(color.rgb*brightness,color.a);}");
        program = GLES20.glCreateProgram();
        GLES20.glAttachShader(program, vertex); GLES20.glAttachShader(program, fragment);
        GLES20.glBindAttribLocation(program, 0, "p"); GLES20.glBindAttribLocation(program, 1, "t");
        GLES20.glLinkProgram(program);
        GLES20.glDeleteShader(vertex); GLES20.glDeleteShader(fragment);
        GLES20.glGetProgramiv(program, GLES20.GL_LINK_STATUS, value, 0);
        if (value[0] == 0) throw new IllegalStateException(GLES20.glGetProgramInfoLog(program));
        uvRegion = GLES20.glGetUniformLocation(program, "region");
        brightness = GLES20.glGetUniformLocation(program, "brightness");
        float[] quad = {-1,-1,0,1, 1,-1,1,1, -1,1,0,0, 1,1,1,0};
        FloatBuffer data = ByteBuffer.allocateDirect(quad.length*4).order(ByteOrder.nativeOrder()).asFloatBuffer();
        data.put(quad).position(0);
        GLES20.glGenBuffers(1, value, 0); vertices = value[0];
        GLES20.glBindBuffer(GLES20.GL_ARRAY_BUFFER, vertices);
        GLES20.glBufferData(GLES20.GL_ARRAY_BUFFER, quad.length*4, data, GLES20.GL_STATIC_DRAW);
        GLES30.glGenSamplers(1, value, 0); sampler = value[0];
        GLES30.glSamplerParameteri(sampler, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_NEAREST);
        GLES30.glSamplerParameteri(sampler, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_NEAREST);
        GLES30.glSamplerParameteri(sampler, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE);
        GLES30.glSamplerParameteri(sampler, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE);
        // Only this bridge uses the output context. These bindings and values
        // survive make-current changes; release() rebuilds them for a new context
        // or Android window. Texture, viewport, blend enable and uniforms remain
        // per-draw because the map and HUD differ. No runner state is changed.
        require(EGL14.eglSwapInterval(display, 0), "Unable to set lower interval");
        GLES20.glDisable(GLES20.GL_DITHER);
        GLES20.glClearColor(0, 0, 0, 1);
        GLES20.glUseProgram(program);
        GLES20.glActiveTexture(GLES20.GL_TEXTURE0);
        GLES30.glBindSampler(0, sampler);
        GLES20.glEnableVertexAttribArray(0);
        GLES20.glEnableVertexAttribArray(1);
        GLES20.glVertexAttribPointer(0, 2, GLES20.GL_FLOAT, false, 16, 0);
        GLES20.glVertexAttribPointer(1, 2, GLES20.GL_FLOAT, false, 16, 8);
        GLES20.glBlendFunc(GLES20.GL_ONE, GLES20.GL_ONE_MINUS_SRC_ALPHA);
    }

}
