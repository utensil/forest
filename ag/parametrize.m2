-- m2 --script ag/parametrize.m2

-- installPackage("AdjointIdeal")
-- installPackage("Parametrization")

-- needsPackage "Parametrization"

-- needsPackage "Cremona"
needsPackage "MultiprojectiveVarieties"

K=RR;

R=K[x,y];

I=ideal(x^2-4, y^2-1);

-- p=parametrize(I)

V = projectiveVariety I

p = parametrize V
