"""FitzHugh-Nagumo figures.

Book: Izhikevich, Figures 4.20 and 4.22, and the form
V' = V (a - V) (V - 1) - w + I, w' = b V - c w.
No Morris-Lecar table column.

--fig nullclines (fnip-0018): I = 0, b = 0.01, c = 0.02, a = 0.1 and a = -0.1.
Nullclines are closed forms sampled at Delta V = 0.02 on [-0.55, 1.15],
kept where w is in [-0.22, 0.26]. Orbits are classical RK4 with h = 0.01.
Initial points and spans: (0.55, 0) for 140 at record 1;
(-0.40, 0.06) for 50 at record 0.8; (0.18, 0) for 14 at record 0.35;
(-0.15, 0.16) for 8 at record 0.4.
Axis: x = (V + 0.55) / 1.70 * 6.05, y = (w + 0.22) / 0.48 * 3.25.

--fig separatrices (fnip-0047): Izhikevich, Figure 4.22, p. 109.
I = 0, a = c = 0.1, b = 0.01. Axis: x = (V + 0.45) * 4.2,
y = (w + 0.06) * 3.5 / 0.32.
Nullclines omit voltage indices 12, 25, 37, 50 and 63 of the
Delta V = 0.02 grid on [-0.45, 1.05]. Eigenlines have half-length
0.22. The right stable branch is the stable-manifold graph out to
the published outer voltage, then 71 equal state-arc samples.
The left stable branch is that graph from the published outer
voltage back to the saddle, with state step 0.0041 doubled up to
0.01. Each unstable branch is classical RK4, h = 0.005, from the
saddle to the node or the focus, then 71 equal state-arc samples.

The prose does not print the decimals this script reports.
"""
import math
import re
import sys
from pathlib import Path

A0, A1, B0, B1 = -0.55, 1.15, -0.22, 0.26
W, H = 6.05, 3.25


def xf(v):
    return (v - A0) / (A1 - A0) * W


def yf(w):
    return (w - B0) / (B1 - B0) * H


def fhn(y, a, b=0.01, c=0.02, current=0.0):
    v, w = y
    return (v * (a - v) * (v - 1) - w + current, b * v - c * w)


def rk4(y, func, h):
    k1 = func(y)
    k2 = func((y[0] + 0.5 * h * k1[0], y[1] + 0.5 * h * k1[1]))
    k3 = func((y[0] + 0.5 * h * k2[0], y[1] + 0.5 * h * k2[1]))
    k4 = func((y[0] + h * k3[0], y[1] + h * k3[1]))
    return (
        y[0] + h * (k1[0] + 2 * k2[0] + 2 * k3[0] + k4[0]) / 6,
        y[1] + h * (k1[1] + 2 * k2[1] + 2 * k3[1] + k4[1]) / 6,
    )


def traj(y0, a, span, record, h=0.01):
    y = tuple(y0)
    pts = [y]
    every = max(1, int(round(record / h)))
    steps = int(round(span / h))
    for i in range(steps):
        y = rk4(y, lambda z, a=a: fhn(z, a), h)
        if (i + 1) % every == 0:
            pts.append(y)
    return pts


def cubic(a):
    pts = []
    v = A0
    while v <= A1 + 1e-12:
        w = v * (a - v) * (v - 1)
        if B0 <= w <= B1:
            pts.append((xf(v), yf(w)))
        v += 0.02
    return pts


def wline(slope):
    pts = []
    v = A0
    while v <= A1 + 1e-12:
        w = slope * v
        if B0 <= w <= B1:
            pts.append((xf(v), yf(w)))
        v += 0.02
    return pts


