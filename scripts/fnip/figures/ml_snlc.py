"""Morris-Lecar, SNLC column of Table 3.1.

Book: Ermentrout and Terman, Table 3.1 SNLC column, p. 51, and
Figure 3.6a, p. 60.
Parameters: phi = 0.067, g_Ca = 4, V3 = 12, V4 = 17.4, E_Ca = 120,
E_K = -84, E_L = -60, g_K = 8, g_L = 2, V1 = -1.2, V2 = 18, C = 20.

--fig folds (fnip-0089): equilibrium voltage against applied current.
x = (I + 20) * 0.08, y = 0.400 + (V + 60) * 0.04.
The lower branch is V = -70, -68.4, ..., -30, then the lower fold.
The middle branch steps 1.2 mV from the lower fold and ends at the
upper fold. The upper branch steps 0.4 mV from the upper fold and
ends at the voltage where the steady current is 60.

--fig circle (fnip-0094): Ermentrout and Terman, Figure 3.5, p. 59.
I_before = I_SN2 - 2 and I_after = I_SN2 + 2.
Axis: x = (V + 60) * 3.2 / 90, y = 0.18640233 + 3.72712956 n.
The right panel is shifted by 4 cm and its coordinates are absolute.
Classical RK4. The long branch starts at the saddle plus 0.4 times
the unstable unit eigenvector, step h = 0.05 ms, and is recorded at
the times below, each a multiple of that step: 0, 22.85, 30.3, 34.65,
37.35, 39.4, then every 1 ms from 40.65 through 70.65, then 72.15,
74.15, 76.15, 78.65, 81.65, 84.65, 88.65, 93.9, 100.95, 111.75, 134.2.
The short branch uses the opposite offset and h = 0.02 ms until the
screen distance to the node is at most 0.045 cm, then 22 equal
centimeter-arc samples. The cycle is one return after the transient
from (-20, 0.2) at I_after, phase-matched to the first published
point (6.136, 0.336), then the 0.05 ms lattice below. The base stride
is 2.05 ms, doubled and tripled on the slow part of the orbit, and
the orbit is closed by repeating the first point.

The prose does not print the decimals this script reports.
"""
import math
import re
import sys
from pathlib import Path

GCA, V3, V4 = 4.0, 12.0, 17.4
ECA, EK, EL = 120.0, -84.0, -60.0
GK, GL, V1, V2 = 8.0, 2.0, -1.2, 18.0


def minf(v):
    return 0.5 * (1 + math.tanh((v - V1) / V2))


def ninf(v):
    return 0.5 * (1 + math.tanh((v - V3) / V4))


def steady(v):
    return GL * (v - EL) + GK * ninf(v) * (v - EK) + GCA * minf(v) * (v - ECA)


def dst(v):
    eps = 1e-5
    return (steady(v + eps) - steady(v - eps)) / (2 * eps)


def folds():
    found = []
    prev_v, prev_d = -80.0, dst(-80.0)
    v = -79.9
    while v <= 40:
        d = dst(v)
        if prev_d * d < 0:
            lo, hi = prev_v, v
            for _ in range(50):
                mid = 0.5 * (lo + hi)
                if dst(lo) * dst(mid) <= 0:
                    hi = mid
                else:
                    lo = mid
            found.append(0.5 * (lo + hi))
        prev_v, prev_d = v, d
        v += 0.1
    found.sort()
    return found


def x_of(current):
    return (current + 20) * 0.08


def y_of(v):
    return 0.400 + (v + 60) * 0.04


def fold_lists():
    sn2, sn1 = folds()
    lower = [-70.0 + 1.6 * i for i in range(26)]
    lower.append(sn2)
    middle = [sn2 + 1.2 * i for i in range(22)]
    middle.append(sn1)
    upper = []
    v = sn1
    while steady(v) < 60 and v < 20:
        upper.append(v)
        v += 0.4
    # The last published sample is the voltage whose steady current is 60.
    lo, hi = upper[-1], upper[-1] + 0.4
    for _ in range(40):
        mid = 0.5 * (lo + hi)
        if steady(mid) < 60:
            lo = mid
        else:
            hi = mid
    upper.append(0.5 * (lo + hi))
    return [
        [(x_of(steady(v)), y_of(v)) for v in lower],
        [(x_of(steady(v)), y_of(v)) for v in middle],
        [(x_of(steady(v)), y_of(v)) for v in upper],
    ]


