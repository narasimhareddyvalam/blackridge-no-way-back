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
- `time_cards.png`: a card rack's cards;
- part F's safety signs: `exit.png`, `exit_left.png` and `exit_right.png` (red EXIT on white, its
  letters filling 6 in of a 0.33 x 0.2 m face, OSHA 1910.37(b)), `extinguisher_sign.png`,
  `eyewash_sign.png`, `first_aid_sign.png`, `no_smoking.png` (at the battery charger),
  `speed_limit.png` (5 MPH), `forklift_sign.png` (CAUTION, FORKLIFT TRAFFIC) and, for the container
  yard's gate (Mission 2's step 4), `no_entry.png` (NO UNAUTHORIZED ENTRY), in the ANSI Z535
  colours: red for fire, green for first aid and eyewash, yellow for caution;
- `shipping_label.png` (the audit's fourth fix, #329): a 4 x 6 in pallet shipping label, as GS1's
  logistic label lays one out: ship from and ship to, the carrier and its PRO number, the SSCC's
  human-readable line and its barcode, its bars set from the SSCC's digits (a stand-in, not a
  scannable GS1-128); every name and number on it is invented;
- `seal_log_page.png` (#337): bay 9's seal log on the dock worker's clipboard, 0.20 x 0.26 m:
  its heading, the columns VAN, SEAL NO., BY and a tick column, five earlier rows filled in by
  hand and ticked, and the current row left empty for the game to fill (invented, as above).

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


def exit_signs():
    red = (200, 16, 20)
    for name, arrow in [("exit", ""), ("exit_left", "<"), ("exit_right", ">")]:
        image = Image.new("RGB", (330, 200), WHITE)
        draw = ImageDraw.Draw(image)
        draw.rectangle((4, 4, 325, 195), outline=(60, 60, 60), width=4)
        left = 90 if arrow == "<" else 20
        right = 240 if arrow == ">" else 310
        centred(draw, (left, 18, right, 182), "EXIT", 150, red)
        if arrow:
            tip = 26 if arrow == "<" else 304
            back = 70 if arrow == "<" else 260
            draw.polygon([(tip, 100), (back, 60), (back, 140)], fill=red)
        image.save(OUT / f"{name}.png")


def safety_signs():
    signs = [("extinguisher_sign", (190, 20, 24), WHITE, ["FIRE", "EXTINGUISHER"]),
             ("eyewash_sign", (20, 130, 60), WHITE, ["EMERGENCY", "EYE WASH"]),
             ("first_aid_sign", (20, 130, 60), WHITE, ["+", "FIRST AID"]),
             ("no_smoking", WHITE, (190, 20, 24), ["NO SMOKING", "BATTERY", "CHARGING AREA"]),
             ("speed_limit", WHITE, BLACK, ["SPEED", "LIMIT", "5", "MPH"]),
             ("forklift_sign", YELLOW, BLACK, ["CAUTION", "FORKLIFT", "TRAFFIC"]),
             ("no_entry", WHITE, (190, 20, 24), ["NO", "UNAUTHORIZED", "ENTRY"])]
    for name, ground, ink, lines in signs:
        image = Image.new("RGB", (240, 300), ground)
        draw = ImageDraw.Draw(image)
        draw.rectangle((5, 5, 234, 294), outline=ink, width=6)
        top = 116 if name == "no_smoking" else 20
        step = (280 - top) // len(lines)
        for index, line in enumerate(lines):
            size = 120 if line in ("+", "5") else 40
            centred(draw, (12, top + index * step, 228, top + (index + 1) * step), line, size, ink)
        if name == "no_smoking":
            draw.ellipse((70, 8, 170, 108), outline=ink, width=10)
            draw.line((86, 24, 154, 92), fill=ink, width=10)
        image.save(OUT / f"{name}.png")


def shipping_label():
    width, height = 400, 600
    image = Image.new("RGB", (width, height), (250, 250, 247))
    draw = ImageDraw.Draw(image)
    black = (20, 20, 20)
    draw.rectangle((6, 6, width - 7, height - 7), outline=black, width=4)
    for y in (150, 270, 360):
        draw.line((6, y, width - 7, y), fill=black, width=3)
    draw.line((200, 6, 200, 150), fill=black, width=3)
    small = font(15, False)
    bold = font(17)
    draw.text((16, 14), "SHIP FROM:", font=small, fill=black)
    for index, line in enumerate(["TRANSFER SHED", "DOCK 9", "VALLEY RD"]):
        draw.text((16, 40 + index * 24), line, font=bold, fill=black)
    draw.text((210, 14), "SHIP TO:", font=small, fill=black)
    for index, line in enumerate(["DC 4417", "RIVER RD", "RECEIVING"]):
        draw.text((210, 40 + index * 24), line, font=bold, fill=black)
    draw.text((16, 162), "CARRIER: VALLEY FREIGHT", font=bold, fill=black)
    draw.text((16, 194), "PRO: 0731 4820 66", font=bold, fill=black)
    draw.text((16, 226), "PO: 88214   CTNS: 18", font=bold, fill=black)
    draw.text((16, 290), "SSCC", font=small, fill=black)
    centred(draw, (6, 306, width - 7, 352), "(00) 0 0614141 000418529 7", 22, black)
    digits = "000614141000418529"
    x = 40
    pattern = []
    for digit in digits:
        value = int(digit)
        pattern += [2 + value % 3, 1 + (value * 7) % 3, 1 + (value * 3) % 4, 1 + value % 2]
    unit = (width - 80) / sum(pattern)
    for index, run in enumerate(pattern):
        if index % 2 == 0:
            draw.rectangle((round(x), 380, round(x + run * unit) - 1, 540), fill=black)
        x += run * unit
    centred(draw, (6, 548, width - 7, 588), "0 0614141 000418529 7", 18, black, False)
    image.save(OUT / "shipping_label.png")


def seal_log_page():
    width, height = 400, 520
    image = Image.new("RGB", (width, height), (246, 244, 236))
    draw = ImageDraw.Draw(image)
    black = (25, 25, 30)
    ink = (28, 40, 110)
    centred(draw, (0, 8, width, 44), "BAY 9  SEAL LOG", 24, black)
    centred(draw, (0, 42, width, 66), "Seal checked: view, verify, tug, twist", 13, black, False)
    columns = [10, 110, 250, 320, 390]
    for index, title in enumerate(["VAN", "SEAL NO.", "BY", "OK"]):
        centred(draw, (columns[index], 72, columns[index + 1], 98), title, 14, black)
    for y in range(70, height - 10, 50):
        draw.line((columns[0], y if y == 70 else y + 30, columns[-1], y if y == 70 else y + 30),
                  fill=(120, 120, 130), width=1)
    draw.line((columns[0], 100, columns[-1], 100), fill=black, width=2)
    for x in columns:
        draw.line((x, 70, x, height - 20), fill=(120, 120, 130), width=1)
    rows = [("BR 031", "4182231", "R.M."), ("BR 017", "4182237", "R.M."),
            ("BR 044", "4182242", "R.M."), ("BR 009", "4182249", "R.M."),
            ("BR 026", "4182253", "R.M.")]
    hand = font(19, False)
    for index, (van, number, by) in enumerate(rows):
        top = 100 + index * 50
        for column, text in enumerate([van, number, by]):
            box = (columns[column], top, columns[column + 1], top + 50)
            left, upper, right, lower = draw.textbbox((0, 0), text, font=hand)
            x = box[0] + (box[2] - box[0] - (right - left)) / 2 - left
            draw.text((x, top + 14), text, font=hand, fill=ink)
        draw.line((335, top + 25, 350, top + 40), fill=ink, width=3)
        draw.line((350, top + 40, 378, top + 8), fill=ink, width=3)
    image.save(OUT / "seal_log_page.png")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    numbers()
    posters()
    legend()
    clock_face()
    time_cards()
    exit_signs()
    safety_signs()
    shipping_label()
    seal_log_page()
    for name in sorted(OUT.glob("*.png")):
        print(f"Wrote {name.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
