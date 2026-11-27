"""Trace-determinant plane.

Book: Izhikevich, Figure 4.15, p. 104, for the trace-determinant
plane. The parabola is tau^2 = 4 Delta. Morris-Lecar uses the Hopf
column of Ermentrout and Terman, Table 3.1, p. 51. The FitzHugh-Nagumo
mark is the origin of V' = V (0.1 - V) (V - 1) - w, w' = 0.01 V - 0.02 w.

--fig plane (fnip-0040): both parabolas are tau^2 = 4 Delta, 81 points.
Zoomed panel: Delta from -0.004 to 0.022, tau from -0.20 to 0.10,
x = 1.031 + 257.7 Delta, y = 4 + 20 tau.
Wide panel: Delta from -0.9 to 2.8, tau from -2.7 to 2.7,
x = (Delta + 0.9) * 6.7 / 3.7, y = (tau + 2.7) * 5.7 / 5.4.
The three marks are the Hopf-column equilibria at I_app = 60 and 100
and the FitzHugh-Nagumo origin, on the zoomed axes.

The prose does not print the decimals this script reports.
"""
import math
import re
import sys
from pathlib import Path

PHI, GCA, V3, V4 = 0.04, 4.4, 2.0, 30.0
ECA, EK, EL = 120.0, -84.0, -60.0
GK, GL, V1, V2, CM = 8.0, 2.0, -1.2, 18.0, 20.0


def minf(v):
    return 0.5 * (1 + math.tanh((v - V1) / V2))


def ninf(v):
    return 0.5 * (1 + math.tanh((v - V3) / V4))


def ionic(v, n):
    return GL * (v - EL) + GK * n * (v - EK) + GCA * minf(v) * (v - ECA)


def eq_v(current):
    lo, hi = -80.0, 80.0
    for _ in range(70):
        mid = 0.5 * (lo + hi)
        if (ionic(lo, ninf(lo)) - current) * (ionic(mid, ninf(mid)) - current) <= 0:
            hi = mid
        else:
            lo = mid
    return 0.5 * (lo + hi)


def jacobian(v, n):
    mp = 0.5 * (1 - math.tanh((v - V1) / V2) ** 2) / V2
    np_ = 0.5 * (1 - math.tanh((v - V3) / V4) ** 2) / V4
    ch = math.cosh((v - V3) / (2 * V4))
    a = (-GL - GK * n - GCA * minf(v) - GCA * mp * (v - ECA)) / CM
    b = -GK * (v - EK) / CM
    c = PHI * np_ * ch
    d = -PHI * ch
    return a + d, a * d - b * c


def parabola(t0, t1, count, x_of, y_of):
    pts = []
    for i in range(count):
        tau = t0 + (t1 - t0) * i / (count - 1)
        pts.append((x_of(tau * tau / 4), y_of(tau)))
    return pts


def marks():
    out = []
    for current in (60, 100):
        v = eq_v(current)
        trace, det = jacobian(v, ninf(v))
        out.append((1.031 + 257.7 * det, 4 + 20 * trace))
    # FitzHugh-Nagumo origin, a = 0.1, b = 0.01, c = 0.02: trace -0.12, det 0.012.
    out.insert(1, (1.031 + 257.7 * 0.012, 4 + 20 * (-0.12)))
    return out


def plane_lists():
    zoom = parabola(
        -0.20,
        0.10,
        81,
        lambda det: 1.031 + 257.7 * det,
        lambda tau: 4 + 20 * tau,
    )
    wide = parabola(
        -2.7,
        2.7,
        81,
        lambda det: (det + 0.9) * 6.7 / 3.7,
        lambda tau: (tau + 2.7) * 5.7 / 5.4,
    )
    return [zoom, wide]


def trees_dir():
    if "--trees" in sys.argv:
        return Path(sys.argv[sys.argv.index("--trees") + 1])
    candidate = Path(__file__).resolve().parents[3] / "trees"
    if candidate.is_dir():
        return candidate
    raise SystemExit("pass --trees DIR")


def published(tree):
    text = (trees_dir() / tree).read_text()
    out = []
    for body in re.findall(r"plot coordinates \{([^{}]*)\}", text):
        out.append(
            [
                (float(a), float(b))
                for a, b in re.findall(
                    r"\(([+-]?\d+\.\d+)\s*,\s*([+-]?\d+\.\d+)\)", body
                )
            ]
        )
    return out


def deviation(got, pub):
    if len(got) != len(pub):
        return None
    worst = 0.0
    for (a, b), (c, d) in zip(got, pub):
        worst = max(worst, abs(round(a, 3) - c), abs(round(b, 3) - d))
    return worst


def check_plane():
    pub = published("fnip-0040.tree")
    got = plane_lists()
    if len(got) != len(pub):
        print("FAIL plane lists", len(got), len(pub))
        return 1
    worst = 0.0
    for i, (g, p) in enumerate(zip(got, pub)):
        m = deviation(g, p)
        if m is None or m > 0.01 + 1e-9:
            print("FAIL plane", i, m)
            return 1
        worst = max(worst, m)
    text = (trees_dir() / "fnip-0040.tree").read_text()
    found = [
        (float(a), float(b))
        for a, b in re.findall(
            r"(?:\\fill(?:\[black\])?|\\draw\[fill=white\]) \(([0-9.]+),([0-9.]+)\) circle",
            text,
        )
    ]
    # The tree draws the three zoomed marks in the order I=60, origin, I=100.
    expect = marks()
    mark_worst = 0.0
    if len(found) < 3:
        print("FAIL marks", len(found))
        return 1
    for (x, y), (px, py) in zip(expect, found[:3]):
        mark_worst = max(mark_worst, abs(round(x, 3) - px), abs(round(y, 3) - py))
    if mark_worst > 0.01 + 1e-9:
        print("FAIL marks", mark_worst, expect, found[:3])
        return 1
    print(
        "check plane fnip-0040.tree lists",
        len(got),
        "max",
        f"{worst:.4f}",
        "marks",
        f"{mark_worst:.4f}",
    )
    for current, (x, y) in zip((60, "origin", 100), expect):
        print(f"  mark {current} ({x:.3f}, {y:.3f})")
    return 0


def main():
    args = sys.argv[1:]
    if "--check" in args:
        sys.exit(check_plane())
    if "--fig" in args:
        for pts in plane_lists():
            body = " ".join("({:.3f},{:.3f})".format(x, y) for x, y in pts)
            print("plot coordinates {" + body + "}")
        for x, y in marks():
            print("mark ({:.3f},{:.3f})".format(x, y))
        return
    raise SystemExit("use --fig plane or --check")


if __name__ == "__main__":
    main()