def nullcline_lists():
    orbits = [
        traj((0.55, 0.0), 0.1, 140, 1.0),
        traj((-0.40, 0.06), 0.1, 50, 0.8),
        traj((0.18, 0.0), -0.1, 14, 0.35),
        traj((-0.15, 0.16), -0.1, 8, 0.4),
    ]
    mapped = [[(xf(v), yf(w)) for v, w in raw] for raw in orbits]
    return [
        cubic(0.1),
        wline(0.5),
        mapped[0],
        mapped[1],
        cubic(-0.1),
        wline(0.5),
        mapped[2],
        mapped[3],
    ]


SX, SY = 4.2, 3.5 / 0.32
BA, BB, BC = 0.1, 0.01, 0.1


def XB(v):
    return (v + 0.45) * SX


def YB(w):
    return (w + 0.06) * SY


def bistable_field(v, w):
    return v * (BA - v) * (v - 1.0) - w, BB * v - BC * w


def eq_pair():
    disc = (BA + 1) ** 2 - 4 * (BA + BB / BC)
    radical = math.sqrt(disc)
    vs = (BA + 1 - radical) / 2
    vn = (BA + 1 + radical) / 2
    return (vs, BB / BC * vs), (vn, BB / BC * vn), (0.0, 0.0)


SADDLE, NODE, FOCUS = eq_pair()


def eigen_units():
    v = SADDLE[0]
    jdv = (BA - v) * (v - 1) + v * (-1) * (v - 1) + v * (BA - v)
    tr = jdv - BC
    det = jdv * (-BC) - (-1) * BB
    root = math.sqrt(tr * tr - 4 * det)
    lamp = (tr + root) / 2
    lamm = (tr - root) / 2

    def unit(lam):
        v2 = jdv - lam
        nrm = math.hypot(1.0, v2)
        return (1.0 / nrm, v2 / nrm), v2

    vu, _ = unit(lamp)
    vs, slope = unit(lamm)
    return vu, vs, slope, lamp, lamm


VU, VS, SLOPE, LAM_U, LAM_S = eigen_units()


def nullcline_voltages():
    omit = {12, 25, 37, 50, 63}
    return [-0.45 + i * 0.02 for i in range(76) if i not in omit]


def step_v(v, w, h):
    def slope(vv, ww):
        fv, fw = bistable_field(vv, ww)
        return fw / fv

    s1 = slope(v, w)
    s2 = slope(v + h / 2, w + h * s1 / 2)
    s3 = slope(v + h / 2, w + h * s2 / 2)
    s4 = slope(v + h, w + h * s3)
    return v + h, w + h * (s1 + 2 * s2 + 2 * s3 + s4) / 6.0


def graph_to(v_end, h=2e-4):
    step = -h if v_end < SADDLE[0] else h
    v = SADDLE[0] + math.copysign(1e-6, step)
    w = SADDLE[1] + math.copysign(1e-6, step) * SLOPE
    pts = [SADDLE, (v, w)]
    guard = 0
    while (v_end - v) * step > 0 and guard < 200000:
        guard += 1
        hh = step
        if (v_end - (v + hh)) * step < 0:
            hh = v_end - v
        v, w = step_v(v, w, hh)
        pts.append((v, w))
    return pts


def arc_sample(raw, n):
    seg = [0.0]
    for (v0, w0), (v1, w1) in zip(raw, raw[1:]):
        seg.append(seg[-1] + math.hypot(v1 - v0, w1 - w0))
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
        vv = raw[lo][0] + t * (raw[hi][0] - raw[lo][0])
        ww = raw[lo][1] + t * (raw[hi][1] - raw[lo][1])
        out.append((XB(vv), YB(ww)))
    return out


def eigen_segment(vec):
    ends = []
    for sign in (-1, 1):
        v = SADDLE[0] + sign * 0.22 * vec[0]
        w = SADDLE[1] + sign * 0.22 * vec[1]
        ends.append((XB(v), YB(w)))
    return ends


def stable_right():
    v_end = 6.394 / SX - 0.45
    return arc_sample(list(reversed(graph_to(v_end))), 71)


