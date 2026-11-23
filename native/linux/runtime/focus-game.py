"""Focus the game window or request a normal window-manager close."""
import ctypes as c
import sys
import time

name=sys.argv[1].encode()
closing = sys.argv[2:] == ['--close']
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
for attempt in range(1 if closing else 120):
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
if closing:
    class ClientMessage(c.Structure):
        _fields_ = [('type', c.c_int), ('serial', c.c_ulong), ('sent', c.c_int), ('display', c.c_void_p),
                    ('window', c.c_ulong), ('message_type', c.c_ulong), ('format', c.c_int), ('data', c.c_long * 5)]
    class Event(c.Union):
        _fields_ = [('message', ClientMessage), ('pad', c.c_long * 24)]
    x.XInternAtom.argtypes = [c.c_void_p, c.c_char_p, c.c_int]
    x.XInternAtom.restype = c.c_ulong
    x.XGetWMProtocols.argtypes = [c.c_void_p, c.c_ulong, c.POINTER(c.POINTER(c.c_ulong)), c.POINTER(c.c_int)]
    x.XSendEvent.argtypes = [c.c_void_p, c.c_ulong, c.c_int, c.c_long, c.POINTER(Event)]
    protocols = x.XInternAtom(d, b'WM_PROTOCOLS', 1)
    delete = x.XInternAtom(d, b'WM_DELETE_WINDOW', 1)
    sent = False
    for window in found:
        atoms = c.POINTER(c.c_ulong)()
        count = c.c_int()
        if protocols and delete and x.XGetWMProtocols(d, window, c.byref(atoms), c.byref(count)):
            accepts_close = delete in atoms[:count.value]
            x.XFree(atoms)
            if accepts_close:
                event = Event()
                event.message = ClientMessage(33, 0, 1, d, window, protocols, 32, (c.c_long * 5)(delete, 0))
                sent = bool(x.XSendEvent(d, window, 0, 0, c.byref(event)))
                if sent: break
    x.XSync(d, 0)
    x.XCloseDisplay(d)
    print('Game window close requested:', sent, flush=True)
    raise SystemExit(0 if sent else 1)
for window in found:x.XMapWindow(d,window)
x.XSync(d,0);time.sleep(.2)
for window in found:x.XSetInputFocus(d,window,1,0)
x.XSync(d,0);x.XCloseDisplay(d)
print('Private game input windows focused:',len(found),flush=True)
