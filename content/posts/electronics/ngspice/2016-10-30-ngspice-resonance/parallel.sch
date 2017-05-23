v 20130925 2
C 40000 40000 0 0 0 title-B.sym
C 48100 46600 1 270 0 capacitor-1.sym
{
T 48800 46400 5 10 0 0 270 0 1
device=CAPACITOR
T 48500 46300 5 10 1 1 0 0 1
refdes=C1
T 49000 46400 5 10 0 0 270 0 1
symversion=0.1
T 48500 45900 5 10 1 1 0 0 1
value=42uF
}
N 44500 46700 44500 47200 4
N 44500 45100 44500 45800 4
N 44500 45100 47600 45100 4
C 46100 44800 1 0 0 gnd-1.sym
C 47000 45700 1 90 0 inductor-1.sym
{
T 46500 45900 5 10 0 0 90 0 1
device=INDUCTOR
T 47200 46300 5 10 1 1 180 0 1
refdes=L1
T 46300 45900 5 10 0 0 90 0 1
symversion=0.1
T 47700 46300 5 10 1 1 180 0 1
value=42uH
}
N 46000 45400 48300 45400 4
N 48300 45400 48300 45700 4
N 47600 45100 47600 45400 4
N 47600 46900 47600 47200 4
N 46900 46600 46900 46900 4
N 46000 46900 48300 46900 4
{
T 46000 47000 5 10 1 1 0 0 1
netname=n1
}
N 48300 46900 48300 46600 4
N 46900 45700 46900 45400 4
N 44500 47200 47600 47200 4
C 44300 46700 1 270 0 current-1.sym
{
T 45300 46100 5 10 0 0 270 0 1
device=CURRENT_SOURCE
T 44800 46300 5 10 1 1 0 0 1
refdes=I1
T 44800 46000 5 10 1 1 0 0 1
value=AC
}
C 46100 45700 1 90 0 resistor-2.sym
{
T 45750 46100 5 10 0 0 90 0 1
device=RESISTOR
T 46400 46200 5 10 1 1 180 0 1
refdes=R1
T 46400 45900 5 10 1 1 180 0 1
value=1k
}
N 46000 46600 46000 46900 4
N 46000 45700 46000 45400 4