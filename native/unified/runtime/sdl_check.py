"""Check the firmware SDL library in its own process."""
import ctypes as C
import json
import os
import sys


def main(args):
    operation, filename, *values = args
    lib = C.CDLL(filename, mode=os.RTLD_NOW | os.RTLD_LOCAL)

    def entry(name, result, *parameters):
        fn = getattr(lib, 'SDL_' + name)
        fn.restype, fn.argtypes = result, parameters
        return fn

    num, ptr, string = C.c_int, C.c_void_p, C.c_char_p
    if operation == 'drivers':
        count = entry('GetNumVideoDrivers', num)()
        name = entry('GetVideoDriver', string, num)
        print('DRIVERS ' + json.dumps([name(i).decode() for i in range(count)]))
        return

    driver, width, height = values
    err = entry('GetError', string)
    window = ctx = None
    init = entry('VideoInit', num, string)
    if init(driver.encode()) < 0:
        raise RuntimeError(err().decode(errors='replace'))
    try:
        attribute = entry('GL_SetAttribute', num, num, num)
        for key, value in ((21, 4), (17, 2), (18, 0)):
            if attribute(key, value) < 0:
                raise RuntimeError(err().decode(errors='replace'))
        window = entry('CreateWindow', ptr, string, num, num, num, num, C.c_uint32)(
            b'AM2ARM display check', 0, 0, int(width), int(height), 0x1007)
        if not window:
            raise RuntimeError(err().decode(errors='replace'))
        ctx = entry('GL_CreateContext', ptr, ptr)(window)
        if not ctx:
            raise RuntimeError(err().decode(errors='replace'))
        get_proc = entry('GL_GetProcAddress', ptr, string)
        gl_string = get_proc(b'glGetString')
        clear = get_proc(b'glClear')
        if not gl_string or not clear:
            raise RuntimeError('Missing GLES entry points.')
        renderer = C.CFUNCTYPE(string, C.c_uint)(gl_string)(0x1f01)
        if not renderer:
            raise RuntimeError('The EGL context did not expose a renderer.')
        C.CFUNCTYPE(None, C.c_uint)(clear)(0x4000)
        entry('GL_SwapWindow', None, ptr)(window)
        print('GLES frame submitted by ' + renderer.decode(errors='replace'), flush=True)
    finally:
        if ctx:
            entry('GL_DeleteContext', None, ptr)(ctx)
        if window:
            entry('DestroyWindow', None, ptr)(window)
        entry('VideoQuit', None)()


if __name__ == '__main__':
    try:
        main(sys.argv[1:])
    except (OSError, RuntimeError, AttributeError, ValueError) as exc:
        print(str(exc), file=sys.stderr, flush=True)
        raise SystemExit(1)
