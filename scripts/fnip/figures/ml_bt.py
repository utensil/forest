"""Bogdanov–Takens nondegeneracy at the Morris–Lecar SNLC folds.

SNLC column: phi is the unknown, g_Ca=4, V3=12, V4=17.4, and the
shared constants E_Ca=120, E_K=-84, E_L=-60, g_K=8, g_L=2,
V1=-1.2, V2=18, C=20. At each fold of equilibria the determinant
is zero for every phi. The phi that makes the trace zero is the
candidate. The quadratic coefficients are read after the Jacobian
is put in the nilpotent block. The prose does not print these
decimals.
"""
import math

GCA, V3, V4 = 4.0, 12.0, 17.4
ECA, EK, EL = 120.0, -84.0, -60.0
GK, GL, V1, V2, C = 8.0, 2.0, -1.2, 18.0, 20.0


def minf(v):
    return 0.5 * (1 + math.tanh((v - V1) / V2))


def ninf(v):
    return 0.5 * (1 + math.tanh((v - V3) / V4))


def dminf(v):
    t = math.tanh((v - V1) / V2)
    return 0.5 * (1 - t * t) / V2


def dninf(v):
    t = math.tanh((v - V3) / V4)
    return 0.5 * (1 - t * t) / V4


def u_of(v):
    return (v - V3) / (2 * V4)


def cosh_u(v):
    return math.cosh(max(min(u_of(v), 20.0), -20.0))


def ionic(v, n):
    return GL * (v - EL) + GK * n * (v - EK) + GCA * minf(v) * (v - ECA)


def steady(v):
    return ionic(v, ninf(v))


def dst(v):
    eps = 1e-6
    return (steady(v + eps) - steady(v - eps)) / (2 * eps)


def folds():
    found = []
    prev_v, prev_d = -80.0, dst(-80.0)
    v = -79.9
    while v <= 40:
        d = dst(v)
        if prev_d * d < 0:
            lo, hi = prev_v, v
            for _ in range(60):
                mid = 0.5 * (lo + hi)
                if dst(lo) * dst(mid) <= 0:
                    hi = mid
                else:
                    lo = mid
            found.append(0.5 * (lo + hi))
        prev_v, prev_d = v, d
        v += 0.05
    found.sort()
    return found


def field(v, n, current, phi):
    return (
        (current - ionic(v, n)) / C,
        phi * (ninf(v) - n) * cosh_u(v),
    )


def hessian(v0, n0, current, phi):
    """Second directional derivatives, shape [component][i][j]."""
    h = 1e-4
    base = field(v0, n0, current, phi)
    out = [[[0.0, 0.0], [0.0, 0.0]] for _ in range(2)]
    shifts = ((h, 0.0), (0.0, h), (h, h))
    samples = {}
    for dv, dn in ((0, 0), (h, 0), (-h, 0), (0, h), (0, -h), (h, h), (-h, -h), (h, -h), (-h, h)):
        samples[(dv, dn)] = field(v0 + dv, n0 + dn, current, phi)
    # f_vv, f_nn, f_vn
    for comp in range(2):
        fvv = (samples[(h, 0)][comp] - 2 * samples[(0, 0)][comp] + samples[(-h, 0)][comp]) / h**2
        fnn = (samples[(0, h)][comp] - 2 * samples[(0, 0)][comp] + samples[(0, -h)][comp]) / h**2
        fvn = (
            samples[(h, h)][comp]
            - samples[(h, -h)][comp]
            - samples[(-h, h)][comp]
            + samples[(-h, -h)][comp]
        ) / (4 * h * h)
        out[comp][0][0] = fvv
        out[comp][1][1] = fnn
        out[comp][0][1] = out[comp][1][0] = fvn
    return out


def jacobian(v, n, phi):
    # At equilibrium. Analytic.
    u = u_of(v)
    ch = cosh_u(v)
    # d(ionic)/dV at fixed n
    dionic_v = GL + GK * n + GCA * (dminf(v) * (v - ECA) + minf(v))
    a = -dionic_v / C
    b = -GK * (v - EK) / C
    c = phi * dninf(v) * ch
    d = -phi * ch
    return a, b, c, d


