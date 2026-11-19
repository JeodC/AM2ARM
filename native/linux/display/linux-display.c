/* Native Linux implementation of the existing AM2R lower-display interface. */
#define EGL_EGLEXT_PROTOTYPES
#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES3/gl3.h>
#include <dlfcn.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "native-api.h"
#define PUBLIC __attribute__((visibility("default")))
static void *egl_library,*gles_library;
static void *(*lower_window)(void);
static int (*lower_width)(void),(*lower_height)(void),(*route)(int);
static const char *(*lower_input)(double,double);
static unsigned long (*input_events)(void);
static void (*flush_producer)(void);
static int loaded,failed;
static char failure[160];
static EGLDisplay display=EGL_NO_DISPLAY;
static EGLContext producer=EGL_NO_CONTEXT,consumer=EGL_NO_CONTEXT;
static EGLSurface output=EGL_NO_SURFACE;
static GLuint scene_texture,hud_texture,program,vertices,sampler;
static GLint region_uniform,brightness_uniform;
static int logical_width=320,logical_height=240,hud_width,hud_height,hud_top,hud_bottom,title_scale,hints;
static float brightness=1,title_x,title_y;
static unsigned long presented,failures,restores,missing_targets;
static int fail(const char *message){
    failed=1;failures++;snprintf(failure,sizeof(failure),"%s",message);
    fprintf(stderr,"NATIVE_DISPLAY failure: %s\n",message);return 0;
}
static int load_api(void){
    if(loaded)return !failed;
    loaded=1;
    egl_library=dlopen("/usr/lib/libEGL.so.1",RTLD_NOW|RTLD_LOCAL);
    gles_library=dlopen("/usr/lib/libGLESv2.so.2",RTLD_NOW|RTLD_LOCAL);
    if(!egl_library || !gles_library)return fail("Vendor EGL/GLES libraries unavailable");
    if(!native_load_api(egl_library,gles_library))return fail("Required graphics functions unavailable");
    lower_window=dlsym(RTLD_DEFAULT,"am2r_native_lower_window");
    lower_width=dlsym(RTLD_DEFAULT,"am2r_native_lower_width");
    lower_height=dlsym(RTLD_DEFAULT,"am2r_native_lower_height");
    lower_input=dlsym(RTLD_DEFAULT,"am2r_native_lower_input");
    route=dlsym(RTLD_DEFAULT,"am2r_native_route");
    input_events=dlsym(RTLD_DEFAULT,"am2r_native_touch_events");
    flush_producer=dlsym(RTLD_DEFAULT,"glFlush");
    if(!lower_window || !lower_width || !lower_height || !lower_input || !route || !input_events || !flush_producer)
        return fail("Native Wayland adapter missing");
    return 1;
}
static GLuint capture_target(void){
    if(!load_api() || failed)return 0;
    flush_producer();
    GLint binding=0,type=0,texture=0;
    glGetIntegerv(GL_FRAMEBUFFER_BINDING,&binding);
    if(!binding){missing_targets++;return 0;}
    glGetFramebufferAttachmentParameteriv(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0,GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE,&type);
    if(type!=GL_TEXTURE){missing_targets++;return 0;}
    glGetFramebufferAttachmentParameteriv(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0,GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME,&texture);
    return (GLuint)texture;
}
static int scene_scale(int w,int h){
    if(w<1 || h<1)return 1;
    int s=(int)fmax(1,fmin(lower_width()/w,lower_height()/h));
    if(w*(s+1)-lower_width()<=2 && h*(s+1)-lower_height()<=2)s++;
    return s;
}
static GLuint compile_shader(GLenum type,const char *source){
    GLuint s=glCreateShader(type);glShaderSource(s,1,&source,NULL);glCompileShader(s);
    GLint good=0;glGetShaderiv(s,GL_COMPILE_STATUS,&good);
    if(!good){char log[512];glGetShaderInfoLog(s,sizeof(log),NULL,log);fprintf(stderr,"Native shader: %s\n",log);glDeleteShader(s);return 0;}
    return s;
}
static int drawing(void){
    GLuint vs=compile_shader(GL_VERTEX_SHADER,"attribute vec2 p;attribute vec2 t;varying vec2 uv;void main(){gl_Position=vec4(p,0.,1.);uv=t;}");
    GLuint fs=compile_shader(GL_FRAGMENT_SHADER,"precision highp float;varying vec2 uv;uniform sampler2D image;uniform vec4 region;uniform float brightness;void main(){vec4 c=texture2D(image,region.xy+uv*region.zw);gl_FragColor=vec4(c.rgb*brightness,c.a);}");
    if(!vs || !fs)return fail("Lower-output shader compile failed");
    program=glCreateProgram();glAttachShader(program,vs);glAttachShader(program,fs);
    glBindAttribLocation(program,0,"p");glBindAttribLocation(program,1,"t");glLinkProgram(program);
    glDeleteShader(vs);glDeleteShader(fs);GLint good=0;glGetProgramiv(program,GL_LINK_STATUS,&good);
    if(!good)return fail("Lower-output shader link failed");
    region_uniform=glGetUniformLocation(program,"region");brightness_uniform=glGetUniformLocation(program,"brightness");
    const float quad[]={-1,-1,0,1,1,-1,1,1,-1,1,0,0,1,1,1,0};
    glGenBuffers(1,&vertices);glBindBuffer(GL_ARRAY_BUFFER,vertices);glBufferData(GL_ARRAY_BUFFER,sizeof(quad),quad,GL_STATIC_DRAW);
    glGenSamplers(1,&sampler);glSamplerParameteri(sampler,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
    glSamplerParameteri(sampler,GL_TEXTURE_MAG_FILTER,GL_NEAREST);glSamplerParameteri(sampler,GL_TEXTURE_WRAP_S,GL_CLAMP_TO_EDGE);
    glSamplerParameteri(sampler,GL_TEXTURE_WRAP_T,GL_CLAMP_TO_EDGE);glBindSampler(0,sampler);
    glDisable(GL_DITHER);glDisable(GL_DEPTH_TEST);glDisable(GL_SCISSOR_TEST);glClearColor(0,0,0,1);
    glUseProgram(program);glActiveTexture(GL_TEXTURE0);glUniform1i(glGetUniformLocation(program,"image"),0);
    glEnableVertexAttribArray(0);glEnableVertexAttribArray(1);
    glVertexAttribPointer(0,2,GL_FLOAT,GL_FALSE,16,(void*)0);glVertexAttribPointer(1,2,GL_FLOAT,GL_FALSE,16,(void*)8);
    glBlendFunc(GL_ONE,GL_ONE_MINUS_SRC_ALPHA);
    if(!eglSwapInterval(display,0))return fail("Lower swap interval rejected");
    return 1;
}
static void hud_band(int x,int y,int scale,int source_y,int rows){
    if(rows<=0)return;
    glViewport(x,y,hud_width*scale,rows*scale);
    glUniform4f(region_uniform,0,(float)source_y/hud_height,1,(float)rows/hud_height);
    glDrawArrays(GL_TRIANGLE_STRIP,0,4);
}
static int present(int w,int h){
    if(!load_api() || failed || !scene_texture || w<1 || h<1)return 0;
    EGLDisplay old_display=eglGetCurrentDisplay();EGLContext old_context=eglGetCurrentContext();
    EGLSurface old_draw=eglGetCurrentSurface(EGL_DRAW),old_read=eglGetCurrentSurface(EGL_READ);
    if(old_display==EGL_NO_DISPLAY || old_context==EGL_NO_CONTEXT)return fail("No producer context");
    if(consumer!=EGL_NO_CONTEXT && old_context!=producer)return fail("Producer context changed; restart the game");
    if(consumer==EGL_NO_CONTEXT){
        void *window=lower_window();if(!window)return fail("Second Wayland output unavailable");
        EGLint config_id=0,n=0;EGLConfig config;
        if(!eglQueryContext(old_display,old_context,EGL_CONFIG_ID,&config_id))return fail("Producer config unavailable");
        EGLint attrs[]={EGL_CONFIG_ID,config_id,EGL_NONE};
        if(!eglChooseConfig(old_display,attrs,&config,1,&n) || n!=1)return fail("Matching EGL config unavailable");
        EGLint context_attrs[]={EGL_CONTEXT_CLIENT_VERSION,3,EGL_NONE};
        display=old_display;producer=old_context;
        consumer=eglCreateContext(display,config,producer,context_attrs);
        if(consumer==EGL_NO_CONTEXT)return fail("Shared output context creation failed");
        output=eglCreateWindowSurface(display,config,(EGLNativeWindowType)window,NULL);
        if(output==EGL_NO_SURFACE)return fail("Lower EGL surface creation failed");
        fprintf(stderr,"NATIVE_DISPLAY shared output context created\n");
    }
    EGLSyncKHR ready=eglCreateSyncKHR(display,EGL_SYNC_FENCE_KHR,NULL);
    if(ready==EGL_NO_SYNC_KHR)return fail("Producer fence unavailable");
    glFlush();
    if(!eglMakeCurrent(display,output,output,consumer)){eglDestroySyncKHR(display,ready);return fail("Cannot bind lower output");}
    int ok=eglWaitSyncKHR(display,ready,0);eglDestroySyncKHR(display,ready);
    if(!ok)fail("Producer GPU wait failed");
    if(ok && !program)ok=drawing();
    EGLSyncKHR consumed=EGL_NO_SYNC_KHR;
    if(ok){
        glClear(GL_COLOR_BUFFER_BIT);int scale=scene_scale(w,h),pw=lower_width(),ph=lower_height();
        int out_w=w*scale,out_h=h*scale,left=(pw-out_w)/2,bottom=(ph-out_h)/2;
        glViewport(left,bottom,out_w,out_h);glDisable(GL_BLEND);
        glUniform4f(region_uniform,0,0,1,1);glUniform1f(brightness_uniform,1);
        glBindTexture(GL_TEXTURE_2D,scene_texture);glDrawArrays(GL_TRIANGLE_STRIP,0,4);
        if(hud_texture && hud_width>0 && hud_height>0 && (hud_top>0 || hud_bottom>0)){
            int pixels=(int)fmax(1,out_w/177);int hud_left=(pw-hud_width*pixels)/2;
            glBindTexture(GL_TEXTURE_2D,hud_texture);glEnable(GL_BLEND);glUniform1f(brightness_uniform,brightness);
            hud_band(hud_left,bottom+out_h-hud_top*pixels,pixels,0,hud_top);
            hud_band(hud_left,bottom,pixels,hud_height-hud_bottom,hud_bottom);
            if(hud_bottom>0 && hints){
                float hs=fmax(.5,pixels/2);int hw=(int)round(32*hs),hh=(int)round(8*hs);
                for(int i=0;i<3;i++)if(hints&(1<<i)){
                    int end=i==2?hud_width:hud_width*(i+1)/3-1;
                    glViewport(hud_left+(end-2)*pixels-hw,bottom+14*pixels-hh,hw,hh);
                    glUniform4f(region_uniform,(float)(i*32)/hud_width,56.0f/hud_height,32.0f/hud_width,8.0f/hud_height);
                    glDrawArrays(GL_TRIANGLE_STRIP,0,4);
                }
            }
            if(hud_top>0 && title_scale>0){
                int tx=hud_left+(int)round(title_x*pixels-hud_width*title_scale/2.0f);
                int ty=bottom+out_h-(int)round(title_y*pixels+16*title_scale);
                hud_band(tx,ty,title_scale,64,32);
            }
        }
        consumed=eglCreateSyncKHR(display,EGL_SYNC_FENCE_KHR,NULL);glFlush();
        if(consumed==EGL_NO_SYNC_KHR)ok=fail("Consumer fence unavailable");
        else if(!eglSwapBuffers(display,output))ok=fail("Lower swap failed");
        if(ok)presented++;
    }
    if(!eglMakeCurrent(old_display,old_draw,old_read,old_context))return fail("Cannot restore game context");
    restores++;
    if(consumed!=EGL_NO_SYNC_KHR){
        if(!eglWaitSyncKHR(display,consumed,0))ok=fail("Consumer GPU wait failed");
        eglDestroySyncKHR(display,consumed);
    }
    return ok;
}
PUBLIC double Thor_Start(void){return load_api() && lower_window()!=NULL;}
PUBLIC double Thor_Ready(void){return !failed && Thor_Start();}
PUBLIC double Thor_SetSize(double w,double h){if(w>=1 && h>=1){logical_width=(int)w;logical_height=(int)h;}return 1;}
PUBLIC double Thor_GPU(double phase,double w,double h){
    if(!load_api() || failed)return 0;
    switch((int)phase){
    case 0:scene_texture=capture_target();return scene_texture!=0;
    case 1:return present((int)w,(int)h);
    case 2:scene_texture=hud_texture=0;return 1;
    case 3:return (double)(int)fmax(1,(int)w*scene_scale(w,h)/177)/scene_scale(w,h);
    case 7:return fmax(1,(int)w*scene_scale(w,h)/177);
    case 10:return fmax(1,(int)w*scene_scale(w,h)/177)*65536+scene_scale(w,h);
    }return 0;
}
PUBLIC double Thor_Hud(double w,double h,double top,double bottom,double fade,double tx,double ty,double ts,double hint_mask){
    hud_texture=w>0 && h>0?capture_target():0;hud_width=w;hud_height=h;
    hud_top=top;hud_bottom=bottom;brightness=fmax(0,fmin(1,fade));title_x=tx;title_y=ty;title_scale=ts;hints=(int)hint_mask&7;
    return 1;
}
PUBLIC double Thor_Frame(double buffer){(void)buffer;return fail("CPU frame fallback is not supported by native output");}
PUBLIC const char *Thor_Input(void){return load_api() && !failed?lower_input(logical_width,logical_height):"";}
PUBLIC double Thor_Swap(double profile,double reverse){(void)profile;return load_api() && !failed?route(reverse!=0):0;}
PUBLIC double Thor_SwapFrame(double x,double y,double w,double h){(void)x;(void)y;(void)w;(void)h;return 0;}
PUBLIC const char *Thor_DisplayInfo(void){
    static char text[512];snprintf(text,sizeof(text),"{\"backend\":\"native-wayland-gpu\",\"presents\":%lu,\"failures\":%lu,\"restores\":%lu,\"missing_targets\":%lu,\"touch_events\":%lu,\"error\":\"%s\"}",
        presented,failures,restores,missing_targets,input_events?input_events():0,failure);return text;
}
