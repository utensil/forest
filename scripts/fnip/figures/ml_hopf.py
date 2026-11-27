"""Morris-Lecar figures, Hopf column of Table 3.1.

Book: Ermentrout and Terman, (3.1), Table 3.1 Hopf column, p. 51.
Parameters: phi = 0.04, g_Ca = 4.4, V3 = 2, V4 = 30, E_Ca = 120,
E_K = -84, E_L = -60, g_K = 8, g_L = 2, V1 = -1.2, V2 = 18, C = 20.

--fig orbit (fnip-0011): classical RK4, h = 0.01 ms, from (0, n_R) at
I_app = 60, sampled every 1 ms on [0, 80]. Orbit x = 3.5 + V/20,
y = 5.818 n. Trace x = 0.075 t, y = 1.517 + 0.02165 V.
--fig nullclines (fnip-0017): closed-form nullclines at Delta V = 1 mV
on V in [-72, 46], n in [0, 0.58], axis width 6.05 and height 3.25.
Orbits at I_app = 60 from (0, n_R) for 80 ms and from (-50, 0.2) for
45 ms, and at I_app = 100 from (-60, 0.25) for 100 ms, classical RK4,
h = 0.01, sampled every 1 ms. The periodic orbit is one return at
I_app = 100 after a 450 ms transient, h = 0.02, kept every 50 steps,
closed by repeating the first point.
--fig equilibrium (fnip-0084): equilibrium voltage against I_app from
0 to 250 at step 2, split at the printed 94 and 212.
x = 0.0224 I, y = 0.159 + (V + 60) * 0.03175.
--fig foci (fnip-0037): the linearization at each focus, sampled on a
uniform time grid. At I_app = 60 the two solutions start at
displacements (2, 0) and (-1.5, 0) and run to 150 ms (80 and 70
points); the middle drawing is the voltage of the first of those.
At I_app = 100 the solutions start at (0.4, 0) and (-0.3, 0) and run
to 80 ms and 70 ms (90 and 70 points).
--fig spiral (fnip-0046): both curves start at displacement (2, 0).
The sample times are 0 and then 0.025 * (1 + 53 j) ms. The upper
curve is the exact linearization. The lower curve is classical RK4
with h = 0.025.
--fig cycle (fnip-0056): at I_app = 100. The transient starts at
(-60, 0.05), classical RK4, h = 0.05, for 70 ms, then 100 evenly
indexed samples. The periodic orbit is one return after a 300 ms
transient, h = 0.02, reduced to 140 samples; the voltage drawing is
two returns, reduced to 180 samples. The zoom is the orbit from
(V* + 1.2, n*) until it leaves the window, h = 0.02, reduced to 80
samples. The dashed ellipse is the curve
V = V* + 0.6324 cos theta + 0.7804 sin theta,
n = n* + 0.004 cos theta, 81 equally spaced angles.
--fig bistable (fnip-0102): phase plane at I_app = 90. Nullclines use
the same window and step as --fig nullclines. The outer orbit is one
return of the upcrossing of V* after a 400 ms transient from (0, 0.4),
classical RK4, h = 0.02, reduced to 120 samples and closed. The inner
orbit is the same section run backward from (V* + 4, n*) after 900 ms,
then reversed so the sample order is forward time, reduced to 80 samples
and closed. Stderr reports the stability signs and no prose decimal.

The prose does not print the decimals this script reports.
"""
import math
import re
import sys
from pathlib import Path

PHI, GCA, V3, V4 = 0.04, 4.4, 2.0, 30.0
ECA, EK, EL = 120.0, -84.0, -60.0
GK, GL, V1, V2, CM = 8.0, 2.0, -1.2, 18.0, 20.0
VLO, VHI, NLO, NHI = -72.0, 46.0, 0.0, 0.58
WIDTH, HEIGHT = 6.05, 3.25


def minf(v):
    import math
    return 0.5 * (1 + math.tanh((v - V1) / V2))


def ninf(v):
    import math
    return 0.5 * (1 + math.tanh((v - V3) / V4))


def tau(v):
    import math
    return 1.0 / math.cosh((v - V3) / (2 * V4))


def ionic(v, n):
    return GL * (v - EL) + GK * n * (v - EK) + GCA * minf(v) * (v - ECA)


def field(v, n, current):
    return (current - ionic(v, n)) / CM, PHI * (ninf(v) - n) / tau(v)


