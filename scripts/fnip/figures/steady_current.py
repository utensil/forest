"""Steady current for Hodgkin-Huxley and the Morris-Lecar SNLC column.

Book: Ermentrout and Terman, (3.3) and Table 3.1.
--fig hh (fnip-0078, upper drawing): Hodgkin-Huxley steady current F(V)
on [-90, 40] at step 1 mV, and the zoom on [-90, -50] at step 0.5 mV,
after a monotonicity scan at step 0.05 mV. Closed form. Parameters as in
hh.py: g_Na = 120, g_K = 36, g_L = 0.3, E_Na = 50, E_K = -77, E_L = -54.4.
--fig ml (fnip-0078, lower drawing): Morris-Lecar SNLC column,
phi = 0.067, g_Ca = 4, V3 = 12, V4 = 17.4, and the shared Table 3.1
reversal potentials. F(V) from V = -50 mV at step 0.5 mV while F <= 70,
after a fold scan on [-80, 80] at step 0.01 mV.

The prose does not print the decimals this script reports.
"""
import math
import re
import sys
from pathlib import Path

# Hodgkin-Huxley, modern voltages, C is not needed for F.
GNA, GK, GL = 120.0, 36.0, 0.3
ENA, EK, EL = 50.0, -77.0, -54.4


def limdiv(num, den, limit):
    return limit if abs(den) < 1e-10 else num / den


def hh_rates(V):
    an = limdiv(0.01 * (V + 55.0), 1.0 - math.exp(-(V + 55.0) / 10.0), 0.1)
    bn = 0.125 * math.exp(-(V + 65.0) / 80.0)
    am = limdiv(0.1 * (V + 40.0), 1.0 - math.exp(-(V + 40.0) / 10.0), 1.0)
    bm = 4.0 * math.exp(-(V + 65.0) / 18.0)
    ah = 0.07 * math.exp(-(V + 65.0) / 20.0)
    bh = 1.0 / (1.0 + math.exp(-(V + 35.0) / 10.0))
    return an, bn, am, bm, ah, bh


def hh_inf(V):
    an, bn, am, bm, ah, bh = hh_rates(V)
    n = an / (an + bn)
    m = am / (am + bm)
    h = ah / (ah + bh)
    return n, m, h


def hh_F(V):
    n, m, h = hh_inf(V)
    return GNA * m**3 * h * (V - ENA) + GK * n**4 * (V - EK) + GL * (V - EL)


def scan(F, a, b, step):
    vs = []
    v = a
    while v <= b + 1e-12:
        vs.append(v)
        v += step
    vals = [F(v) for v in vs]
    dips = 0
    for i in range(1, len(vals)):
        if vals[i] < vals[i - 1] - 1e-9:
            dips += 1
    # folds: sign changes of the forward difference
    folds = []
    prev = None
    for i in range(1, len(vals)):
        d = vals[i] - vals[i - 1]
        if prev is not None and prev * d < 0:
            folds.append(0.5 * (vs[i - 1] + vs[i - 2]))
        prev = d
    return vs, vals, dips, folds


def count_roots(vals, level):
    c = 0
    for i in range(1, len(vals)):
        y0, y1 = vals[i - 1] - level, vals[i] - level
        if y0 == 0 or y0 * y1 < 0:
            c += 1
    return c


vs, vals, dips, folds = scan(hh_F, -90.0, 40.0, 0.05)
print("hh dips", dips, "Fends", vals[0], vals[-1], "folds", folds)
print("hh roots at 0", count_roots(vals, 0.0))

# Morris-Lecar SNLC column, Table 3.1. Names stay off the Hodgkin-Huxley constants.
PHI = 0.067
GCA, V3, V4 = 4.0, 12.0, 17.4
ECA, ML_EK, ML_EL = 120.0, -84.0, -60.0
ML_GK, ML_GL = 8.0, 2.0
V1, V2, CM = -1.2, 18.0, 20.0


def minf(V):
    return 0.5 * (1.0 + math.tanh((V - V1) / V2))


def ninf(V):
    return 0.5 * (1.0 + math.tanh((V - V3) / V4))


def ml_F(V):
    return (
        ML_GL * (V - ML_EL)
        + ML_GK * ninf(V) * (V - ML_EK)
        + GCA * minf(V) * (V - ECA)
    )


mvs, mvals, mdips, mfolds = scan(ml_F, -80.0, 80.0, 0.01)
print("ml dips", mdips, "folds", mfolds)
for vf in mfolds:
    print(" fold", vf, "F", ml_F(vf), "n", ninf(vf))
if len(mfolds) >= 2:
    lo, hi = sorted(ml_F(v) for v in mfolds)
    print("between", lo, hi)
    for level in (lo - 5, 0.5 * (lo + hi), hi + 5):
        print(" roots", level, count_roots(mvals, level))


def emit(path, samples, x_of, y_of, draws):
    pts = " ".join("({:.3f},{:.3f})".format(x_of(v), y_of(F)) for v, F in samples)
    body = "\n".join(draws)
    body += "\n\\draw[thick] plot coordinates {" + pts + "};"
    open(path, "w").write(body + "\n")
    print("wrote", path, "pts", len(samples))


def samples(F, a, b, step, y_lo, y_hi):
    out = []
    v = a
    while v <= b + 1e-9:
        f = F(v)
        if f < y_lo or f > y_hi:
            break
        out.append((v, f))
        v += step
    return out


print("debug F-90", hh_F(-90.0), "F-50", hh_F(-50.0))
hh_full = samples(hh_F, -90.0, 40.0, 1.0, -1000.0, 4000.0)
hh_zoom = samples(hh_F, -90.0, -50.0, 0.5, -30.0, 80.0)
print("debug lens", len(hh_full), len(hh_zoom), hh_zoom[:2])

