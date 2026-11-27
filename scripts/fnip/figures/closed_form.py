"""Closed-form phase portraits.

Book, node and saddle: Izhikevich, Figures 4.16 and 4.17, p. 105.
Book, flat curves: Guckenheimer and Holmes, (3.2.1), section 3.2,
p. 124, and Figure 3.2.1, p. 125.

--fig node-saddle (fnip-0039): solutions of
x' = -x, y' = -3y (stable node, y = K x^3) and
x' = x, y' = -y (saddle, x y = C).
Sampled uniformly in x. Screen origin (3, 1.650), one centimeter
per unit. Node curves use 28 points from |x| = 2.609 to |x| = 0.157,
with K x^3 equal to ±1.435 or ±0.359 at the outer end. Saddle curves
use 26 points, products ±0.823669 on [0.563, 2.661] and ±1.871177
on [1.279, 2.661], with both signs of x.

--fig flat (fnip-0062): y = C exp(1/x) for x < 0, the solutions of
x' = x^2, y' = -y. The screen origin is (3, 1.75) and one unit of x
is 2.48 cm. Four curves, 25 points, x screen from 0.37 to 2.77.
The initial screen heights are 2.86, 2.28, 1.32 and 0.74.

The prose does not print the decimals this script reports.
"""
import math
import re
import sys
from pathlib import Path


def node_saddle_lists():
    curves = []
    for y0 in (1.435, 0.359):
        for sx, sy in ((1, 1), (-1, -1), (1, -1), (-1, 1)):
            x0 = sx * 2.609
            x1 = sx * 0.157
            k = (sy * y0) / (x0 ** 3)
            pts = []
            for i in range(28):
                x = x0 + (x1 - x0) * i / 27
                pts.append((3 + x, 1.650 + k * x ** 3))
            curves.append(pts)
    saddles = (
        (0.563, 2.661, 0.823669),
        (1.279, 2.661, 1.871177),
    )
    for x0, x1, c0 in saddles:
        for sx, sc in ((1, 1), (-1, 1), (1, -1), (-1, -1)):
            pts = []
            for i in range(26):
                x = sx * (x0 + (x1 - x0) * i / 25)
                c = sc * c0
                pts.append((3 + x, 1.650 + c / x))
            curves.append(pts)
    return curves


def flat_lists():
    beta = 2.48
    heights = (2.86, 2.28, 1.32, 0.74)
    curves = []
    for height in heights:
        c = (height - 1.75) / math.exp(beta / (0.37 - 3))
        pts = []
        for i in range(25):
            screen = 0.37 + (2.77 - 0.37) * i / 24
            y = c * math.exp(beta / (screen - 3))
            pts.append((screen, 1.75 + y))
        curves.append(pts)
    return curves


FIGS = {
    "node-saddle": ("fnip-0039.tree", node_saddle_lists),
    "flat": ("fnip-0062.tree", flat_lists),
}


def trees_dir():
    if "--trees" in sys.argv:
        return Path(sys.argv[sys.argv.index("--trees") + 1])
    candidate = Path(__file__).resolve().parents[3] / "trees"
    if candidate.is_dir():
        return candidate
    raise SystemExit("pass --trees DIR")


def published(tree):
    text = (trees_dir() / tree).read_text()
    return [
        [
            (float(a), float(b))
            for a, b in re.findall(
                r"\(([+-]?\d+\.\d+)\s*,\s*([+-]?\d+\.\d+)\)", body
            )
        ]
        for body in re.findall(r"plot coordinates \{([^{}]*)\}", text)
    ]


def deviation(got, pub):
    if len(got) != len(pub):
        return None
    worst = 0.0
    for (a, b), (c, d) in zip(got, pub):
        worst = max(worst, abs(round(a, 3) - c), abs(round(b, 3) - d))
    return worst


def check_all():
    failed = 0
    for name, (tree, builder) in FIGS.items():
        got = builder()
        pub = published(tree)
        if len(got) != len(pub):
            print("FAIL", name, "lists", len(got), len(pub))
            failed += 1
            continue
        worst = 0.0
        bad = False
        for i, (g, p) in enumerate(zip(got, pub)):
            m = deviation(g, p)
            if m is None or m > 0.01 + 1e-9:
                print("FAIL", name, i, m, "len", len(g), len(p))
                bad = True
                break
            worst = max(worst, m)
        if bad:
            failed += 1
        else:
            print("check", name, tree, "lists", len(got), "max", f"{worst:.4f}")
    return failed


def main():
    args = sys.argv[1:]
    if "--check" in args:
        sys.exit(check_all())
    if "--fig" in args:
        name = args[args.index("--fig") + 1]
        for pts in FIGS[name][1]():
            body = " ".join("({:.3f},{:.3f})".format(x, y) for x, y in pts)
            print("plot coordinates {" + body + "}")
        return
    raise SystemExit("use --fig or --check")


if __name__ == "__main__":
    main()