def rk4(v, n, current, h):
    k1 = field(v, n, current)
    k2 = field(v + 0.5 * h * k1[0], n + 0.5 * h * k1[1], current)
    k3 = field(v + 0.5 * h * k2[0], n + 0.5 * h * k2[1], current)
    k4 = field(v + h * k3[0], n + h * k3[1], current)
    return (
        v + h * (k1[0] + 2 * k2[0] + 2 * k3[0] + k4[0]) / 6,
        n + h * (k1[1] + 2 * k2[1] + 2 * k3[1] + k4[1]) / 6,
    )


def eq_v(current, lo=-80.0, hi=60.0):
    for _ in range(80):
        mid = 0.5 * (lo + hi)
        if (ionic(lo, ninf(lo)) - current) * (ionic(mid, ninf(mid)) - current) <= 0:
            hi = mid
        else:
            lo = mid
    return 0.5 * (lo + hi)


def xm(v):
    return (v - VLO) / (VHI - VLO) * WIDTH


def ym(n):
    return (n - NLO) / (NHI - NLO) * HEIGHT


def n_of_v(v, current):
    return (current - GL * (v - EL) - GCA * minf(v) * (v - ECA)) / (GK * (v - EK))


def null_curve(current, kind):
    pts = []
    v = VLO
    while v <= VHI + 1e-9:
        y = ninf(v) if kind == "n" else n_of_v(v, current)
        if NLO <= y <= NHI:
            pts.append((xm(v), ym(y)))
        v += 1.0
    return pts


def integrate(v, n, current, h, span, every):
    pts = [(v, n)]
    steps = int(round(span / h))
    stride = int(round(every / h))
    for i in range(steps):
        v, n = rk4(v, n, current, h)
        if (i + 1) % stride == 0:
            pts.append((v, n))
    return pts


def periodic():
    ve = eq_v(100)
    ne = ninf(ve)
    v, n = 0.0, ne
    h = 0.02
    for _ in range(int(round(450 / h))):
        v, n = rk4(v, n, 100, h)
    raw = []
    prev = v
    idx = []
    t = 0.0
    while len(idx) < 2 and t < 300:
        v, n = rk4(v, n, 100, h)
        t += h
        raw.append((v, n))
        if prev < ve <= v:
            idx.append(len(raw) - 1)
        prev = v
    cycle = raw[idx[0] : idx[1] + 1 : 50]
    if cycle[-1] != raw[idx[1]]:
        cycle.append(raw[idx[1]])
    cycle.append(cycle[0])
    return [(xm(v), ym(n)) for v, n in cycle]


def orbit_lists():
    nr = ninf(eq_v(60))
    v, n = 0.0, nr
    orb, trc = [], []
    for k in range(0, 8001):
        if k % 100 == 0:
            t = k * 0.01
            orb.append((3.5 + v / 20.0, 5.818 * n))
            trc.append((0.075 * t, 1.517 + 0.02165 * v))
        if k == 8000:
            break
        v, n = rk4(v, n, 60, 0.01)
    return [orb, trc]


def nullcline_lists():
    nr = ninf(eq_v(60))
    spike = integrate(0.0, nr, 60, 0.01, 80, 1.0)
    quiet = integrate(-50.0, 0.2, 60, 0.01, 45, 1.0)
    trans = integrate(-60.0, 0.25, 100, 0.01, 100, 1.0)
    return [
        null_curve(60, "v"),
        null_curve(60, "n"),
        [(xm(v), ym(n)) for v, n in spike],
        [(xm(v), ym(n)) for v, n in quiet],
        null_curve(100, "v"),
        null_curve(100, "n"),
        periodic(),
        [(xm(v), ym(n)) for v, n in trans],
    ]


def equilibrium_lists():
    def x_of(current):
        return current * 0.0224

    def y_of(v):
        return 0.159 + (v + 60) * 0.03175

    segs = [[], [], []]
    current = 0.0
    while current <= 250 + 1e-9:
        v = eq_v(current, -80, 80)
        pt = (x_of(current), y_of(v))
        if current <= 94:
            segs[0].append(pt)
        if 94 <= current <= 212:
            segs[1].append(pt)
        if current >= 212:
            segs[2].append(pt)
        current += 2.0
    return segs


