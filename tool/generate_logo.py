#!/usr/bin/env python3
"""FairTurn mark on warm paper: the chosen person, with the group beside them."""

import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SIZE = 1024
CREAM = (246, 243, 236, 255)
LEAF = (63, 122, 90, 255)
SAND = (232, 210, 184, 255)
SAGE = (188, 210, 190, 255)


def place(value: float, scale: float) -> float:
    return SIZE / 2 + (value - SIZE / 2) * scale


def stroke(draw: ImageDraw.ImageDraw, points: list[tuple[float, float]], width: float, fill: tuple[int, int, int, int]) -> None:
    radius = width / 2
    for index in range(len(points) - 1):
        x0, y0 = points[index]
        x1, y1 = points[index + 1]
        dist = math.hypot(x1 - x0, y1 - y0)
        steps = max(1, int(dist / 1.5))
        for step in range(steps + 1):
            t = step / steps
            x = x0 + (x1 - x0) * t
            y = y0 + (y1 - y0) * t
            draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=fill)


def circle(draw: ImageDraw.ImageDraw, cx: float, cy: float, radius: float, fill: tuple[int, int, int, int]) -> None:
    draw.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), fill=fill)


def draw_mark(canvas: Image.Image, scale: float = 1.0) -> None:
    draw = ImageDraw.Draw(canvas)

    def at(x: float, y: float) -> tuple[float, float]:
        return place(x, scale), place(y, scale)

    def r(value: float) -> float:
        return value * scale

    # Separated people. The middle one is whose turn it is.
    circle(draw, *at(300, 560), r(132), SAND)
    circle(draw, *at(724, 560), r(132), SAGE)
    circle(draw, *at(512, 470), r(176), LEAF)

    badge = at(640, 600)
    circle(draw, badge[0], badge[1], r(58), CREAM)
    arm = r(46)
    stroke(
        draw,
        [
            (badge[0] - arm * 0.42, badge[1] + arm * 0.02),
            (badge[0] - arm * 0.05, badge[1] + arm * 0.36),
            (badge[0] + arm * 0.48, badge[1] - arm * 0.38),
        ],
        width=r(16),
        fill=LEAF,
    )


def main() -> None:
    assets = ROOT / "assets"
    assets.mkdir(exist_ok=True)
    logo = Image.new("RGBA", (SIZE, SIZE), CREAM)
    draw_mark(logo, scale=0.9)
    logo_path = assets / "logo.png"
    logo.convert("RGB").save(logo_path, optimize=True)

    splash = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    ImageDraw.Draw(splash).ellipse((172, 172, 852, 852), fill=CREAM)
    draw_mark(splash, scale=0.64)
    splash_path = ROOT / "android/app/src/main/res/drawable-nodpi/splash_icon.png"
    splash_path.parent.mkdir(parents=True, exist_ok=True)
    splash.save(splash_path, optimize=True)
    print(f"wrote {logo_path}")
    print(f"wrote {splash_path}")


if __name__ == "__main__":
    main()
