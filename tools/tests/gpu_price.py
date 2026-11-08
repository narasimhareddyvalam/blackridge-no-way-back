"""gpu_price.py <run.log> [more logs]: the GPU price of Assignment 6's effects from a windowed run of
game/tests/gpu_price.gd with Apple's Metal Performance HUD logging (MTL_HUD_ENABLED=1,
MTL_HUD_LOG_ENABLED=1).

Once a second the HUD writes to stderr "metal-HUD: <first frame>,<graphics memory>,<process
memory>," then a (present interval, GPU time) pair for each frame since the last line, both in
milliseconds. Each frame's end is placed in wall-clock time back from its line's time stamp. The
script prints each block, an effect shown or hidden, with its wall-clock window; a block takes the
frames that ended inside its window after its first `skip` seconds. A gap in the HUD's log (it
logs only while the window is in front) costs frames, not alignment.

An effect's price is the mean, over its cycles, of the shown block's mean GPU time minus the hidden
block's that follows it, so a drift in the GPU's time over a minute cancels. It is set against the
budgets in CHANGE-BRIEF.md section 8, with a 95% interval from the cycles' spread. Several logs
are read as one (their runs never overlap in time), so an effect measured in two runs pools its
cycles. Frames a second, from the HUD's present intervals, are shown beside them for reference.
"""
import re
import statistics
import sys
from datetime import datetime

BUDGETS = {"A1": 0.25, "A2": 0.20, "B1": 0.70, "B2": 0.30}
TOTAL_BUDGET = 1.45
HUD = re.compile(r"^(\d{4}-\d\d-\d\d \d\d:\d\d:\d\d\.\d+) .*metal-HUD: (.*)$")
BLOCK = re.compile(r"GPU PRICE BLOCK\|(\w+)\|(on|off)\|cycle (\d+)\|time ([\d.]+)-([\d.]+)"
                   r"\|skip ([\d.]+)\|particles (\d+)\|([^|]*)\|(.*)$")
# Two-sided 95% points of Student's t, by degrees of freedom; larger counts use 1.96.
T95 = {1: 12.71, 2: 4.30, 3: 3.18, 4: 2.78, 5: 2.57, 6: 2.45, 7: 2.36, 8: 2.31, 9: 2.26,
       10: 2.23, 12: 2.18, 15: 2.13, 20: 2.09, 25: 2.06, 30: 2.04, 40: 2.02, 60: 2.00}


def t95(df):
    for limit in sorted(T95):
        if df <= limit:
            return T95[limit]
    return 1.96


def read(path):
    frames, blocks, notes, lines = [], [], [], 0
    for line in open(path, encoding="utf-8", errors="replace"):
        line = line.rstrip("\n")
        hud = HUD.match(line)
        if hud:
            lines += 1
            stamp = datetime.strptime(hud.group(1), "%Y-%m-%d %H:%M:%S.%f").timestamp()
            values = [float(v) for v in hud.group(2).split(",") if v.strip()]
            pairs = values[3:]
            count = len(pairs) // 2
            elapsed = 0.0
            for index in range(count - 1, -1, -1):
                frames.append((stamp - elapsed / 1000.0, pairs[2 * index + 1], pairs[2 * index]))
                elapsed += pairs[2 * index]
            continue
        block = BLOCK.search(line)
        if block:
            blocks.append({
                "effect": block.group(1), "shown": block.group(2) == "on",
                "cycle": int(block.group(3)), "began": float(block.group(4)),
                "ended": float(block.group(5)), "skip": float(block.group(6)),
                "particles": int(block.group(7)), "view": block.group(8),
                "state": block.group(9),
            })
        elif line.startswith("GPU PRICE:"):
            notes.append(line)
    return frames, blocks, notes, lines


def gpu_times(frames, block, column=1):
    start = block["began"] + block["skip"]
    return [frame[column] for frame in frames if start < frame[0] <= block["ended"]]


def main(*paths):
    frames, blocks, notes, lines = [], [], [], 0
    for run, path in enumerate(paths):
        more = read(path)
        frames += more[0]
        blocks += [dict(block, cycle=(run, block["cycle"])) for block in more[1]]
        notes += [note for note in more[2] if note not in notes]
        lines += more[3]
    print("GPU price from the Metal Performance HUD's per-frame GPU time, Apple M4 (MacBook Air)")
    for note in notes:
        print(note)
    print("HUD lines %d, frames %d" % (lines, len(frames)))
    print()
    print("%-3s %-18s %6s %7s %7s %10s %10s %9s %9s  %s" % (
        "fx", "view", "cycles", "frames", "frames", "shown ms", "hidden ms", "price ms",
        "95% +/-", "state"))
    print("%-3s %-18s %6s %7s %7s" % ("", "", "", "shown", "hidden"))
    results = {}
    for effect in BUDGETS:
        mine = [b for b in blocks if b["effect"] == effect]
        if not mine:
            continue
        shown_all, hidden_all, prices, shown_present, hidden_present = [], [], [], [], []
        for cycle in sorted({b["cycle"] for b in mine}):
            on = [b for b in mine if b["cycle"] == cycle and b["shown"]]
            off = [b for b in mine if b["cycle"] == cycle and not b["shown"]]
            if not on or not off:
                continue
            on_times, off_times = gpu_times(frames, on[0]), gpu_times(frames, off[0])
            if len(on_times) < 5 or len(off_times) < 5:
                continue
            shown_all += on_times
            hidden_all += off_times
            shown_present += gpu_times(frames, on[0], 2)
            hidden_present += gpu_times(frames, off[0], 2)
            prices.append(statistics.fmean(on_times) - statistics.fmean(off_times))
        if len(prices) < 2:
            print("%-3s %-18s too few complete cycles (%d)" % (effect, mine[0]["view"], len(prices)))
            continue
        price = statistics.fmean(prices)
        half = t95(len(prices) - 1) * statistics.stdev(prices) / len(prices) ** 0.5
        results[effect] = (price, half, 1000.0 / statistics.fmean(shown_present),
                           1000.0 / statistics.fmean(hidden_present))
        print("%-3s %-18s %6d %7d %7d %10.3f %10.3f %9.3f %9.3f  %s" % (
            effect, mine[0]["view"], len(prices), len(shown_all), len(hidden_all),
            statistics.fmean(shown_all), statistics.fmean(hidden_all), price, half,
            "%d particles; %s" % (mine[0]["particles"], mine[-1]["state"] or "-")))
    print()
    print("%-3s %10s %20s %8s  %-30s %s" % (
        "fx", "price ms", "95% interval", "budget", "against it", "frames/s shown, hidden"))
    total, total_var = 0.0, 0.0
    for effect, (price, half, fps_on, fps_off) in results.items():
        budget = BUDGETS[effect]
        low, high = price - half, price + half
        verdict = ("within" if high <= budget else "over" if low > budget
                   else "not settled at this precision")
        total += price
        total_var += (half / 1.96) ** 2
        print("%-3s %10.3f %9.3f to %7.3f %8.2f  %-30s %.1f, %.1f" % (
            effect, price, low, high, budget, verdict, fps_on, fps_off))
    if len(results) == len(BUDGETS):
        half = 1.96 * total_var ** 0.5
        verdict = ("within" if total + half <= TOTAL_BUDGET else "over"
                   if total - half > TOTAL_BUDGET else "not settled at this precision")
        print("%-3s %10.3f %9.3f to %7.3f %8.2f  %s" % (
            "all", total, total - half, total + half, TOTAL_BUDGET, verdict))


if __name__ == "__main__":
    main(*sys.argv[1:])