PHI = 0.067
CM = 20.0
AY, BY = 0.18640233070998233, 3.727129562101114
LONG_TIMES = (
    [0.0, 22.85, 30.3, 34.65, 37.35, 39.4]
    + [40.65 + i for i in range(31)]
    + [
        72.15, 74.15, 76.15, 78.65, 81.65, 84.65,
        88.65, 93.9, 100.95, 111.75, 134.2,
    ]
)
CYCLE_TIMES = [
    0.0, 2.05, 4.1, 6.15, 8.2, 10.25, 12.3, 14.35, 16.4, 18.45, 20.5, 22.55,
    24.6, 26.65, 28.75, 30.75, 32.8, 34.85, 36.9, 38.95, 41.0, 43.05, 45.15,
    47.1, 49.25, 51.3, 53.3, 57.4, 61.5, 65.55, 69.8, 73.8, 77.85, 82.0, 88.2,
    94.3, 100.4, 106.5, 110.8, 114.85, 118.85, 123.0, 127.15, 129.2, 131.2,
    133.3, 135.35, 137.35, 139.4, 141.45, 143.5, 145.55,
]


def ionic(v, n):
    return GL * (v - EL) + GK * n * (v - EK) + GCA * minf(v) * (v - ECA)


def tau(v):
    return 1.0 / math.cosh(max(min((v - V3) / (2 * V4), 20.0), -20.0))


def field(v, n, current):
    return (current - ionic(v, n)) / CM, PHI * (ninf(v) - n) / tau(v)


def rk4(v, n, current, h):
    k1 = field(v, n, current)
    k2 = field(v + h * k1[0] / 2, n + h * k1[1] / 2, current)
    k3 = field(v + h * k2[0] / 2, n + h * k2[1] / 2, current)
    k4 = field(v + h * k3[0], n + h * k3[1], current)
    return (
        v + h * (k1[0] + 2 * k2[0] + 2 * k3[0] + k4[0]) / 6,
        n + h * (k1[1] + 2 * k2[1] + 2 * k3[1] + k4[1]) / 6,
    )


def equilibria(current):
    roots = []
    prev = None
    for k in range(7001):
        v = -70 + k * 0.02
        d = steady(v) - current
        if prev is not None and prev[1] * d < 0:
            lo, hi = prev[0], v
            for _ in range(40):
                mid = 0.5 * (lo + hi)
                if (steady(lo) - current) * (steady(mid) - current) <= 0:
                    hi = mid
                else:
                    lo = mid
            roots.append(0.5 * (lo + hi))
        prev = (v, d)
    return [(v, ninf(v)) for v in roots]


def unstable_vector(saddle, current):
    h = 1e-5
    f0 = field(saddle[0], saddle[1], current)
    fv = field(saddle[0] + h, saddle[1], current)
    fn = field(saddle[0], saddle[1] + h, current)
    a = (fv[0] - f0[0]) / h
    b = (fn[0] - f0[0]) / h
    c = (fv[1] - f0[1]) / h
    d = (fn[1] - f0[1]) / h
    tr = a + d
    det = a * d - b * c
    lam = (tr + math.sqrt(tr * tr - 4 * det)) / 2
    v2 = -(a - lam) / b
    nrm = math.hypot(1.0, v2)
    return (1.0 / nrm, v2 / nrm)


def screen(v, n, shift=0.0):
    return shift + (v + 60.0) * 3.2 / 90.0, AY + BY * n


def cm_resample(raw, n):
    seg = [0.0]
    for (x0, y0), (x1, y1) in zip(raw, raw[1:]):
        seg.append(seg[-1] + math.hypot(x1 - x0, y1 - y0))
    out = []
    for i in range(n):
        target = seg[-1] * i / (n - 1)
        lo, hi = 0, len(seg) - 1
        while lo + 1 < hi:
            mid = (lo + hi) // 2
            if seg[mid] < target:
                lo = mid
            else:
                hi = mid
        span = seg[hi] - seg[lo]
        t = 0.0 if span == 0 else (target - seg[lo]) / span
        out.append(
            (
                raw[lo][0] + t * (raw[hi][0] - raw[lo][0]),
                raw[lo][1] + t * (raw[hi][1] - raw[lo][1]),
            )
        )
    return out


