-- brew install Macaulay2/tap/M2
-- m2 --script ag/hello.m2 > output/hello.svg
-- example from https://www.unimelb-macaulay2.cloud.edu.au/#editor

needsPackage "VectorGraphics"

R=RR[x,y]; P=y^2-(x+1)*(x-1)*(x-2);

fig=plot2d(P,{-2,3},"stroke-width"=>0.05,Size=>35,"stroke"=>"red",Axes=>true)

print(html(fig))