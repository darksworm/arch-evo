#!/usr/bin/env python3
"""Write the Hyprland-matching keymap changes to the Keyball44 over VIA (EEPROM).

Usage:
  sudo python3 -I keyball-apply.py [--dry-run] [/dev/hidrawN]
  sudo python3 -I keyball-apply.py --restore BACKUP.json [/dev/hidrawN]

Each change is only written if the key still holds the expected old value, and
every write is read back. --restore writes back every key that differs from a
keyball-dump.py backup.
"""
import json
import os
import select
import sys

ROWS, COLS = 8, 6
HYPER = 0x0D00  # C(A(G(kc))) — LCTL|LALT|LGUI in the QK_MODS range
KC = {"A": 0x04, "C": 0x06, "D": 0x07, "F": 0x09, "G": 0x0A, "H": 0x0B,
      "S": 0x16, "T": 0x17, "V": 0x19, "COMM": 0x36}
NO, TRNS = 0x0000, 0x0001

# (layer, matrix row, matrix col, expected old, new, note)
# right half: matrix row = visual row + 4, col mirrored (outer key = col 0)
CHANGES = [
    (3, 1, 1, 0x0835, HYPER | KC["A"], "Esc+A  Super+`    -> Hyper+A (ws 1)"),
    (3, 1, 2, 0x081E, HYPER | KC["S"], "Esc+S  Super+1    -> Hyper+S (ws 2)"),
    (3, 1, 3, 0x081F, HYPER | KC["D"], "Esc+D  Super+2    -> Hyper+D (ws 3)"),
    (3, 1, 4, 0x0820, HYPER | KC["F"], "Esc+F  Super+3    -> Hyper+F (ws 4)"),
    (3, 1, 5, 0x0821, HYPER | KC["G"], "Esc+G  Super+4    -> Hyper+G (ws 5)"),
    (3, 2, 0, NO,     TRNS,            "Esc+LShift  NO    -> TRNS (Shift for move-to-ws)"),
    (3, 2, 3, 0x0D0F, HYPER | KC["C"], "Esc+C  Hyper+L    -> Hyper+C (zen)"),
    (3, 2, 4, 0x0D16, HYPER | KC["V"], "Esc+V  Hyper+S    -> Hyper+V (clipboard)"),
    (3, 2, 5, 0x0D06, NO,              "Esc+B  Hyper+C    -> NO"),
    (3, 6, 5, 0x0D07, NO,              "Esc+N  Hyper+D    -> NO (discord gone)"),
    (3, 6, 3, 0x0D09, HYPER | KC["COMM"], "Esc+,  Hyper+F    -> Hyper+, (monitor -1)"),
    (3, 0, 5, 0x0807, HYPER | KC["T"], "Esc+T  Super+D    -> Hyper+T (teams)"),
    (3, 5, 5, 0x020B, HYPER | KC["H"], "Esc+H  Shift+H    -> Hyper+H (focus left)"),
    (1, 0, 5, 0x0817, TRNS,            "L1 T   Super+T    -> TRNS"),
    (1, 2, 3, 0x0806, TRNS,            "L1 C   Super+C    -> TRNS"),
    (1, 2, 4, 0x0819, TRNS,            "L1 V   Super+V    -> TRNS"),
]


def xfer(fd, payload):
    os.write(fd, b"\x00" + bytes(payload) + bytes(32 - len(payload)))
    if not select.select([fd], [], [], 1.0)[0]:
        raise SystemExit("timeout waiting for keyboard reply")
    return os.read(fd, 32)


def get(fd, layer, row, col):
    r = xfer(fd, [0x04, layer, row, col])
    return r[4] << 8 | r[5]


def put(fd, layer, row, col, kc):
    xfer(fd, [0x05, layer, row, col, kc >> 8, kc & 0xFF])
    got = get(fd, layer, row, col)
    if got != kc:
        raise SystemExit(f"readback mismatch at L{layer} r{row} c{col}: wrote {kc:#06x}, got {got:#06x}")


args = sys.argv[1:]
dry = "--dry-run" in args
args = [a for a in args if a != "--dry-run"]
restore = None
if args and args[0] == "--restore":
    restore, args = args[1], args[2:]
dev = args[0] if args else "/dev/hidraw3"

fd = os.open(dev, os.O_RDWR)
try:
    if restore:
        layers = json.load(open(restore))["layers"]
        n = 0
        for l, m in enumerate(layers):
            for r in range(ROWS):
                for c in range(COLS):
                    if get(fd, l, r, c) != m[r][c]:
                        print(f"restore L{l} r{r} c{c} -> {m[r][c]:#06x}")
                        if not dry:
                            put(fd, l, r, c, m[r][c])
                        n += 1
        print(f"{n} keys {'would be ' if dry else ''}restored")
    else:
        stale = [(ch, cur) for ch in CHANGES if (cur := get(fd, *ch[:3])) not in (ch[3], ch[4])]
        if stale:
            for ch, cur in stale:
                print(f"unexpected value {cur:#06x} at {ch[5]} (expected {ch[3]:#06x})")
            raise SystemExit("keymap differs from the backup — nothing written")
        for l, r, c, old, new, note in CHANGES:
            print(("DRY  " if dry else "SET  ") + note)
            if not dry:
                put(fd, l, r, c, new)
        print("done" + (" (dry run, nothing written)" if dry else ""))
finally:
    os.close(fd)