def circle_lists():
    current = steady(folds()[0])
    before = current - 2.0
    after = current + 2.0
    node, saddle, _upper = sorted(equilibria(before))
    vu = unstable_vector(saddle, before)
    node_cm = screen(*node)

    def at_times(v, n, times, h, current_):
        out = []
        t = 0.0
        for target in times:
            while t < target - 1e-9:
                step = min(h, target - t)
                v, n = rk4(v, n, current_, step)
                t += step
            out.append((v, n))
        return out

    v0 = saddle[0] + 0.4 * vu[0]
    n0 = saddle[1] + 0.4 * vu[1]
    long_pts = [screen(v, n) for v, n in at_times(v0, n0, LONG_TIMES, 0.05, before)]

    v = saddle[0] - 0.4 * vu[0]
    n = saddle[1] - 0.4 * vu[1]
    short_raw = [screen(v, n)]
    for _ in range(20000):
        v, n = rk4(v, n, before, 0.02)
        pt = screen(v, n)
        short_raw.append(pt)
        if math.hypot(pt[0] - node_cm[0], pt[1] - node_cm[1]) <= 0.045:
            break
    short_pts = cm_resample(short_raw, 22)

    v, n = -20.0, 0.2
    prev = v
    cross = []
    trail = []
    t = 0.0
    h = 0.05
    while len(cross) < 3 and t < 2000:
        trail.append((v, n))
        vn, nn = rk4(v, n, after, h)
        if prev < -15 <= vn:
            cross.append(len(trail) - 1)
        prev, v, n = v, vn, nn
        t += h
    cyc = trail[cross[-2] : cross[-1]]
    period = len(cyc)
    v_star = (6.136 - 4.0) * 90.0 / 3.2 - 60.0
    n_star = (0.336 - AY) / BY
    target = screen(v_star, n_star, shift=4.0)
    best, j0 = 1e9, 0
    for j, (vv, nn) in enumerate(cyc):
        x, y = screen(vv, nn, shift=4.0)
        err = math.hypot(x - target[0], y - target[1])
        if err < best:
            best, j0 = err, j
    cycle_pts = []
    for rel in CYCLE_TIMES:
        k = int(round(rel / h))
        vv, nn = cyc[(j0 + k) % period]
        cycle_pts.append(screen(vv, nn, shift=4.0))
    cycle_pts.append(cycle_pts[0])
    return [long_pts, short_pts, cycle_pts]


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
    vs = folds()
    print("folds V", [round(v, 4) for v in vs], "I", [round(steady(v), 4) for v in vs])
    got = fold_lists()
    pub = published("fnip-0089.tree")
    if len(got) != len(pub):
        print("FAIL folds lists", len(got), len(pub))
        return 1
    worst = 0.0
    for i, (g, p) in enumerate(zip(got, pub)):
        m = deviation(g, p)
        if m is None or m > 0.01 + 1e-9:
            print("FAIL folds", i, m, "len", len(g), len(p))
            return 1
        worst = max(worst, m)
    print("check folds fnip-0089.tree lists", len(got), "max", f"{worst:.4f}")
    got = circle_lists()
    pub = published("fnip-0094.tree")
    if len(got) != len(pub):
        print("FAIL circle lists", len(got), len(pub))
        return 1
    worst = 0.0
    for i, (g, p) in enumerate(zip(got, pub)):
        m = deviation(g, p)
        if m is None or m > 0.01 + 1e-9:
            print("FAIL circle", i, m, "len", len(g), len(p))
            return 1
        worst = max(worst, m)
    print("check circle fnip-0094.tree lists", len(got), "max", f"{worst:.4f}")
    return 0


def emit(lists):
    for pts in lists:
        body = " ".join("({:.3f},{:.3f})".format(x, y) for x, y in pts)
        print("plot coordinates {" + body + "}")


def main():
    args = sys.argv[1:]
    if "--check" in args:
        sys.exit(check_all())
    if "--fig" in args:
        name = args[args.index("--fig") + 1]
        if name == "folds":
            emit(fold_lists())
            return
        if name == "circle":
            sn2 = folds()[0]
            print("SN2", round(sn2, 4), "I", round(steady(sn2), 4), file=sys.stderr)
            emit(circle_lists())
            return
    raise SystemExit("use --fig folds, --fig circle, or --check")


if __name__ == "__main__":
    main()
