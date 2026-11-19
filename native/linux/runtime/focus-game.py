"""Map and focus only the game's X11 input windows at startup."""
import ctypes as c
import sys
import time

name=sys.argv[1].encode()
x=c.CDLL('libX11.so.6')
x.XOpenDisplay.argtypes=[c.c_char_p];x.XOpenDisplay.restype=c.c_void_p
x.XDefaultRootWindow.argtypes=[c.c_void_p];x.XDefaultRootWindow.restype=c.c_ulong
x.XQueryTree.argtypes=[c.c_void_p,c.c_ulong,c.POINTER(c.c_ulong),c.POINTER(c.c_ulong),c.POINTER(c.POINTER(c.c_ulong)),c.POINTER(c.c_uint)]
x.XFetchName.argtypes=[c.c_void_p,c.c_ulong,c.POINTER(c.c_char_p)]
x.XMapWindow.argtypes=[c.c_void_p,c.c_ulong]
x.XSetInputFocus.argtypes=[c.c_void_p,c.c_ulong,c.c_int,c.c_ulong]
x.XSync.argtypes=[c.c_void_p,c.c_int]
x.XFree.argtypes=[c.c_void_p];x.XCloseDisplay.argtypes=[c.c_void_p]
d=x.XOpenDisplay(None)
if not d:raise SystemExit('Private X11 input display unavailable')
root=x.XDefaultRootWindow(d);found=[]
for attempt in range(120):
    rr=c.c_ulong();parent=c.c_ulong();children=c.POINTER(c.c_ulong)();count=c.c_uint()
    if x.XQueryTree(d,root,c.byref(rr),c.byref(parent),c.byref(children),c.byref(count)):
        for i in range(count.value):
            title=c.c_char_p()
            if x.XFetchName(d,children[i],c.byref(title)) and title.value:
                if name in title.value:found.append(children[i])
                x.XFree(title)
        if children:x.XFree(children)
    if found:break
    time.sleep(.25)
if not found:raise SystemExit('Named game input window did not appear')
for window in found:x.XMapWindow(d,window)
x.XSync(d,0);time.sleep(.2)
for window in found:x.XSetInputFocus(d,window,1,0)
x.XSync(d,0);x.XCloseDisplay(d)
print('Private game input windows focused:',len(found),flush=True)