def jacobian(v, n):
    mp = 0.5 * (1 - math.tanh((v - V1) / V2) ** 2) / V2
    np_ = 0.5 * (1 - math.tanh((v - V3) / V4) ** 2) / V4
    u = (v - V3) / (2 * V4)
    ch = math.cosh(u)
    return (
        (-GL - GK * n - GCA * minf(v) - GCA * mp * (v - ECA)) / CM,
        -GK * (v - EK) / CM,
        PHI * np_ * ch,
        -PHI * ch,
    )


def linear_at(jac, y0, times):
    a, b, c, d = jac
    tr = a + d
    det = a * d - b * c
    alpha = tr / 2
    omega = math.sqrt(4 * det - tr * tr) / 2

    def step(y, h):
        ea = math.exp(alpha * h)
        co = math.cos(omega * h)
        si = math.sin(omega * h) / omega
        return (
            ea * ((co + si * (a - alpha)) * y[0] + si * b * y[1]),
            ea * (si * c * y[0] + (co + si * (d - alpha)) * y[1]),
        )

    y = y0
    prev = 0.0
    out = []
    for t in times:
        y = step(y, t - prev)
        prev = t
        out.append(y)
    return out


def foci_lists():
    vr, nr = eq_v(60), ninf(eq_v(60))
    ve, ne = eq_v(100), ninf(eq_v(100))
    j60 = jacobian(vr, nr)
    j100 = jacobian(ve, ne)

    def grid(n, span):
        return [span * i / (n - 1) for i in range(n)]

    x60 = lambda dv: 3.100 + 1.2915 * dv
    y60 = lambda dn: 1.575 + 562.5 * dn
    x100 = lambda dv: 3.100 + 2.067 * dv
    y100 = lambda dn: 1.938 + 242.5 * dn
    xt = lambda t: t * 6.2 / 150
    yt = lambda dv: 0.424 + 0.8475 * dv
    a = linear_at(j60, (2.0, 0.0), grid(80, 150))
    b = linear_at(j60, (-1.5, 0.0), grid(70, 150))
    c = linear_at(j60, (2.0, 0.0), grid(110, 150))
    d = linear_at(j100, (0.4, 0.0), grid(90, 80))
    e = linear_at(j100, (-0.3, 0.0), grid(70, 70))
    return [
        [(x60(p[0]), y60(p[1])) for p in a],
        [(x60(p[0]), y60(p[1])) for p in b],
        [(xt(t), yt(p[0])) for t, p in zip(grid(110, 150), c)],
        [(x100(p[0]), y100(p[1])) for p in d],
        [(x100(p[0]), y100(p[1])) for p in e],
    ]


def spiral_lists():
    vr = eq_v(60)
    nr = ninf(vr)
    times = [0.0] + [0.025 * (1 + 53 * j) for j in range(121)]
    linear = linear_at(jacobian(vr, nr), (2.0, 0.0), times)
    v, n = vr + 2.0, nr
    nonlinear = [(2.0, 0.0)]
    prev = 0
    for t in times[1:]:
        steps = int(round((t - prev) / 0.025))
        for _ in range(steps):
            v, n = rk4(v, n, 60, 0.025)
        nonlinear.append((v - vr, n - nr))
        prev = t
    x = lambda dv: 0.840 + 2.4 * dv
    y = lambda dn: 0.262 + 1049.5 * dn
    return [
        [(x(p[0]), y(p[1])) for p in linear],
        [(x(p[0]), y(p[1])) for p in nonlinear],
    ]


def decimate(seq, count):
    if len(seq) == count:
        return list(seq)
    step = (len(seq) - 1) / (count - 1)
    return [seq[int(round(i * step))] for i in range(count)]


