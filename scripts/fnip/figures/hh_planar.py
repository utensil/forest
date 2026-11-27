"""Planar Hodgkin-Huxley reduction checks.

Book lines stay in the notes: h = 0.89 - 1.1 n, n + h about 0.84,
the reduced Hopf values 6.8 and 267, and the full-model value about 154.
The prose does not print the decimals this script reports.

Run from the Forest worktree:
  python3 scripts/fnip/figures/hh_planar.py
"""
from pathlib import Path

src = Path(__file__).with_name("hh.py").read_text().split("# --- checks ---")[0]
ns = {}
exec(src, ns)


def need(name):
    return ns[name]


rest, gates, rk4 = need("rest"), need("gates"), need("rk4")
GNA, GK, GL = need("GNA"), need("GK"), need("GL")
ENA, EK, EL = need("ENA"), need("EK"), need("EL")


def orbit(I, t_end, dt=0.02, settle=0.0):
    V = rest()
    n, m, h, *_ = gates(V)
    state = (V + 30.0, n, m, h)
    samples = []
    t = 0.0
    while t < t_end:
        state = rk4(state, I, dt)
        t += dt
        if t >= settle:
            samples.append(state)
    return samples


def fit_h_on_n(samples):
    ns_ = [s[1] for s in samples]
    hs = [s[3] for s in samples]
    nbar = sum(ns_) / len(ns_)
    hbar = sum(hs) / len(hs)
    var = sum((n - nbar) ** 2 for n in ns_)
    cov = sum((n - nbar) * (h - hbar) for n, h in zip(ns_, hs))
    slope = cov / var
    return hbar - slope * nbar, slope


def fit_n_on_h(samples):
    ns_ = [s[1] for s in samples]
    hs = [s[3] for s in samples]
    nbar = sum(ns_) / len(ns_)
    hbar = sum(hs) / len(hs)
    var = sum((h - hbar) ** 2 for h in hs)
    cov = sum((n - nbar) * (h - hbar) for n, h in zip(ns_, hs))
    r = -cov / var
    return nbar + r * hbar, r


def reduced_roots(I):
    def f(V):
        n, m, h, *_ = gates(V)
        return I - GK * n**4 * (V - EK) - GNA * m**3 * (0.89 - 1.1 * n) * (V - ENA) - GL * (V - EL)

    roots = []
    x = -90.0
    prev = f(x)
    while x < 40.0:
        y = f(x + 0.5)
        if prev == 0 or prev * y < 0:
            lo, hi, flo = x, x + 0.5, prev
            for _ in range(40):
                mid = 0.5 * (lo + hi)
                fm = f(mid)
                if flo * fm <= 0:
                    hi = mid
                else:
                    lo, flo = mid, fm
            roots.append(0.5 * (lo + hi))
        prev = y
        x += 0.5
    return roots


def main():
    failed = 0

    def check(ok, msg):
        nonlocal failed
        print(("ok  " if ok else "FAIL") + " " + msg)
        if not ok:
            failed += 1

    for I, t_end, settle in ((8, 200, 80), (10, 200, 80), (100, 80, 30)):
        samples = orbit(I, t_end, settle=settle)
        sums = [s[1] + s[3] for s in samples]
        a, c = fit_h_on_n(samples)
        b, r = fit_n_on_h(samples)
        peak = max(s[0] for s in samples)
        print(
            f"I={I} Vpeak={peak:.2f} n+h=[{min(sums):.3f},{max(sums):.3f}] "
            f"mean={sum(sums)/len(sums):.3f} h={a:.3f}{c:+.3f}n b,r=({b:.3f},{r:.3f})"
        )
        if I == 8:
            check(min(sums) < 0.80 and max(sums) > 0.84, "I=8 n+h straddles the printed 0.84")
            check(0.83 < sum(sums) / len(sums) < 0.85, "I=8 mean near 0.84")
            check(0.87 < a < 0.90 and -1.11 < c < -1.07, "I=8 h-on-n near 0.884-1.092n")
        if I == 10:
            check(0.86 < a < 0.89 and -1.09 < c < -1.05, "I=10 h-on-n near 0.871-1.07n")
            check(0.79 < b < 0.83 and 0.90 < r < 0.95, "I=10 (b,r) near (0.808, 0.923)")
        if I == 100:
            check(-25 < peak < -10, "I=100 voltage peak near -20")
            check(0.72 < b < 0.77 and 1.14 < r < 1.20, "I=100 (b,r) near (0.741, 1.166)")

    for I, lo, hi in ((0, -65.3, -64.9), (8, -60.5, -59.9)):
        roots = reduced_roots(I)
        print(f"reduced I={I} roots={[round(v, 2) for v in roots]}")
        check(len(roots) == 1 and lo < roots[0] < hi, f"reduced I={I} one equilibrium")
    return failed


if __name__ == "__main__":
    raise SystemExit(main())
