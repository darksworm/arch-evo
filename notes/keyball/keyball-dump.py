#!/usr/bin/env python3
"""Read the Keyball44 keymap over the VIA raw-HID protocol and print it.

Usage: sudo python3 -I keyball_dump.py [/dev/hidrawN] [out.json]
"""
import json
import os
import select
import sys

DEV = sys.argv[1] if len(sys.argv) > 1 else "/dev/hidraw3"
OUT = sys.argv[2] if len(sys.argv) > 2 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "keyball_keymap.json")
ROWS, COLS = 8, 6


def xfer(fd, payload):
    buf = bytes(payload) + bytes(32 - len(payload))
    os.write(fd, b"\x00" + buf)  # report id 0
    r, _, _ = select.select([fd], [], [], 1.0)
    if not r:
        raise SystemExit("timeout waiting for keyboard reply")
    return os.read(fd, 32)


BASIC = {0x00: "NO", 0x01: "TRNS", 0x28: "ENT", 0x29: "ESC", 0x2A: "BSPC", 0x2B: "TAB", 0x2C: "SPC",
         0x2D: "MINS", 0x2E: "EQL", 0x2F: "LBRC", 0x30: "RBRC", 0x31: "BSLS", 0x32: "NUHS", 0x33: "SCLN",
         0x34: "QUOT", 0x35: "GRV", 0x36: "COMM", 0x37: "DOT", 0x38: "SLSH", 0x39: "CAPS",
         0x46: "PSCR", 0x47: "SCRL", 0x48: "PAUS", 0x49: "INS", 0x4A: "HOME", 0x4B: "PGUP", 0x4C: "DEL",
         0x4D: "END", 0x4E: "PGDN", 0x4F: "RGHT", 0x50: "LEFT", 0x51: "DOWN", 0x52: "UP",
         0x64: "NUBS", 0x65: "APP", 0x87: "INT1", 0x88: "INT2", 0x89: "INT3", 0x90: "LNG1", 0x91: "LNG2",
         0xA5: "PWR", 0xA8: "MUTE", 0xA9: "VOLU", 0xAA: "VOLD", 0xAB: "MNXT", 0xAC: "MPRV", 0xAE: "MPLY",
         0xBD: "BRIU", 0xBE: "BRID",
         0xE0: "LCTL", 0xE1: "LSFT", 0xE2: "LALT", 0xE3: "LGUI", 0xE4: "RCTL", 0xE5: "RSFT", 0xE6: "RALT", 0xE7: "RGUI"}
for i in range(26):
    BASIC[0x04 + i] = chr(ord("A") + i)
for i in range(9):
    BASIC[0x1E + i] = str(i + 1)
BASIC[0x27] = "0"
for i in range(12):
    BASIC[0x3A + i] = f"F{i + 1}"
for i in range(12):
    BASIC[0x68 + i] = f"F{i + 13}"


def mods(m):
    side = "R" if m & 0x10 else "L"
    names = [n for bit, n in ((1, "CTL"), (2, "SFT"), (4, "ALT"), (8, "GUI")) if m & bit]
    return "+".join(side + n for n in names) or "?"


def basic(k):
    return BASIC.get(k, f"0x{k:02X}")


def decode(kc, proto):
    if kc <= 0xFF:
        return basic(kc)
    if kc <= 0x1FFF:
        return f"{mods(kc >> 8 & 0x1F)}({basic(kc & 0xFF)})"
    if proto >= 12:  # QMK >= 0.19 keycode layout
        if 0x2000 <= kc <= 0x3FFF:
            return f"MT({mods(kc >> 8 & 0x1F)},{basic(kc & 0xFF)})"
        if 0x4000 <= kc <= 0x4FFF:
            return f"LT({kc >> 8 & 0xF},{basic(kc & 0xFF)})"
        if 0x5000 <= kc <= 0x51FF:
            return f"LM({kc >> 5 & 0xF},{mods(kc & 0x1F)})"
        for base, name in ((0x5200, "TO"), (0x5220, "MO"), (0x5240, "DF"), (0x5260, "TG"),
                           (0x5280, "OSL"), (0x52C0, "TT"), (0x52E0, "PDF")):
            if base <= kc < base + 0x20:
                return f"{name}({kc - base})"
        if 0x52A0 <= kc < 0x52C0:
            return f"OSM({mods(kc & 0x1F)})"
        if 0x7E00 <= kc < 0x7E40:
            return f"KB_{kc - 0x7E00}"
        if 0x7E40 <= kc < 0x7F00:
            return f"USER_{kc - 0x7E40}"
    else:  # legacy keycode layout
        if 0x4000 <= kc <= 0x4FFF:
            return f"LT({kc >> 8 & 0xF},{basic(kc & 0xFF)})"
        if 0x6000 <= kc <= 0x7FFF:
            return f"MT({mods(kc >> 8 & 0x1F)},{basic(kc & 0xFF)})"
        for base, name in ((0x5100, "MO"), (0x5200, "DF"), (0x5300, "TG"), (0x5400, "OSL")):
            if base <= kc < base + 0x20:
                return f"{name}({kc - base})"
        if 0x5000 <= kc < 0x5100:
            return f"TO({kc & 0x1F})"
        if 0x5500 <= kc < 0x5520:
            return f"OSM({mods(kc & 0x1F)})"
        if 0x5800 <= kc < 0x5820:
            return f"TT({kc - 0x5800})"
        if 0x5F80 <= kc < 0x6000:
            return f"USER_{kc - 0x5F80}"
    return f"0x{kc:04X}"


fd = os.open(DEV, os.O_RDWR)
try:
    r = xfer(fd, [0x01])
    proto = r[1] << 8 | r[2]
    layers = xfer(fd, [0x11])[1]
    total = layers * ROWS * COLS * 2
    raw = bytearray()
    while len(raw) < total:
        n = min(28, total - len(raw))
        off = len(raw)
        r = xfer(fd, [0x12, off >> 8, off & 0xFF, n])
        raw += r[4:4 + n]
finally:
    os.close(fd)

codes = [raw[i] << 8 | raw[i + 1] for i in range(0, len(raw), 2)]
km = [[codes[(l * ROWS + r) * COLS:(l * ROWS + r + 1) * COLS] for r in range(ROWS)] for l in range(layers)]

print(f"VIA protocol {proto}, {layers} layers  (device {DEV})")
for l, m in enumerate(km):
    print(f"\n── layer {l} ──")
    for r in range(4):
        left = [decode(k, proto) for k in m[r]]
        right = [decode(k, proto) for k in reversed(m[r + 4])]  # right half is mirrored
        if r == 3:
            left[0] = right[-1] = ""  # KC_NO padding slot
        print(" ".join(f"{x:>14}" for x in left), "  |  ", " ".join(f"{x:<14}" for x in right))

with open(OUT, "w") as f:
    json.dump({"protocol": proto, "layers": km}, f)
print(f"\nraw keycodes written to {OUT}")