def xh(v):
    return (v + 100.0) * 5.6 / 140.0

def yh(f):
    return 0.15 + (f + 200.0) * 2.5 / 4200.0

def xz(v):
    return (v + 90.0) * 5.6 / 40.0

def yz(f):
    return 0.15 + (f + 20.0) * 2.5 / 90.0

lines = [
    r"\begin{scope}",
    r"  \draw[->] (0,0) -- (6.15,0) node[right] {$V$};",
    r"  \draw[->] (0,0) -- (0,2.9) node[above] {$F$};",
]
for v, lab in ((-100, "-100"), (-50, "-50"), (0, "0"), (40, "40")):
    lines.append(r"  \draw ({:.3f},0) -- ({:.3f},-0.05) node[below] {{${}$}};".format(xh(v), xh(v), lab))
for f, lab in ((0, "0"), (2000, "2000")):
    lines.append(r"  \draw (0,{:.3f}) -- (-0.05,{:.3f}) node[left] {{${}$}};".format(yh(f), yh(f), lab))
lines.append(r"  \draw[thin] (0,{:.3f}) -- (5.6,{:.3f});".format(yh(0), yh(0)))
pts = " ".join("({:.3f},{:.3f})".format(xh(v), yh(f)) for v, f in hh_full)
lines.append(r"  \draw[thick] plot coordinates {" + pts + "};")
lines.append(r"\end{scope}")
lines.append(r"\begin{scope}[yshift=-4.40cm]")
lines.append(r"  \draw[->] (0,0) -- (6.15,0) node[right] {$V$};")
lines.append(r"  \draw[->] (0,0) -- (0,2.9) node[above] {$F$};")
for v, lab in ((-90, "-90"), (-70, "-70"), (-50, "-50")):
    lines.append(r"  \draw ({:.3f},0) -- ({:.3f},-0.05) node[below] {{${}$}};".format(xz(v), xz(v), lab))
for f, lab in ((-10, "-10"), (0, "0"), (40, "40")):
    lines.append(r"  \draw (0,{:.3f}) -- (-0.05,{:.3f}) node[left] {{${}$}};".format(yz(f), yz(f), lab))
lines.append(r"  \draw[thin] (0,{:.3f}) -- (5.6,{:.3f});".format(yz(0), yz(0)))
pts = " ".join("({:.3f},{:.3f})".format(xz(v), yz(f)) for v, f in hh_zoom)
lines.append(r"  \draw[thick] plot coordinates {" + pts + "};")
lines.append(r"\end{scope}")
HH_BODY = "\n".join(lines)
print("fig-hh", len(hh_full), len(hh_zoom), "yz0", round(yz(0), 3), "yz ends", round(yz(hh_zoom[0][1]), 3), round(yz(hh_zoom[-1][1]), 3))

ml_win = []
v = -50.0
while v <= 15.0 + 1e-9:
    f = ml_F(v)
    if f > 70.0:
        break
    ml_win.append((v, f))
    v += 0.5
print("ml window", ml_win[0], ml_win[-1], "n", len(ml_win))

def xm(v):
    return (v + 50.0) * 5.6 / 60.0

def ym(f):
    return 0.15 + (f + 20.0) * 2.5 / 90.0

ml_lines = [
    r"\draw[->] (0,0) -- (6.15,0) node[right] {$V$};",
    r"\draw[->] (0,0) -- (0,2.9) node[above] {$F$};",
]
for v, lab in ((-40, "-40"), (-20, "-20"), (0, "0")):
    ml_lines.append(r"\draw ({:.3f},0) -- ({:.3f},-0.05) node[below] {{${}$}};".format(xm(v), xm(v), lab))
for f, lab in ((-20, "-20"), (0, "0"), (20, "20"), (40, "40"), (60, "60")):
    ml_lines.append(r"\draw (0,{:.3f}) -- (-0.05,{:.3f}) node[left] {{${}$}};".format(ym(f), ym(f), lab))
pts = " ".join("({:.3f},{:.3f})".format(xm(v), ym(f)) for v, f in ml_win)
ml_lines.append(r"\draw[thick] plot coordinates {" + pts + "};")
ML_BODY = "\n".join(ml_lines)
print("fig-ml", "ym fold region", round(ym(40), 3), round(ym(-10), 3))

FIGS = {"hh": HH_BODY, "ml": ML_BODY}
_PLOT = re.compile(r"plot coordinates \{([^{}]*)\}")


def _trees():
    if "--trees" in sys.argv:
        return Path(sys.argv[sys.argv.index("--trees") + 1])
    here = Path(__file__).resolve()
    candidate = here.parents[3] / "trees"
    if candidate.is_dir():
        return candidate
    raise SystemExit("pass --trees DIR")


def check_all():
    pub = _PLOT.findall((_trees() / "fnip-0078.tree").read_text())
    got = _PLOT.findall(HH_BODY) + _PLOT.findall(ML_BODY)
    if got != pub:
        print("FAIL fnip-0078 lists", len(got), len(pub))
        return 1
    print("check fnip-0078 lists", len(got), "byte-identical")
    return 0


args = sys.argv[1:]
if "--check" in args:
    sys.exit(check_all())
if "--fig" in args:
    name = args[args.index("--fig") + 1]
    sys.stdout.write(FIGS[name] + "\n")
else:
    out = Path(__file__).resolve().parent / "out"
    out.mkdir(exist_ok=True)
    for name, body in FIGS.items():
        (out / ("fig-" + name + ".tex")).write_text(body + "\n")
    print("wrote figures", list(FIGS))