def stable_left():
    v_far = -0.090 / SX - 0.45
    v = SADDLE[0] - 1e-6
    w = SADDLE[1] - 1e-6 * SLOPE
    while v > v_far:
        h = -2e-4
        if v + h < v_far:
            h = v_far - v
        v, w = step_v(v, w, h)
    h = 0.0041
    pts = [(XB(v), YB(w))]
    guard = 0
    while v < SADDLE[0] - 1e-8 and guard < 5000:
        guard += 1
        hh = min(h, SADDLE[0] - v)
        v, w = step_v(v, w, hh)
        pts.append((XB(v), YB(w)))
        if h < 0.01:
            h = min(0.01, h * 2.0)
    pts[-1] = (XB(SADDLE[0]), YB(SADDLE[1]))
    return pts


def rk4_bi(v, w, h):
    k1 = bistable_field(v, w)
    k2 = bistable_field(v + h * k1[0] / 2, w + h * k1[1] / 2)
    k3 = bistable_field(v + h * k2[0] / 2, w + h * k2[1] / 2)
    k4 = bistable_field(v + h * k3[0], w + h * k3[1])
    return (
        v + h * (k1[0] + 2 * k2[0] + 2 * k3[0] + k4[0]) / 6,
        w + h * (k1[1] + 2 * k2[1] + 2 * k3[1] + k4[1]) / 6,
    )


def unstable(sign, target, n=71):
    v = SADDLE[0] + sign * 1e-8 * VU[0]
    w = SADDLE[1] + sign * 1e-8 * VU[1]
    raw = [(v, w)]
    for _ in range(200000):
        v, w = rk4_bi(v, w, 0.005)
        raw.append((v, w))
        if math.hypot(v - target[0], w - target[1]) < 1e-4:
            break
    raw = [SADDLE] + raw + [target]
    return arc_sample(raw, n)


def separatrix_lists():
    cubic_pts = []
    line_pts = []
    for v in nullcline_voltages():
        cubic_pts.append((XB(v), YB(v * (BA - v) * (v - 1.0))))
        line_pts.append((XB(v), YB((BB / BC) * v)))
    return [
        cubic_pts,
        line_pts,
        eigen_segment(VS),
        eigen_segment(VU),
        stable_right(),
        stable_left(),
        unstable(1, NODE),
        unstable(-1, FOCUS),
    ]


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


def check_one(tree, got):
    pub = published(tree)
    if len(got) != len(pub):
        print("FAIL", tree, "lists", len(got), len(pub))
        return 1
    worst = 0.0
    for i, (g, p) in enumerate(zip(got, pub)):
        m = deviation(g, p)
        if m is None or m > 0.01 + 1e-9:
            print("FAIL", tree, i, m, len(g), len(p))
            return 1
        worst = max(worst, m)
    print("check", tree, "lists", len(got), "max", f"{worst:.4f}")
    return 0


def main():
    args = sys.argv[1:]
    if "--check" in args:
        code = check_one("fnip-0018.tree", nullcline_lists())
        print(
            "separatrix eigenvalues",
            round(LAM_U, 4),
            round(LAM_S, 4),
        )
        code |= check_one("fnip-0047.tree", separatrix_lists())
        sys.exit(code)
    if "--fig" in args:
        name = args[args.index("--fig") + 1]
        if name == "nullclines":
            lists = nullcline_lists()
        elif name == "separatrices":
            print(
                "saddle",
                tuple(round(z, 6) for z in SADDLE),
                "eigenvalues",
                round(LAM_U, 6),
                round(LAM_S, 6),
            )
            lists = separatrix_lists()
        else:
            raise SystemExit("use --fig nullclines or --fig separatrices")
        for pts in lists:
            body = " ".join("({:.3f},{:.3f})".format(x, y) for x, y in pts)
            print("plot coordinates {" + body + "}")
        return
    raise SystemExit("use --fig nullclines, --fig separatrices, or --check")


if __name__ == "__main__":
    main()
