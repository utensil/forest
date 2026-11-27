"""Hodgkin-Huxley figure coordinates.

Book: Ermentrout and Terman, pp. 23-25, (1.43) and the gating rates.
No Morris-Lecar table column. Parameters: C = 1 uF/cm^2 (Izhikevich, p. 38),
phi = 1, g_Na = 120, g_K = 36, g_L = 0.3 mS/cm^2, E_Na = 50, E_K = -77,
E_L = -54.4 mV. Conductances are written in mS/cm^2, as the notes print them.

--fig steady (fnip-0071): steady values and time constants on
V = -100, -95, ..., 40. Closed form, no time step.
--fig clamp (fnip-0072): voltage clamp to 0 mV from the rest gates.
Closed form at t = 0, 0.25, ..., 6 ms.
--fig spike (fnip-0073): spike from rest plus 10 mV at I = 0.
Classical RK4, dt = 0.0025 ms, span 0-20 ms, sampled every 0.2 ms.
Initial point: (V_rest + 10 mV, n_rest, m_rest, h_rest).

The prose does not print the decimals this script reports.
"""
import math
import re
import sys
from pathlib import Path

GNA, GK, GL = 120.0, 36.0, 0.3
ENA, EK, EL = 50.0, -77.0, -54.4
C, PHI = 1.0, 1.0


def limdiv(num, den, limit):
    return limit if abs(den) < 1e-10 else num / den


def rates(V):
    an = limdiv(0.01 * (V + 55.0), 1.0 - math.exp(-(V + 55.0) / 10.0), 0.1)
    bn = 0.125 * math.exp(-(V + 65.0) / 80.0)
    am = limdiv(0.1 * (V + 40.0), 1.0 - math.exp(-(V + 40.0) / 10.0), 1.0)
    bm = 4.0 * math.exp(-(V + 65.0) / 18.0)
    ah = 0.07 * math.exp(-(V + 65.0) / 20.0)
    bh = 1.0 / (1.0 + math.exp(-(V + 35.0) / 10.0))
    return an, bn, am, bm, ah, bh


def gates(V):
    an, bn, am, bm, ah, bh = rates(V)
    def it(a, b):
        return a / (a + b), 1.0 / (a + b)
    n, tn = it(an, bn)
    m, tm = it(am, bm)
    h, th = it(ah, bh)
    return n, m, h, tn, tm, th


def F(V):
    n, m, h, *_ = gates(V)
    return GNA * m**3 * h * (V - ENA) + GK * n**4 * (V - EK) + GL * (V - EL)


def rest():
    a, b = -90.0, 40.0
    fa = F(a)
    for _ in range(70):
        mid = 0.5 * (a + b)
        fm = F(mid)
        if fa * fm <= 0:
            b = mid
        else:
            a, fa = mid, fm
    return 0.5 * (a + b)


def rhs(state, I):
    V, n, m, h = state
    an, bn, am, bm, ah, bh = rates(V)
    dV = (I - GNA * m**3 * h * (V - ENA) - GK * n**4 * (V - EK) - GL * (V - EL)) / C
    dn = PHI * (an * (1 - n) - bn * n)
    dm = PHI * (am * (1 - m) - bm * m)
    dh = PHI * (ah * (1 - h) - bh * h)
    return (dV, dn, dm, dh)


def rk4(state, I, dt):
    def add(a, b, s):
        return tuple(x + s * y for x, y in zip(a, b))
    k1 = rhs(state, I)
    k2 = rhs(add(state, k1, 0.5 * dt), I)
    k3 = rhs(add(state, k2, 0.5 * dt), I)
    k4 = rhs(add(state, k3, dt), I)
    return tuple(x + (dt / 6.0) * (a + 2 * b + 2 * c + d)
                 for x, a, b, c, d in zip(state, k1, k2, k3, k4))


def jacobian(V):
    n, m, h, tn, tm, th = gates(V)
    eps = 1e-5
    def dinf(idx):
        return (gates(V + eps)[idx] - gates(V - eps)[idx]) / (2 * eps)
    dIdV = GNA * m**3 * h + GK * n**4 + GL
    J = [[0.0] * 4 for _ in range(4)]
    J[0][0] = -dIdV / C
    J[0][1] = -(4 * GK * n**3 * (V - EK)) / C
    J[0][2] = -(3 * GNA * m**2 * h * (V - ENA)) / C
    J[0][3] = -(GNA * m**3 * (V - ENA)) / C
    for i, (idx, tau) in enumerate(((0, tn), (1, tm), (2, th)), start=1):
        J[i][0] = PHI * dinf(idx) / tau
        J[i][i] = -PHI / tau
    return J


