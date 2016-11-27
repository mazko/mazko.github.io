v 20130925 2
C 40000 40000 0 0 0 title-B.sym
C 45400 47700 1 0 0 spice-model-1.sym
{
T 45500 48400 5 10 0 1 0 0 1
device=model
T 45500 48300 5 10 1 1 0 0 1
refdes=A1
T 46700 48000 5 10 1 1 0 0 1
model-name=LT1007
T 45900 47800 5 10 1 1 0 0 1
file=LT1007CS.txt
}
C 48600 45500 1 90 0 voltage-3.sym
{
T 47900 45700 5 8 0 0 90 0 1
device=VOLTAGE_SOURCE
T 48600 46100 5 10 1 1 0 0 1
refdes=V2
T 48800 45800 5 10 1 1 180 0 1
value=15
}
C 48700 48300 1 0 0 voltage-3.sym
{
T 48900 49000 5 8 0 0 0 0 1
device=VOLTAGE_SOURCE
T 48900 48400 5 10 1 1 180 0 1
refdes=V1
T 49600 48400 5 10 1 1 180 0 1
value=15
}
C 51800 46300 1 0 0 gnd-1.sym
C 50500 46900 1 0 0 resistor-2.sym
{
T 50900 47250 5 10 0 0 0 0 1
device=RESISTOR
T 50700 47200 5 10 1 1 0 0 1
refdes=R
T 51000 47200 5 10 1 1 0 0 1
value=1k
}
N 49000 47000 50500 47000 4
{
T 49600 47200 5 10 1 1 0 0 1
netname=OUT
}
C 47900 46500 1 0 0 opamp-2.sym
{
T 48700 47500 5 10 0 0 0 0 1
device=OPAMP
T 47600 47500 5 10 1 1 0 0 1
refdes=U1
T 48700 47700 5 10 0 0 0 0 1
symversion=0.1
T 48700 46600 5 10 1 1 0 0 1
model-name=LT1007
}
C 45200 46300 1 270 0 voltage-3.sym
{
T 45900 46100 5 8 0 0 270 0 1
device=VOLTAGE_SOURCE
T 45000 46100 5 10 1 1 0 0 1
refdes=Vin
T 45000 45500 5 10 1 1 0 0 1
value=DC
}
C 45300 44900 1 0 0 gnd-1.sym
C 47300 45400 1 90 0 resistor-2.sym
{
T 46950 45800 5 10 0 0 90 0 1
device=RESISTOR
T 47400 46000 5 10 1 1 0 0 1
refdes=Rf
T 47400 45700 5 10 1 1 0 0 1
value=365k
}
C 45900 46600 1 0 0 resistor-2.sym
{
T 46300 46950 5 10 0 0 0 0 1
device=RESISTOR
T 46000 46900 5 10 1 1 0 0 1
refdes=Rg
T 46400 46900 5 10 1 1 0 0 1
value=365
}
N 46800 46700 47900 46700 4
N 45400 45400 45400 45200 4
N 45400 46300 45400 46700 4
N 48700 48500 48400 48500 4
N 48400 48500 48400 47500 4
C 49700 47900 1 0 0 gnd-1.sym
N 49600 48500 49800 48500 4
N 49800 48500 49800 48200 4
N 48400 46500 48400 46400 4
C 48300 45100 1 0 0 gnd-1.sym
N 48400 45500 48400 45400 4
C 47100 46900 1 0 0 gnd-1.sym
N 51400 47000 51900 47000 4
N 51900 47000 51900 46600 4
N 47900 47300 47200 47300 4
N 47200 47300 47200 47200 4
N 47200 45400 47200 44800 4
N 47200 44800 49800 44800 4
N 49800 44800 49800 47000 4
N 47200 46300 47200 46700 4
N 45900 46700 45400 46700 4