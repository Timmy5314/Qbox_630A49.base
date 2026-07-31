"""
Genereert de ontbrekende clothing_*.png iconen voor ox_inventory.

Pure Python: geen PIL nodig, alleen zlib + struct. Tekent eenvoudige
silhouetten op een transparante achtergrond, in een lichte tint die leesbaar is
op de donkere ox_inventory slots.

Bewust simpel en consistent gehouden: het doel is dat elk kledingstuk
herkenbaar is in de inventory, niet dat het kunst is.
"""

import zlib
import struct
import os
import sys

SIZE = 128
FILL = (222, 226, 232, 255)      # licht grijsblauw, leest goed op donker
ACCENT = (150, 158, 170, 255)    # donkerder voor detail
GOLD = (214, 178, 92, 255)       # sieraden


class Canvas:
    def __init__(self, size=SIZE):
        self.size = size
        self.px = [[(0, 0, 0, 0)] * size for _ in range(size)]

    def put(self, x, y, color):
        if 0 <= x < self.size and 0 <= y < self.size:
            self.px[y][x] = color

    def rect(self, x0, y0, x1, y1, color):
        for y in range(int(y0), int(y1) + 1):
            for x in range(int(x0), int(x1) + 1):
                self.put(x, y, color)

    def rrect(self, x0, y0, x1, y1, r, color):
        for y in range(int(y0), int(y1) + 1):
            for x in range(int(x0), int(x1) + 1):
                dx = min(x - x0, x1 - x, r)
                dy = min(y - y0, y1 - y, r)
                if dx < r and dy < r:
                    if (r - dx) ** 2 + (r - dy) ** 2 > r * r:
                        continue
                self.put(x, y, color)

    def circle(self, cx, cy, r, color):
        for y in range(int(cy - r), int(cy + r) + 1):
            for x in range(int(cx - r), int(cx + r) + 1):
                if (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
                    self.put(x, y, color)

    def ring(self, cx, cy, r, w, color):
        inner = (r - w) ** 2
        outer = r * r
        for y in range(int(cy - r), int(cy + r) + 1):
            for x in range(int(cx - r), int(cx + r) + 1):
                d = (x - cx) ** 2 + (y - cy) ** 2
                if inner <= d <= outer:
                    self.put(x, y, color)

    def poly(self, points, color):
        ys = [p[1] for p in points]
        for y in range(int(min(ys)), int(max(ys)) + 1):
            xs = []
            n = len(points)
            for i in range(n):
                x0, y0 = points[i]
                x1, y1 = points[(i + 1) % n]
                if y0 == y1:
                    continue
                if min(y0, y1) <= y < max(y0, y1):
                    t = (y - y0) / (y1 - y0)
                    xs.append(x0 + t * (x1 - x0))
            xs.sort()
            for i in range(0, len(xs) - 1, 2):
                for x in range(int(xs[i]), int(xs[i + 1]) + 1):
                    self.put(x, y, color)

    def save(self, path):
        raw = bytearray()
        for row in self.px:
            raw.append(0)  # filter type 0
            for r, g, b, a in row:
                raw += bytes((r, g, b, a))

        def chunk(tag, data):
            c = struct.pack(">I", len(data)) + tag + data
            return c + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

        png = b"\x89PNG\r\n\x1a\n"
        png += chunk(b"IHDR", struct.pack(">IIBBBBB", self.size, self.size, 8, 6, 0, 0, 0))
        png += chunk(b"IDAT", zlib.compress(bytes(raw), 9))
        png += chunk(b"IEND", b"")

        with open(path, "wb") as f:
            f.write(png)


def shirt(c):
    c.poly([(30, 34), (48, 26), (80, 26), (98, 34), (104, 56), (88, 62), (88, 104), (40, 104), (40, 62), (24, 56)], FILL)
    c.poly([(56, 26), (64, 40), (72, 26)], ACCENT)


def jacket(c):
    c.poly([(30, 34), (48, 26), (80, 26), (98, 34), (104, 58), (90, 64), (90, 106), (38, 106), (38, 64), (24, 58)], FILL)
    c.rect(62, 30, 66, 104, ACCENT)
    c.poly([(48, 26), (64, 44), (80, 26)], ACCENT)


def pants(c):
    # Omtrek met de kruisnaad als inkeping tussen de twee pijpen.
    c.poly([
        (38, 26), (90, 26),          # tailleband, boven
        (90, 108), (70, 108),        # rechterpijp omlaag en de zoom
        (64, 60),                    # kruis
        (58, 108), (38, 108),        # linkerpijp zoom
    ], FILL)
    c.rect(38, 26, 90, 36, ACCENT)   # tailleband


def shoes(c):
    c.poly([(24, 78), (44, 54), (58, 54), (66, 72), (100, 84), (104, 96), (24, 96)], FILL)
    c.rect(24, 90, 104, 96, ACCENT)


def hat(c):
    c.poly([(38, 66), (42, 38), (86, 38), (90, 66)], FILL)
    c.rrect(22, 66, 112, 78, 5, FILL)
    c.rect(42, 56, 86, 62, ACCENT)


def mask(c):
    # Bandjes eerst, zodat het masker eroverheen valt.
    c.rect(18, 56, 36, 62, ACCENT)
    c.rect(92, 56, 110, 62, ACCENT)
    c.rrect(34, 42, 94, 90, 20, FILL)
    # Korte plooilijnen, niet over de volle breedte: anders leest het als strepen.
    c.rect(46, 60, 82, 64, ACCENT)
    c.rect(46, 72, 82, 76, ACCENT)


def glasses(c):
    c.ring(44, 64, 18, 5, FILL)
    c.ring(84, 64, 18, 5, FILL)
    c.rect(60, 62, 68, 66, FILL)


def bag(c):
    c.rrect(32, 52, 96, 106, 8, FILL)
    c.ring(64, 52, 20, 5, ACCENT)
    c.rect(32, 68, 96, 74, ACCENT)


def vest(c):
    c.poly([(40, 30), (58, 30), (64, 44), (70, 30), (88, 30), (94, 56), (94, 104), (34, 104), (34, 56)], FILL)
    c.rect(62, 44, 66, 104, ACCENT)


def watch(c):
    c.rect(54, 22, 74, 48, FILL)
    c.rect(54, 80, 74, 106, FILL)
    c.circle(64, 64, 26, FILL)
    c.circle(64, 64, 19, ACCENT)
    c.rect(63, 50, 65, 64, FILL)
    c.rect(64, 63, 76, 65, FILL)


def chain(c):
    for i in range(11):
        t = i / 10
        x = 32 + t * 64
        y = 44 + 34 * (1 - (2 * t - 1) ** 2)
        c.ring(x, y, 7, 3, GOLD)


def bracelet(c):
    c.ring(64, 64, 30, 8, GOLD)


def ears(c):
    c.circle(46, 50, 9, GOLD)
    c.ring(46, 68, 12, 4, GOLD)
    c.circle(84, 50, 9, GOLD)
    c.ring(84, 68, 12, 4, GOLD)


def decals(c):
    c.poly([(34, 34), (50, 28), (78, 28), (94, 34), (94, 104), (34, 104)], FILL)
    c.circle(64, 62, 18, ACCENT)
    c.circle(64, 62, 9, FILL)


ICONS = {
    "clothing_shirt": shirt,
    "clothing_jacket": jacket,
    "clothing_pants": pants,
    "clothing_shoes": shoes,
    "clothing_hat": hat,
    "clothing_mask": mask,
    "clothing_glasses": glasses,
    "clothing_bag": bag,
    "clothing_vest": vest,
    "clothing_watch": watch,
    "clothing_chain": chain,
    "clothing_bracelet": bracelet,
    "clothing_ears": ears,
    "clothing_decals": decals,
}


def main():
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    for name, draw in ICONS.items():
        c = Canvas()
        draw(c)
        path = os.path.join(out, name + ".png")
        c.save(path)
        print("%-22s %6d bytes" % (name + ".png", os.path.getsize(path)))


if __name__ == "__main__":
    main()