def eigenvalues(J):
    n = 4
    A = [row[:] for row in J]
    M = [row[:] for row in A]
    coeffs = []
    for k in range(1, n + 1):
        tr = sum(M[i][i] for i in range(n))
        ck = tr / k
        coeffs.append(ck)
        B = [[M[i][j] - (ck if i == j else 0.0) for j in range(n)] for i in range(n)]
        M = [[sum(A[i][t] * B[t][j] for t in range(n)) for j in range(n)] for i in range(n)]
    c1, c2, c3, c4 = coeffs

    def p(z):
        return (((z - c1) * z - c2) * z - c3) * z - c4

    roots = [0.4 + 0.9j, -0.7 + 1.1j, -1.3 - 0.6j, 0.2 - 1.4j]
    for _ in range(60):
        new = []
        for i, r in enumerate(roots):
            den = 1 + 0j
            for j, o in enumerate(roots):
                if i != j:
                    den *= (r - o)
            new.append(r - p(r) / den)
        roots = new
    return roots


def coords(pairs):
    return " ".join("({:.3f},{:.3f})".format(x, y) for x, y in pairs)


def samples(vs, fn):
    return [(v, fn(v)) for v in vs]


# --- checks ---
vs = [-90 + i * 0.25 for i in range(521)]
fs = [F(v) for v in vs]
dips = sum(1 for i in range(1, len(fs)) if fs[i] < fs[i - 1] - 1e-7)
Vr = rest()
nr, mr, hr, tnr, tmr, thr = gates(Vr)
eigs = eigenvalues(jacobian(Vr))
print("monotonic_dips", dips)
print("rest", Vr, nr, mr, hr)
print("tau_rest", tnr, tmr, thr)
for z in eigs:
    print("eig", round(z.real, 6), round(z.imag, 6))

# steady curves, V in [-100, 40]
grid = [v for v in range(-100, 41, 5)]
curves = {name: [] for name in ("n", "m", "h", "tn", "tm", "th")}
for v in grid:
    n, m, h, tn, tm, th = gates(v)
    curves["n"].append((v, n))
    curves["m"].append((v, m))
    curves["h"].append((v, h))
    curves["tn"].append((v, tn))
    curves["tm"].append((v, tm))
    curves["th"].append((v, th))


def x_of(v):
    return (v + 100) * 5.6 / 140.0


def y_inf(y):
    return 0.15 + y * 2.5


def y_tau(y):
    return 0.15 + y * 2.5 / 9.0


# clamp at 0 from rest gates, closed form, 0 to 6 ms
ninf, minf, hinf, tn0, tm0, th0 = gates(0.0)
print("clamp0", ninf, minf, hinf, tn0, tm0, th0)
clamp_t = [i * 0.25 for i in range(25)]


def closed(x0, xinf, tau, t):
    return xinf + (x0 - xinf) * math.exp(-t / tau)


clamp = {
    "n": [(t, closed(nr, ninf, tn0, t)) for t in clamp_t],
    "m": [(t, closed(mr, minf, tm0, t)) for t in clamp_t],
    "h": [(t, closed(hr, hinf, th0, t)) for t in clamp_t],
}


def x_t(t, tspan, width):
    return t * width / tspan


def y01(y):
    return 0.15 + y * 2.55


# action potential: +10 mV from rest, I=0, to 12 ms
state = (Vr + 10.0, nr, mr, hr)
dt = 0.0025
t = 0.0
traj = []
peak = state[0]
tpeak = 0.0
cross = 0
prev = state[0]
while t <= 20.0 + 1e-12:
    if abs(t / 0.2 - round(t / 0.2)) < 1e-8 or t == 0.0:
        gna = GNA * state[2] ** 3 * state[3]
        gk = GK * state[1] ** 4
        traj.append((t, state[0], gna, gk))
    if state[0] > peak:
        peak, tpeak = state[0], t
    if prev < 0.0 <= state[0]:
        cross += 1
    prev = state[0]
    state = rk4(state, 0.0, dt)
    t += dt
print("spike_crossings", cross, "peak", peak, "tpeak", tpeak, "endV", state[0])
print("gmax", max(p[2] for p in traj), max(p[3] for p in traj))

# tikz
out = []
A = []
A.append(r"\begin{scope}")
A.append(r"  \draw[->] (0,0) -- (6.15,0) node[right] {$V$};")
A.append(r"  \draw[->] (0,0) -- (0,2.85) node[above] {$x_{\infty}$};")
for v, lab in ((-100, "-100"), (-50, "-50"), (0, "0"), (40, "40")):
    A.append(r"  \draw ({:.3f},0) -- ({:.3f},-0.05) node[below] {{${}$}};".format(x_of(v), x_of(v), lab))
