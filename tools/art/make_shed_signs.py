"""Draw the transfer shed's signs for part E of step 5 of #253 (docs/PHASE_BRIEF.md):

- `dock_numbers.png`: the docks' numbers 1-9, 18 in (0.46 m), painted black on a safety-yellow
  plate, three by three;
- `posters.png`: the six federal posters employers must display, three by two, each drawn as its
  layout with its title and no other text (the bars stand for its small print): OSHA's "Job
  Safety and Health: It's the Law!", the Fair Labor Standards Act's minimum wage, EEO's "Know Your
  Rights", the Family and Medical Leave Act, USERRA and the Employee Polygraph Protection Act;
- `station_legend.png`: a dock control station's legend plate: DOOR (OPEN, CLOSE, STOP),
  LEVELER (RAISE, LIP) and RESTRAINT (ENGAGE, RELEASE);
- `clock_face.png`: a time clock's display and card slot;
- `time_cards.png`: a card rack's cards.

The same every run (no randomness). Usage, from the repository root:
    python3 -I tools/art/make_shed_signs.py
"""

import pathlib

from PIL import Image, ImageDraw, ImageFont

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "game/features/environments/industrial_loop/art/fitout"
YELLOW = (250, 200, 20)
BLACK = (22, 22, 22)
WHITE = (244, 244, 240)
POSTERS = [("JOB SAFETY AND HEALTH", "IT'S THE LAW!", (20, 60, 120)),
           ("EMPLOYEE RIGHTS", "FAIR LABOR STANDARDS ACT", (30, 30, 30)),
           ("KNOW YOUR RIGHTS", "WORKPLACE DISCRIMINATION IS ILLEGAL", (24, 52, 98)),
           ("EMPLOYEE RIGHTS", "FAMILY AND MEDICAL LEAVE ACT", (40, 40, 40)),
           ("YOUR RIGHTS UNDER USERRA", "UNIFORMED SERVICES EMPLOYMENT", (110, 20, 30)),
           ("EMPLOYEE POLYGRAPH", "PROTECTION ACT", (30, 30, 30))]


def font(size, bold=True):
    names = ["/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else
             "/System/Library/Fonts/Supplemental/Arial.ttf", "/System/Library/Fonts/Helvetica.ttc"]
    for name in names:
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            continue
    return ImageFont.load_default()


def centred(draw, box, text, size, fill, bold=True):
    """Draws `text` centred in `box`, shrunk until it fits the box's width with a margin."""
    face = font(size, bold)
    left, top, right, bottom = draw.textbbox((0, 0), text, font=face)
    while right - left > (box[2] - box[0]) - 16 and size > 8:
        size -= 1
        face = font(size, bold)
        left, top, right, bottom = draw.textbbox((0, 0), text, font=face)
    x = box[0] + (box[2] - box[0] - (right - left)) / 2 - left
    y = box[1] + (box[3] - box[1] - (bottom - top)) / 2 - top
    draw.text((x, y), text, font=face, fill=fill)


def numbers():
    cell = (160, 220)
    image = Image.new("RGB", (cell[0] * 3, cell[1] * 3), YELLOW)
    draw = ImageDraw.Draw(image)
    for index in range(9):
        x0, y0 = (index % 3) * cell[0], (index // 3) * cell[1]
        draw.rectangle((x0 + 6, y0 + 6, x0 + cell[0] - 7, y0 + cell[1] - 7), outline=BLACK,
                       width=5)
        centred(draw, (x0, y0, x0 + cell[0], y0 + cell[1]), str(index + 1), 170, BLACK)
    image.save(OUT / "dock_numbers.png")


def posters():
    cell = (280, 360)
    image = Image.new("RGB", (cell[0] * 3, cell[1] * 2), WHITE)
    draw = ImageDraw.Draw(image)
    for index, (title, subtitle, colour) in enumerate(POSTERS):
        x0, y0 = (index % 3) * cell[0], (index // 3) * cell[1]
        draw.rectangle((x0, y0, x0 + cell[0] - 1, y0 + cell[1] - 1), fill=WHITE,
                       outline=(150, 150, 150), width=2)
        draw.rectangle((x0 + 10, y0 + 10, x0 + cell[0] - 11, y0 + 92), fill=colour)
        centred(draw, (x0 + 10, y0 + 16, x0 + cell[0] - 11, y0 + 52), title, 22, WHITE)
        centred(draw, (x0 + 10, y0 + 54, x0 + cell[0] - 11, y0 + 86), subtitle,
                15 if len(subtitle) > 26 else 18, WHITE)
        for row in range(12):
            y = y0 + 110 + row * 15
            width = cell[0] - 40 - (60 if row % 5 == 4 else (index * 7 + row * 13) % 30)
            draw.rectangle((x0 + 20, y, x0 + 20 + width, y + 6), fill=(160, 160, 160))
        draw.ellipse((x0 + 20, y0 + cell[1] - 70, x0 + 70, y0 + cell[1] - 20), outline=colour,
                     width=4)
        draw.rectangle((x0 + 90, y0 + cell[1] - 50, x0 + cell[0] - 20, y0 + cell[1] - 38),
                       fill=colour)
    image.save(OUT / "posters.png")


def legend():
    image = Image.new("RGB", (250, 400), (205, 207, 204))
    draw = ImageDraw.Draw(image)
    rows = [("DOOR", ["OPEN", "CLOSE", "STOP"]), ("LEVELER", ["RAISE", "LIP"]),
            ("RESTRAINT", ["ENGAGE", "RELEASE"])]
    y = 14
    for heading, labels in rows:
        draw.rectangle((10, y, 240, y + 30), fill=BLACK)
        centred(draw, (10, y, 240, y + 30), heading, 20, WHITE)
        y += 38
        for index, label in enumerate(labels):
            x = 10 + index * (230 // len(labels))
            centred(draw, (x, y + 52, x + 230 // len(labels), y + 72), label, 14, BLACK)
        y += 82
    image.save(OUT / "station_legend.png")


def clock_face():
    image = Image.new("RGB", (190, 240), (48, 50, 52))
    draw = ImageDraw.Draw(image)
    draw.rectangle((20, 24, 170, 84), fill=(18, 30, 22))
    centred(draw, (20, 24, 170, 84), "02:47", 40, (120, 230, 150))
    centred(draw, (20, 88, 170, 108), "IN  OUT", 16, WHITE)
    draw.rectangle((40, 140, 150, 152), fill=BLACK)
    centred(draw, (20, 170, 170, 200), "INSERT CARD", 14, (200, 200, 200))
    image.save(OUT / "clock_face.png")


def time_cards():
    image = Image.new("RGB", (150, 600), (180, 182, 180))
    draw = ImageDraw.Draw(image)
    for slot in range(12):
        y = 8 + slot * 49
        if slot % 4 != 3:
            draw.rectangle((14, y, 136, y + 30), fill=(236, 230, 205))
            draw.rectangle((20, y + 6, 100, y + 11), fill=(90, 90, 90))
            draw.rectangle((20, y + 16, 70, y + 20), fill=(150, 60, 50))
        draw.rectangle((6, y + 32, 144, y + 44), fill=(120, 122, 120))
    image.save(OUT / "time_cards.png")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    numbers()
    posters()
    legend()
    clock_face()
    time_cards()
    for name in sorted(OUT.glob("*.png")):
        print(f"Wrote {name.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
