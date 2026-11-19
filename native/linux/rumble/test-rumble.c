#include <assert.h>
#include <errno.h>
#include <fcntl.h>
#include <glob.h>
#include <linux/input.h>
#include <math.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

double AM2ARM_Rumble(const char *, double, double);
double AM2ARM_RumbleStop(void);

static unsigned long long now_ms = 10000;
static int opens, closes, uploads, starts, stops, removes, scans;
static int motor_fd, no_force_feedback, deny_upload, fail_play, duplicate;
static struct ff_effect received;
static char *paths[] = {"/dev/input/event4", "/dev/input/event17", NULL};
static const char *pad_guid = "19000000010000000100000000010000";

int __wrap_glob(const char *pattern, int flags, int (*err)(const char *, int), glob_t *result) {
    (void)flags; (void)err;
    assert(!strcmp(pattern, "/dev/input/event*"));
    scans++;
    memset(result, 0, sizeof(*result));
    result->gl_pathc = 2;
    result->gl_pathv = paths;
    return 0;
}
void __wrap_globfree(glob_t *g) { (void)g; }
int __wrap_open(const char *path, int flags, ...) {
    assert((flags & O_ACCMODE) == O_RDWR);
    opens++;
    return strstr(path, "event17") ? 117 : 104;
}
int __wrap_close(int fd) { assert(fd == 117 || fd == 104); closes++; return 0; }
int __wrap_clock_gettime(clockid_t clock, struct timespec *t) {
    assert(clock == CLOCK_MONOTONIC);
    t->tv_sec = now_ms / 1000;
    t->tv_nsec = (now_ms % 1000) * 1000000;
    return 0;
}
int __wrap_ioctl(int fd, unsigned long request, ...) {
    va_list ap;
    va_start(ap, request);
    if (request == EVIOCRMFF) {
        assert(va_arg(ap, int) == 7);
        removes++;
        va_end(ap);
        return 0;
    }
    void *arg = va_arg(ap, void *);
    va_end(ap);
    if (request == EVIOCGID) {
        struct input_id *id = arg;
        *id = (struct input_id){BUS_HOST, 1, (fd == 117 || duplicate) ? 1 : 9, 0x100};
    } else if (_IOC_TYPE(request) == 'E' && _IOC_NR(request) == 0x20 + EV_FF) {
        unsigned long *bits = arg;
        memset(bits, 0, _IOC_SIZE(request));
        if (!no_force_feedback)
            bits[FF_RUMBLE / (8 * sizeof(*bits))] |= 1UL << (FF_RUMBLE % (8 * sizeof(*bits)));
    } else if (request == EVIOCGEFFECTS) {
        *(int *)arg = 16;
    } else if (request == EVIOCSFF) {
        assert(fd == 117);
        uploads++;
        if (deny_upload) { errno = EACCES; return -1; }
        struct ff_effect *effect = arg;
        assert(effect->id == -1 || effect->id == 7);
        assert(effect->type == FF_RUMBLE);
        assert(effect->replay.length > 0 && effect->replay.length <= 1000);
        effect->id = 7;
        received = *effect;
        motor_fd = fd;
    } else {
        fprintf(stderr, "unexpected ioctl %lx\n", request);
        assert(0);
    }
    return 0;
}
ssize_t __wrap_write(int fd, const void *buffer, size_t count) {
    assert(fd == motor_fd && count == sizeof(struct input_event));
    const struct input_event *event = buffer;
    assert(event->type == EV_FF && event->code == 7);
    if (event->value) {
        assert(event->value == 1);
        if (fail_play) { errno = ENODEV; return -1; }
        starts++;
    } else stops++;
    return (ssize_t)count;
}
static void reset(void) {
    AM2ARM_RumbleStop();
    now_ms += 20000;
    opens = closes = uploads = starts = stops = removes = scans = 0;
    no_force_feedback = deny_upload = fail_play = duplicate = 0;
}

int main(void) {
    reset();
    assert(AM2ARM_Rumble(pad_guid, .25, .5) == 1);
    assert(motor_fd == 117 && starts == 1 && uploads == 1);
    assert(received.u.rumble.strong_magnitude == 16384);
    assert(received.u.rumble.weak_magnitude == 32768);
    for (int frame = 0; frame < 600; frame++) {
        now_ms += 17;
        assert(AM2ARM_Rumble(pad_guid, .25, .5) == 1);
    }
    assert(uploads == 1 && starts > 10 && starts < 80 && scans == 1);
    AM2ARM_RumbleStop();
    assert(stops == 1 && removes == 1 && opens == closes);
    int previous_stops = stops;
    for (int i = 0; i < 60; i++) AM2ARM_RumbleStop();
    assert(stops == previous_stops && scans == 1);

    reset();
    assert(AM2ARM_Rumble(pad_guid, .15, .15) == 1);
    now_ms += 17;
    assert(AM2ARM_Rumble(pad_guid, .60, .60) == 1);
    assert(uploads == 2 && received.u.rumble.strong_magnitude == 39321);
    assert(AM2ARM_Rumble(pad_guid, 0, 0) == 0);
    assert(stops == 1 && removes == 1 && opens == closes);

    reset();
    assert(AM2ARM_Rumble(pad_guid, -10, 10) == 1);
    assert(received.u.rumble.strong_magnitude == 0 && received.u.rumble.weak_magnitude == 65535);
    assert(AM2ARM_Rumble(pad_guid, NAN, INFINITY) == 0);
    assert(stops == 1 && removes == 1);

    reset();
    no_force_feedback = 1;
    for (int i = 0; i < 60; i++) {
        assert(AM2ARM_Rumble(pad_guid, .5, .5) == 0);
        now_ms += 17;
    }
    assert(scans == 1 && uploads == 0 && starts == 0 && opens == closes);
    no_force_feedback = 0;
    now_ms += 10000;
    assert(AM2ARM_Rumble(pad_guid, .5, .5) == 1);

    reset();
    assert(AM2ARM_Rumble("bad-guid", 1, 1) == 0);
    assert(scans == 0 && opens == 0);
    duplicate = 1;
    assert(AM2ARM_Rumble(pad_guid, 1, 1) == 0);
    assert(starts == 0 && opens == closes);

    reset();
    deny_upload = 1;
    assert(AM2ARM_Rumble(pad_guid, .5, .5) == 0);
    assert(starts == 0 && opens == closes);

    reset();
    assert(AM2ARM_Rumble(pad_guid, .5, .5) == 1);
    fail_play = 1;
    now_ms += 400;
    assert(AM2ARM_Rumble(pad_guid, .5, .5) == 0);
    assert(opens == closes);

    reset();
    assert(AM2ARM_Rumble(pad_guid, .5, .5) == 1);
    assert(AM2ARM_Rumble("030000004c050000e60c000011810000", .5, .5) == 0);
    assert(stops == 1 && removes == 1 && opens == closes);
    AM2ARM_RumbleStop();
    puts("Rumble routing, updates, stop, bounded effects and failure checks passed.");
    return 0;
}