def cycle_lists():
    ve, ne = eq_v(100), ninf(eq_v(100))

    def xv(v):
        return (v + 70) / 150 * 6

    def yn(n):
        return n * 3.2

    def xz(v):
        return (v + 26) / 8 * 6

    def yz(n):
        return (n - 0.145) / 0.030 * 3

    def xt(t):
        return t / 170 * 6

    def yv(v):
        return (v + 60) / 110 * 3

    v, n = -60.0, 0.05
    trail = [(v, n)]
    for _ in range(int(round(70 / 0.05))):
        v, n = rk4(v, n, 100, 0.05)
        trail.append((v, n))
    transient = [(xv(v), yn(n)) for v, n in decimate(trail, 100)]

    v, n = ve + 1.2, ne
    for _ in range(int(round(300 / 0.02))):
        v, n = rk4(v, n, 100, 0.02)
    raw = []
    prev = v
    crosses = []
    t = 0.0
    while len(crosses) < 3 and t < 250:
        v, n = rk4(v, n, 100, 0.02)
        t += 0.02
        raw.append((t, v, n))
        if prev < ve <= v:
            crosses.append(len(raw) - 1)
        prev = v
    seg = raw[crosses[-2] : crosses[-1] + 1]
    cycle = [(xv(p[1]), yn(p[2])) for p in decimate(seg, 140)]
    vt = [(p[0] - seg[0][0], p[1]) for p in seg]
    period = vt[-1][0]
    vt2 = vt + [(period + p[0], p[1]) for p in vt[1:]]
    voltage = [(xt(p[0]), yv(p[1])) for p in decimate(vt2, 180)]

    ellipse = []
    for k in range(81):
        theta = 2 * math.pi * k / 80
        vv = ve + 0.6324 * math.cos(theta) + 0.7804 * math.sin(theta)
        nn = ne + 0.004 * math.cos(theta)
        ellipse.append((xz(vv), yz(nn)))

    v, n = ve + 1.2, ne
    zoom_raw = [(v, n)]
    for _ in range(int(200 / 0.02)):
        v, n = rk4(v, n, 100, 0.02)
        if v < -26 or n < 0.145 or n > 0.175:
            break
        zoom_raw.append((v, n))
    zoom = [(xz(v), yz(n)) for v, n in decimate(zoom_raw, 80)]
    return [transient, cycle, ellipse, zoom, voltage]


def upcrossings(v, n, current, h, count):
    ve = eq_v(current)
    prev = v
    hits = []
    pts = []
    t = 0.0
    while len(hits) < count and t < 2000:
        v, n = rk4(v, n, current, h)
        t += abs(h)
        pts.append((v, n))
        if prev < ve <= v:
            hits.append(len(pts) - 1)
        prev = v
    if len(hits) < count:
        raise SystemExit("section did not return")
    return pts, hits


def bistable_lists():
    current = 90.0
    ve, ne = eq_v(current), ninf(eq_v(current))
    v, n = 0.0, 0.4
    for _ in range(int(round(400 / 0.02))):
        v, n = rk4(v, n, current, 0.02)
    outer_raw, outer_hits = upcrossings(v, n, current, 0.02, 2)
    outer = decimate(outer_raw[outer_hits[0] : outer_hits[1] + 1], 120)
    outer.append(outer[0])

    v, n = ve + 4.0, ne
    for _ in range(int(round(900 / 0.02))):
        v, n = rk4(v, n, current, -0.02)
    inner_raw, inner_hits = upcrossings(v, n, current, -0.02, 2)
    inner = decimate(inner_raw[inner_hits[0] : inner_hits[1] + 1], 80)
    inner.reverse()
    inner.append(inner[0])

    a, b, c, d = jacobian(ve, ne)
    print("author-check I=90 trace", "negative" if a + d < 0 else "NONNEGATIVE", file=sys.stderr)
    # A displacement off each orbit, one return, compared with the section gap.
    def gap(orbit, step):
        v0, n0 = orbit[0]
        w, z = v0, n0 + 0.004
        for _ in range(int(round(80 / abs(step)))):
            w, z = rk4(w, z, current, step)
        back, hits = upcrossings(w, z, current, step, 1)
        return abs(back[hits[0]][1] - n0)

    print(
        "author-check inner displacement grows"
        if gap(inner, 0.02) > 0.004
        else "author-check INNER DID NOT GROW",
        file=sys.stderr,
    )
    print(
        "author-check outer displacement shrinks"
        if gap(outer, 0.02) < 0.004
        else "author-check OUTER DID NOT SHRINK",
        file=sys.stderr,
    )
    return [
        null_curve(current, "v"),
        null_curve(current, "n"),
        [(xm(v), ym(n)) for v, n in inner],
        [(xm(v), ym(n)) for v, n in outer],
    ]


FIGS = {
    "orbit": ("fnip-0011.tree", orbit_lists),
    "nullclines": ("fnip-0017.tree", nullcline_lists),
    "foci": ("fnip-0037.tree", foci_lists),
    "spiral": ("fnip-0046.tree", spiral_lists),
    "cycle": ("fnip-0056.tree", cycle_lists),
    "equilibrium": ("fnip-0084.tree", equilibrium_lists),
    "bistable": ("fnip-0102.tree", bistable_lists),
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
                print("FAIL", name, i, m)
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
