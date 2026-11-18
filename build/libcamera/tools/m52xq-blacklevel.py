#!/usr/bin/env python3
# m52xq: measure the sensor black level from RAW frames (lens covered).
# usage: m52xq-blacklevel.py [camera-substring ...]   (default: all cameras)
# Prints per camera: format, size, the mean / median of every Bayer channel in
# 10-bit units and in the 16-bit scale of the softisp tuning files (x64).
import selectors
import sys

import libcamera as lc

FRAMES = 6          # first frames are skipped (exposure settling), the last is measured


def channels_csi2p10(buf, w, h, stride, crop=512):
    """Bayer channel samples of a central crop x crop region (pure python, no numpy)."""
    x0 = (w // 2 - crop // 2) // 4 * 4
    y0 = (h // 2 - crop // 2) // 2 * 2
    ch = {(0, 0): [], (0, 1): [], (1, 0): [], (1, 1): []}
    for y in range(y0, y0 + crop):
        row = buf[y * stride : (y + 1) * stride]
        for g in range(x0 // 4, (x0 + crop) // 4):
            b = row[g * 5 : g * 5 + 5]
            lo = b[4]
            for i in range(4):
                v = (b[i] << 2) | ((lo >> (2 * i)) & 3)
                ch[(y & 1, (g * 4 + i) & 1)].append(v)
    return ch


def measure(cm, cam):
    cam.acquire()
    started = False
    try:
        cfg = cam.generate_configuration([lc.StreamRole.Raw])
        sc = cfg.at(0)
        # the smallest raw mode is enough for the black level
        sizes = sorted(sc.formats.sizes(sc.pixel_format), key=lambda s: s.width * s.height)
        if sizes:
            sc.size = sizes[0]
        cfg.validate()
        print(f"  controls: {', '.join(sorted(str(c.name) for c in cam.controls))}")
        cam.configure(cfg)
        fmt, w, h, stride = str(sc.pixel_format), sc.size.width, sc.size.height, sc.stride
        alloc = lc.FrameBufferAllocator(cam)
        alloc.allocate(sc.stream)
        bufs = alloc.buffers(sc.stream)
        reqs = []
        for b in bufs:
            r = cam.create_request()
            r.add_buffer(sc.stream, b)
            reqs.append(r)
        # short exposure, minimum gain: only the black level remains
        ctrls = {}
        for mode in ("ExposureTimeMode", "AnalogueGainMode"):
            cid = getattr(lc.controls, mode, None)
            if cid is not None and cid in cam.controls:
                ctrls[cid] = 1      # Manual
        if lc.controls.ExposureTime in cam.controls:
            ctrls[lc.controls.ExposureTime] = cam.controls[lc.controls.ExposureTime].min or 100
        if lc.controls.AnalogueGain in cam.controls:
            ctrls[lc.controls.AnalogueGain] = cam.controls[lc.controls.AnalogueGain].min or 1.0
        cam.start(ctrls)
        started = True
        for r in reqs:
            cam.queue_request(r)
        sel = selectors.DefaultSelector()
        sel.register(cm.event_fd, selectors.EVENT_READ)
        got, last = 0, None
        waited = 0
        while got < FRAMES:
            if not sel.select(5):
                waited += 1
                if waited >= 2:
                    raise RuntimeError(f"no frames after 10 s ({got} received)")
            for r in cm.get_ready_requests():
                got += 1
                fb = r.buffers[sc.stream]
                if got == FRAMES:
                    import mmap
                    p = fb.planes[0]
                    with mmap.mmap(p.fd, p.offset + p.length, mmap.MAP_SHARED, mmap.PROT_READ) as m:
                        last = bytes(m[p.offset : p.offset + p.length])
                else:
                    r.reuse()
                    cam.queue_request(r)
        cam.stop()
        started = False
    finally:
        if started:
            try:
                cam.stop()
            except Exception as e:
                print(f"  stop: {e}")
        try:
            cam.release()
        except Exception as e:
            print(f"  release: {e}")
    if "CSI2P" not in fmt or "10" not in fmt:
        print(f"  {fmt}: not a 10-bit packed format, skipped")
        return
    ch = channels_csi2p10(last, w, h, stride)
    order = fmt[1:5] if fmt.startswith("S") else fmt[:4]   # SRGGB10_CSI2P -> RGGB
    print(f"  {fmt} {w}x{h} stride {stride}")
    for (dy, dx), name in zip(((0, 0), (0, 1), (1, 0), (1, 1)), order):
        v = sorted(ch[(dy, dx)])
        n = len(v)
        mean = sum(v) / n
        med = v[n // 2]
        print(f"    {name}{dy}{dx}: mean {mean:7.2f}  median {med:5d}  min {v[0]:4d}  p99 {v[int(n * 0.99)]:5d}"
              f"  -> tuning blackLevel ~{int(round(med * 64))}")


def main():
    want = sys.argv[1:]
    cm = lc.CameraManager.singleton()
    for cam in cm.cameras:
        name = cam.id
        if want and not any(w in name for w in want):
            continue
        model = cam.properties.get(lc.properties.Model, "?")
        print(f"{model} ({name})")
        try:
            measure(cm, cam)
        except Exception as e:
            import traceback
            print(f"  error: {e!r}")
            traceback.print_exc()


if __name__ == "__main__":
    main()