for y, lab in ((0, "0"), (1, "1")):
    A.append(r"  \draw (0,{:.3f}) -- (-0.05,{:.3f}) node[left] {{${}$}};".format(y_inf(y), y_inf(y), lab))
style = {"n": "thick", "m": "thick,dashed", "h": "thick,dotted"}
for name in ("n", "m", "h"):
    pts = [(x_of(v), y_inf(y)) for v, y in curves[name]]
    A.append(r"  \draw[{}] plot coordinates {{{}}};".format(style[name], coords(pts)))
# labels where the curves separate: n near -20, m near -20 but higher, h near -80
def lab_inf(name, v, anchor, dx, dy):
    y = {"n": curves["n"], "m": curves["m"], "h": curves["h"]}[name]
    # nearest sample
    vv, yy = min(y, key=lambda p: abs(p[0] - v))
    A.append(r"  \node[{}] at ({:.3f},{:.3f}) {{${}$}};".format(
        anchor, x_of(vv) + dx, y_inf(yy) + dy, name))
lab_inf("h", -90, "anchor=south west", 0.08, 0.02)
lab_inf("n", -80, "anchor=north west", 0.06, -0.02)
lab_inf("m", -25, "anchor=south", 0.0, 0.08)
A.append(r"\end{scope}")

A.append(r"\begin{scope}[yshift=-4.05cm]")
A.append(r"  \draw[->] (0,0) -- (6.15,0) node[right] {$V$};")
A.append(r"  \draw[->] (0,0) -- (0,2.85) node[above] {$\tau$};")
for v, lab in ((-100, "-100"), (-50, "-50"), (0, "0"), (40, "40")):
    A.append(r"  \draw ({:.3f},0) -- ({:.3f},-0.05) node[below] {{${}$}};".format(x_of(v), x_of(v), lab))
for y, lab in ((0, "0"), (4, "4"), (8, "8")):
    A.append(r"  \draw (0,{:.3f}) -- (-0.05,{:.3f}) node[left] {{${}$}};".format(y_tau(y), y_tau(y), lab))
for name, sty in (("tn", "thick"), ("tm", "thick,dashed"), ("th", "thick,dotted")):
    pts = [(x_of(v), y_tau(y)) for v, y in curves[name]]
    A.append(r"  \draw[{}] plot coordinates {{{}}};".format(sty, coords(pts)))
# tau labels near peaks
for name, key, v, anch, dx, dy in (
    ("n", "tn", -75, "anchor=south", 0.15, 0.06),
    ("h", "th", -65, "anchor=north west", 0.12, -0.02),
    ("m", "tm", -20, "anchor=west", 0.08, 0.0),
):
    vv, yy = min(curves[key], key=lambda p: abs(p[0] - v))
    A.append(r"  \node[{}] at ({:.3f},{:.3f}) {{$\tau_{{{}}}$}};".format(
        anch, x_of(vv) + dx, y_tau(yy) + dy, name))
A.append(r"\end{scope}")

B = []
B.append(r"\draw[->] (0,0) -- (6.15,0) node[right] {$t$};")
B.append(r"\draw[->] (0,0) -- (0,2.9) node[above] {$x$};")
for t, lab in ((0, "0"), (2, "2"), (4, "4"), (6, "6")):
    B.append(r"\draw ({:.3f},0) -- ({:.3f},-0.05) node[below] {{${}$}};".format(
        x_t(t, 6, 5.7), x_t(t, 6, 5.7), lab))
for y, lab in ((0, "0"), (1, "1")):
    B.append(r"\draw (0,{:.3f}) -- (-0.05,{:.3f}) node[left] {{${}$}};".format(y01(y), y01(y), lab))
for name, sty in (("n", "thick"), ("m", "thick,dashed"), ("h", "thick,dotted")):
    pts = [(x_t(t, 6, 5.7), y01(y)) for t, y in clamp[name]]
    B.append(r"\draw[{}] plot coordinates {{{}}};".format(sty, coords(pts)))
# Interior gaps: n sits under the m plateau, m sits between the two rises, h sits above its tail.
B.append(r"\node[anchor=south] at (2.600,2.220) {$n$};")
B.append(r"\node[anchor=west] at (0.780,1.950) {$m$};")
B.append(r"\node[anchor=south] at (3.400,0.280) {$h$};")