def bt_coeffs(v):
    n = ninf(v)
    current = steady(v)
    a, b, c, d = jacobian(v, n, 1.0)
    # trace = a - phi*cosh, and d = -phi*cosh when phi=1 gives d_unit.
    # phi_star * |d at phi=1| cancels a.
    ch = cosh_u(v)
    phi = a / ch  # trace = a - phi*ch = 0
    if phi <= 0:
        raise SystemExit(f"nonpositive phi at V={v}")
    a, b, c, d = jacobian(v, n, phi)
    # J v1 = 0, J w = v1
    # rows (a,b), (c,d)
    # eigenvector: b v_n + a v_v = 0 if we use first row: a v + b n = 0
    if abs(b) > abs(a):
        vvec = (b, -a)
    else:
        vvec = (-d, c) if abs(c) + abs(d) > 0 else (1.0, 0.0)
    norm = math.hypot(*vvec) or 1.0
    vvec = (vvec[0] / norm, vvec[1] / norm)
    # Solve J w = vvec. J has rank 1. Use least squares with a gauge w·vvec=0.
    # J = [[a,b],[c,d]]
    # a w1 + b w2 = v1
    # c w1 + d w2 = v2
    # pick the row with larger norm
    if abs(a) + abs(b) >= abs(c) + abs(d):
        # particular solution
        if abs(b) >= abs(a):
            w = (0.0, vvec[0] / b)
        else:
            w = (vvec[0] / a, 0.0)
    else:
        if abs(d) >= abs(c):
            w = (0.0, vvec[1] / d)
        else:
            w = (vvec[1] / c, 0.0)
    # Remove component along vvec so the generalized eigenvector is transverse.
    dot = w[0] * vvec[0] + w[1] * vvec[1]
    w = (w[0] - dot * vvec[0], w[1] - dot * vvec[1])
    # P = [v w]; quadratic form of original field, then left-multiply by P^{-1}.
    detp = vvec[0] * w[1] - vvec[1] * w[0]
    if abs(detp) < 1e-12:
        raise SystemExit("degenerate frame")

    def pinv(z):
        # solve P u = z
        return (
            (z[0] * w[1] - z[1] * w[0]) / detp,
            (vvec[0] * z[1] - vvec[1] * z[0]) / detp,
        )

    H = hessian(v, n, current, phi)

    def quad(comp, x, y):
        # (1/2) of the bilinear polar? We stored pure second derivatives
        # of the Taylor f = (1/2) f_vv x^2 + f_vn x y + (1/2) f_nn y^2
        return 0.5 * H[comp][0][0] * x * x + H[comp][0][1] * x * y + 0.5 * H[comp][1][1] * y * y

    def q_state(x, y):
        return (quad(0, x, y), quad(1, x, y))

    # In coordinates u, state = P u, quadratic of u' is Pinv Q(Pu).
    # Monomials xi^2, xi eta, eta^2.
    def coeff(monomial):
        # monomial is (xi, eta) unit direction squared
        xi, eta = monomial
        state = (vvec[0] * xi + w[0] * eta, vvec[1] * xi + w[1] * eta)
        return pinv(q_state(*state))

    # a20 is the xi^2 coeff of the first new component? After reduction
    # x' = y + a20 x^2 + a11 x y + a02 y^2
    # y' = b20 x^2 + b11 x y + b02 y^2
    # Kuznetsov: b20 != 0 and a20 + b11 != 0.
    a20 = coeff((1.0, 0.0))[0]
    b20 = coeff((1.0, 0.0))[1]
    # mixed xi*eta: polarization
    both = coeff((1.0, 1.0))
    only_x = coeff((1.0, 0.0))
    only_y = coeff((0.0, 1.0))
    a11 = both[0] - only_x[0] - only_y[0]
    b11 = both[1] - only_x[1] - only_y[1]
    return {
        "V": v,
        "I": current,
        "phi": phi,
        "trace": a + d,
        "det": a * d - b * c,
        "Jnorm": math.hypot(a, b, c, d),
        "a20": a20,
        "b11": b11,
        "b20": b20,
        "sum": a20 + b11,
    }


def main():
    bad = False
    sn2, sn1 = folds()
    for name, v in (("SN2", sn2), ("SN1", sn1)):
        row = bt_coeffs(v)
        ok = abs(row["b20"]) > 1e-8 and abs(row["sum"]) > 1e-8 and abs(row["trace"]) < 1e-8 and abs(row["det"]) < 1e-8
        bad = bad or not ok
        print(
            name,
            f"V={row['V']:.6f}",
            f"I={row['I']:.6f}",
            f"phi={row['phi']:.6f}",
            f"trace={row['trace']:.3e}",
            f"det={row['det']:.3e}",
            f"b20={row['b20']:.6e}",
            f"a20+b11={row['sum']:.6e}",
            "nondegenerate" if ok else "DEGENERATE",
        )
    if bad:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
