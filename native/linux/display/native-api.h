/* Vendor entry points, resolved from the active system GLES/EGL libraries. */
static __typeof__(&eglChooseConfig) p_eglChooseConfig;
static __typeof__(&eglCreateContext) p_eglCreateContext;
static __typeof__(&eglCreateSyncKHR) p_eglCreateSyncKHR;
static __typeof__(&eglCreateWindowSurface) p_eglCreateWindowSurface;
static __typeof__(&eglDestroySyncKHR) p_eglDestroySyncKHR;
static __typeof__(&eglGetCurrentContext) p_eglGetCurrentContext;
static __typeof__(&eglGetCurrentDisplay) p_eglGetCurrentDisplay;
static __typeof__(&eglGetCurrentSurface) p_eglGetCurrentSurface;
static __typeof__(&eglMakeCurrent) p_eglMakeCurrent;
static __typeof__(&eglQueryContext) p_eglQueryContext;
static __typeof__(&eglSwapBuffers) p_eglSwapBuffers;
static __typeof__(&eglSwapInterval) p_eglSwapInterval;
static __typeof__(&eglWaitSyncKHR) p_eglWaitSyncKHR;
static __typeof__(&glActiveTexture) p_glActiveTexture;
static __typeof__(&glAttachShader) p_glAttachShader;
static __typeof__(&glBindAttribLocation) p_glBindAttribLocation;
static __typeof__(&glBindBuffer) p_glBindBuffer;
static __typeof__(&glBindSampler) p_glBindSampler;
static __typeof__(&glBindTexture) p_glBindTexture;
static __typeof__(&glBlendFunc) p_glBlendFunc;
static __typeof__(&glBufferData) p_glBufferData;
static __typeof__(&glClear) p_glClear;
static __typeof__(&glClearColor) p_glClearColor;
static __typeof__(&glCompileShader) p_glCompileShader;
static __typeof__(&glCreateProgram) p_glCreateProgram;
static __typeof__(&glCreateShader) p_glCreateShader;
static __typeof__(&glDeleteShader) p_glDeleteShader;
static __typeof__(&glDisable) p_glDisable;
static __typeof__(&glDrawArrays) p_glDrawArrays;
static __typeof__(&glEnable) p_glEnable;
static __typeof__(&glEnableVertexAttribArray) p_glEnableVertexAttribArray;
static __typeof__(&glFlush) p_glFlush;
static __typeof__(&glGenBuffers) p_glGenBuffers;
static __typeof__(&glGenSamplers) p_glGenSamplers;
static __typeof__(&glGetFramebufferAttachmentParameteriv) p_glGetFramebufferAttachmentParameteriv;
static __typeof__(&glGetIntegerv) p_glGetIntegerv;
static __typeof__(&glGetProgramiv) p_glGetProgramiv;
static __typeof__(&glGetShaderInfoLog) p_glGetShaderInfoLog;
static __typeof__(&glGetShaderiv) p_glGetShaderiv;
static __typeof__(&glGetUniformLocation) p_glGetUniformLocation;
static __typeof__(&glLinkProgram) p_glLinkProgram;
static __typeof__(&glReadPixels) p_glReadPixels;
static __typeof__(&glSamplerParameteri) p_glSamplerParameteri;
static __typeof__(&glShaderSource) p_glShaderSource;
static __typeof__(&glUniform1f) p_glUniform1f;
static __typeof__(&glUniform1i) p_glUniform1i;
static __typeof__(&glUniform4f) p_glUniform4f;
static __typeof__(&glUseProgram) p_glUseProgram;
static __typeof__(&glVertexAttribPointer) p_glVertexAttribPointer;
static __typeof__(&glViewport) p_glViewport;
static int native_load_api(void *egl,void *gles){
    PFNEGLGETPROCADDRESSPROC get=(PFNEGLGETPROCADDRESSPROC)dlsym(egl,"eglGetProcAddress");
    p_eglChooseConfig=dlsym(egl,"eglChooseConfig");
    if(!p_eglChooseConfig){fprintf(stderr,"Missing vendor entry eglChooseConfig\n");return 0;}
    p_eglCreateContext=dlsym(egl,"eglCreateContext");
    if(!p_eglCreateContext){fprintf(stderr,"Missing vendor entry eglCreateContext\n");return 0;}
    p_eglCreateSyncKHR=dlsym(egl,"eglCreateSyncKHR");
    if(!p_eglCreateSyncKHR && get)p_eglCreateSyncKHR=(__typeof__(p_eglCreateSyncKHR))get("eglCreateSyncKHR");
    if(!p_eglCreateSyncKHR){fprintf(stderr,"Missing vendor entry eglCreateSyncKHR\n");return 0;}
    p_eglCreateWindowSurface=dlsym(egl,"eglCreateWindowSurface");
    if(!p_eglCreateWindowSurface){fprintf(stderr,"Missing vendor entry eglCreateWindowSurface\n");return 0;}
    p_eglDestroySyncKHR=dlsym(egl,"eglDestroySyncKHR");
    if(!p_eglDestroySyncKHR && get)p_eglDestroySyncKHR=(__typeof__(p_eglDestroySyncKHR))get("eglDestroySyncKHR");
    if(!p_eglDestroySyncKHR){fprintf(stderr,"Missing vendor entry eglDestroySyncKHR\n");return 0;}
    p_eglGetCurrentContext=dlsym(egl,"eglGetCurrentContext");
    if(!p_eglGetCurrentContext){fprintf(stderr,"Missing vendor entry eglGetCurrentContext\n");return 0;}
    p_eglGetCurrentDisplay=dlsym(egl,"eglGetCurrentDisplay");
    if(!p_eglGetCurrentDisplay){fprintf(stderr,"Missing vendor entry eglGetCurrentDisplay\n");return 0;}
    p_eglGetCurrentSurface=dlsym(egl,"eglGetCurrentSurface");
    if(!p_eglGetCurrentSurface){fprintf(stderr,"Missing vendor entry eglGetCurrentSurface\n");return 0;}
    p_eglMakeCurrent=dlsym(egl,"eglMakeCurrent");
    if(!p_eglMakeCurrent){fprintf(stderr,"Missing vendor entry eglMakeCurrent\n");return 0;}
    p_eglQueryContext=dlsym(egl,"eglQueryContext");
    if(!p_eglQueryContext){fprintf(stderr,"Missing vendor entry eglQueryContext\n");return 0;}
    p_eglSwapBuffers=dlsym(egl,"eglSwapBuffers");
    if(!p_eglSwapBuffers){fprintf(stderr,"Missing vendor entry eglSwapBuffers\n");return 0;}
    p_eglSwapInterval=dlsym(egl,"eglSwapInterval");
    if(!p_eglSwapInterval){fprintf(stderr,"Missing vendor entry eglSwapInterval\n");return 0;}
    p_eglWaitSyncKHR=dlsym(egl,"eglWaitSyncKHR");
    if(!p_eglWaitSyncKHR && get)p_eglWaitSyncKHR=(__typeof__(p_eglWaitSyncKHR))get("eglWaitSyncKHR");
    if(!p_eglWaitSyncKHR){fprintf(stderr,"Missing vendor entry eglWaitSyncKHR\n");return 0;}
    p_glActiveTexture=dlsym(gles,"glActiveTexture");
    if(!p_glActiveTexture){fprintf(stderr,"Missing vendor entry glActiveTexture\n");return 0;}
    p_glAttachShader=dlsym(gles,"glAttachShader");
    if(!p_glAttachShader){fprintf(stderr,"Missing vendor entry glAttachShader\n");return 0;}
    p_glBindAttribLocation=dlsym(gles,"glBindAttribLocation");
    if(!p_glBindAttribLocation){fprintf(stderr,"Missing vendor entry glBindAttribLocation\n");return 0;}
    p_glBindBuffer=dlsym(gles,"glBindBuffer");
    if(!p_glBindBuffer){fprintf(stderr,"Missing vendor entry glBindBuffer\n");return 0;}
    p_glBindSampler=dlsym(gles,"glBindSampler");
    if(!p_glBindSampler){fprintf(stderr,"Missing vendor entry glBindSampler\n");return 0;}
    p_glBindTexture=dlsym(gles,"glBindTexture");
    if(!p_glBindTexture){fprintf(stderr,"Missing vendor entry glBindTexture\n");return 0;}
    p_glBlendFunc=dlsym(gles,"glBlendFunc");
    if(!p_glBlendFunc){fprintf(stderr,"Missing vendor entry glBlendFunc\n");return 0;}
    p_glBufferData=dlsym(gles,"glBufferData");
    if(!p_glBufferData){fprintf(stderr,"Missing vendor entry glBufferData\n");return 0;}
    p_glClear=dlsym(gles,"glClear");
    if(!p_glClear){fprintf(stderr,"Missing vendor entry glClear\n");return 0;}
    p_glClearColor=dlsym(gles,"glClearColor");
    if(!p_glClearColor){fprintf(stderr,"Missing vendor entry glClearColor\n");return 0;}
    p_glCompileShader=dlsym(gles,"glCompileShader");
    if(!p_glCompileShader){fprintf(stderr,"Missing vendor entry glCompileShader\n");return 0;}
    p_glCreateProgram=dlsym(gles,"glCreateProgram");
    if(!p_glCreateProgram){fprintf(stderr,"Missing vendor entry glCreateProgram\n");return 0;}
    p_glCreateShader=dlsym(gles,"glCreateShader");
    if(!p_glCreateShader){fprintf(stderr,"Missing vendor entry glCreateShader\n");return 0;}
    p_glDeleteShader=dlsym(gles,"glDeleteShader");
    if(!p_glDeleteShader){fprintf(stderr,"Missing vendor entry glDeleteShader\n");return 0;}
    p_glDisable=dlsym(gles,"glDisable");
    if(!p_glDisable){fprintf(stderr,"Missing vendor entry glDisable\n");return 0;}
    p_glDrawArrays=dlsym(gles,"glDrawArrays");
    if(!p_glDrawArrays){fprintf(stderr,"Missing vendor entry glDrawArrays\n");return 0;}
    p_glEnable=dlsym(gles,"glEnable");
    if(!p_glEnable){fprintf(stderr,"Missing vendor entry glEnable\n");return 0;}
    p_glEnableVertexAttribArray=dlsym(gles,"glEnableVertexAttribArray");
    if(!p_glEnableVertexAttribArray){fprintf(stderr,"Missing vendor entry glEnableVertexAttribArray\n");return 0;}
    p_glFlush=dlsym(gles,"glFlush");
    if(!p_glFlush){fprintf(stderr,"Missing vendor entry glFlush\n");return 0;}
    p_glGenBuffers=dlsym(gles,"glGenBuffers");
    if(!p_glGenBuffers){fprintf(stderr,"Missing vendor entry glGenBuffers\n");return 0;}
    p_glGenSamplers=dlsym(gles,"glGenSamplers");
    if(!p_glGenSamplers){fprintf(stderr,"Missing vendor entry glGenSamplers\n");return 0;}
    p_glGetFramebufferAttachmentParameteriv=dlsym(gles,"glGetFramebufferAttachmentParameteriv");
    if(!p_glGetFramebufferAttachmentParameteriv){fprintf(stderr,"Missing vendor entry glGetFramebufferAttachmentParameteriv\n");return 0;}
    p_glGetIntegerv=dlsym(gles,"glGetIntegerv");
    if(!p_glGetIntegerv){fprintf(stderr,"Missing vendor entry glGetIntegerv\n");return 0;}
    p_glGetProgramiv=dlsym(gles,"glGetProgramiv");
    if(!p_glGetProgramiv){fprintf(stderr,"Missing vendor entry glGetProgramiv\n");return 0;}
    p_glGetShaderInfoLog=dlsym(gles,"glGetShaderInfoLog");
    if(!p_glGetShaderInfoLog){fprintf(stderr,"Missing vendor entry glGetShaderInfoLog\n");return 0;}
    p_glGetShaderiv=dlsym(gles,"glGetShaderiv");
    if(!p_glGetShaderiv){fprintf(stderr,"Missing vendor entry glGetShaderiv\n");return 0;}
    p_glGetUniformLocation=dlsym(gles,"glGetUniformLocation");
    if(!p_glGetUniformLocation){fprintf(stderr,"Missing vendor entry glGetUniformLocation\n");return 0;}
    p_glLinkProgram=dlsym(gles,"glLinkProgram");
    if(!p_glLinkProgram){fprintf(stderr,"Missing vendor entry glLinkProgram\n");return 0;}
    p_glReadPixels=dlsym(gles,"glReadPixels");
    if(!p_glReadPixels){fprintf(stderr,"Missing vendor entry glReadPixels\n");return 0;}
    p_glSamplerParameteri=dlsym(gles,"glSamplerParameteri");
    if(!p_glSamplerParameteri){fprintf(stderr,"Missing vendor entry glSamplerParameteri\n");return 0;}
    p_glShaderSource=dlsym(gles,"glShaderSource");
    if(!p_glShaderSource){fprintf(stderr,"Missing vendor entry glShaderSource\n");return 0;}
    p_glUniform1f=dlsym(gles,"glUniform1f");
    if(!p_glUniform1f){fprintf(stderr,"Missing vendor entry glUniform1f\n");return 0;}
    p_glUniform1i=dlsym(gles,"glUniform1i");
    if(!p_glUniform1i){fprintf(stderr,"Missing vendor entry glUniform1i\n");return 0;}
    p_glUniform4f=dlsym(gles,"glUniform4f");
    if(!p_glUniform4f){fprintf(stderr,"Missing vendor entry glUniform4f\n");return 0;}
    p_glUseProgram=dlsym(gles,"glUseProgram");
    if(!p_glUseProgram){fprintf(stderr,"Missing vendor entry glUseProgram\n");return 0;}
    p_glVertexAttribPointer=dlsym(gles,"glVertexAttribPointer");
    if(!p_glVertexAttribPointer){fprintf(stderr,"Missing vendor entry glVertexAttribPointer\n");return 0;}
    p_glViewport=dlsym(gles,"glViewport");
    if(!p_glViewport){fprintf(stderr,"Missing vendor entry glViewport\n");return 0;}
    return 1;
}
#define eglChooseConfig p_eglChooseConfig
#define eglCreateContext p_eglCreateContext
#define eglCreateSyncKHR p_eglCreateSyncKHR
#define eglCreateWindowSurface p_eglCreateWindowSurface
#define eglDestroySyncKHR p_eglDestroySyncKHR
#define eglGetCurrentContext p_eglGetCurrentContext
#define eglGetCurrentDisplay p_eglGetCurrentDisplay
#define eglGetCurrentSurface p_eglGetCurrentSurface
#define eglMakeCurrent p_eglMakeCurrent
#define eglQueryContext p_eglQueryContext
#define eglSwapBuffers p_eglSwapBuffers
#define eglSwapInterval p_eglSwapInterval
#define eglWaitSyncKHR p_eglWaitSyncKHR
#define glActiveTexture p_glActiveTexture
#define glAttachShader p_glAttachShader
#define glBindAttribLocation p_glBindAttribLocation
#define glBindBuffer p_glBindBuffer
#define glBindSampler p_glBindSampler
#define glBindTexture p_glBindTexture
#define glBlendFunc p_glBlendFunc
#define glBufferData p_glBufferData
#define glClear p_glClear
#define glClearColor p_glClearColor
#define glCompileShader p_glCompileShader
#define glCreateProgram p_glCreateProgram
#define glCreateShader p_glCreateShader
#define glDeleteShader p_glDeleteShader
#define glDisable p_glDisable
#define glDrawArrays p_glDrawArrays
#define glEnable p_glEnable
#define glEnableVertexAttribArray p_glEnableVertexAttribArray
#define glFlush p_glFlush
#define glGenBuffers p_glGenBuffers
#define glGenSamplers p_glGenSamplers
#define glGetFramebufferAttachmentParameteriv p_glGetFramebufferAttachmentParameteriv
#define glGetIntegerv p_glGetIntegerv
#define glGetProgramiv p_glGetProgramiv
#define glGetShaderInfoLog p_glGetShaderInfoLog
#define glGetShaderiv p_glGetShaderiv
#define glGetUniformLocation p_glGetUniformLocation
#define glLinkProgram p_glLinkProgram
#define glReadPixels p_glReadPixels
#define glSamplerParameteri p_glSamplerParameteri
#define glShaderSource p_glShaderSource
#define glUniform1f p_glUniform1f
#define glUniform1i p_glUniform1i
#define glUniform4f p_glUniform4f
#define glUseProgram p_glUseProgram
#define glVertexAttribPointer p_glVertexAttribPointer
#define glViewport p_glViewport