C = []
# voltage panel
C.append(r"\begin{scope}[yshift=3.7cm]")
C.append(r"  \draw[->] (0,0) -- (6.15,0) node[right] {$t$};")
C.append(r"  \draw[->] (0,0) -- (0,2.85) node[above] {$V$};")
for t, lab in ((0, "0"), (10, "10"), (20, "20")):
    C.append(r"  \draw ({:.3f},0) -- ({:.3f},-0.05) node[below] {{${}$}};".format(
        x_t(t, 20, 5.7), x_t(t, 20, 5.7), lab))
for v, lab in ((-80, "-80"), (-40, "-40"), (0, "0"), (40, "40")):
    y = 0.15 + (v + 80) * 2.45 / 120.0
    C.append(r"  \draw (0,{:.3f}) -- (-0.05,{:.3f}) node[left] {{${}$}};".format(y, y, lab))
pts = [(x_t(t, 20, 5.7), 0.15 + (v + 80) * 2.45 / 120.0) for t, v, _, _ in traj]
C.append(r"  \draw[thick] plot coordinates {{{}}};".format(coords(pts)))
C.append(r"\end{scope}")
# conductance panel, scale 0 to 40
C.append(r"\begin{scope}")
C.append(r"  \draw[->] (0,0) -- (6.15,0) node[right] {$t$};")
C.append(r"  \draw[->] (0,0) -- (0,2.7) node[above] {$g$};")
for t, lab in ((0, "0"), (10, "10"), (20, "20")):
    C.append(r"  \draw ({:.3f},0) -- ({:.3f},-0.05) node[below] {{${}$}};".format(
        x_t(t, 20, 5.7), x_t(t, 20, 5.7), lab))
for g, lab in ((0, "0"), (20, "20"), (40, "40")):
    y = 0.12 + g * 2.3 / 40.0
    C.append(r"  \draw (0,{:.3f}) -- (-0.05,{:.3f}) node[left] {{${}$}};".format(y, y, lab))
gna = [(x_t(t, 20, 5.7), 0.12 + min(g, 40) * 2.3 / 40.0) for t, _, g, _ in traj]
gk = [(x_t(t, 20, 5.7), 0.12 + min(g, 40) * 2.3 / 40.0) for t, _, _, g in traj]
C.append(r"  \draw[thick] plot coordinates {{{}}};".format(coords(gna)))
C.append(r"  \draw[thick,dashed] plot coordinates {{{}}};".format(coords(gk)))
# labels at the peaks
ina = max(range(len(traj)), key=lambda i: traj[i][2])
ik = max(range(len(traj)), key=lambda i: traj[i][3])
C.append(r"  \node[anchor=south] at ({:.3f},{:.3f}) {{$g_{{\mathrm{{Na}}}}$}};".format(
    gna[ina][0], gna[ina][1] + 0.08))
C.append(r"  \node[anchor=south west] at ({:.3f},{:.3f}) {{$g_{{\mathrm{{K}}}}$}};".format(
    gk[ik][0] + 0.05, gk[ik][1] + 0.06))
C.append(r"\end{scope}")

FIGS = {
    "steady": ("fnip-0071.tree", "\n".join(A)),
    "clamp": ("fnip-0072.tree", "\n".join(B)),
    "spike": ("fnip-0073.tree", "\n".join(C)),
}
_PLOT = re.compile(r"plot coordinates \{([^{}]*)\}")


def _lists(text):
    return _PLOT.findall(text)


def _trees():
    if "--trees" in sys.argv:
        return Path(sys.argv[sys.argv.index("--trees") + 1])
    here = Path(__file__).resolve()
    candidate = here.parents[3] / "trees"
    if candidate.is_dir():
        return candidate
    raise SystemExit("pass --trees DIR")


def check_all():
    trees = _trees()
    failed = 0
    for name, (tree, body) in FIGS.items():
        got = _lists(body)
        pub = _lists((trees / tree).read_text())
        if got != pub:
            failed += 1
            print("FAIL", name, tree, "lists", len(got), len(pub))
        else:
            print("check", name, tree, "lists", len(got), "byte-identical")
    return failed


args = sys.argv[1:]
if "--check" in args:
    sys.exit(check_all())
if "--fig" in args:
    name = args[args.index("--fig") + 1]
    sys.stdout.write(FIGS[name][1] + "\n")
else:
    out = Path(__file__).resolve().parent / "out"
    out.mkdir(exist_ok=True)
    for name, (_, body) in FIGS.items():
        (out / ("fig-" + name + ".tex")).write_text(body + "\n")
    print("wrote figures", [name for name in FIGS])
