v 20130925 2
C 40000 40000 0 0 0 title-B.sym
C 44800 47700 1 0 0 spice-model-1.sym
{
T 44900 48400 5 10 0 1 0 0 1
device=model
T 44900 48300 5 10 1 1 0 0 1
refdes=A1
T 46100 48000 5 10 1 1 0 0 1
model-name=LT1007
T 45300 47800 5 10 1 1 0 0 1
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
C 51100 46600 1 0 0 gnd-1.sym
C 50200 46900 1 0 0 resistor-2.sym
{
T 50600 47250 5 10 0 0 0 0 1
device=RESISTOR
T 50400 47200 5 10 1 1 0 0 1
refdes=R
T 50700 47200 5 10 1 1 0 0 1
value=1k
}
N 49000 47000 50200 47000 4
{
T 49400 47200 5 10 1 1 0 0 1
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
C 44700 44900 1 0 0 gnd-1.sym
N 47100 46700 47900 46700 4
N 48700 48500 48400 48500 4
N 48400 48500 48400 47500 4
C 49700 47900 1 0 0 gnd-1.sym
N 49600 48500 49800 48500 4
N 49800 48500 49800 48200 4
N 48400 46500 48400 46400 4
C 48300 45100 1 0 0 gnd-1.sym
N 48400 45500 48400 45400 4
C 47600 47000 1 0 0 gnd-1.sym
N 47700 47300 47900 47300 4
C 47100 46900 1 180 0 capacitor-1.sym
{
T 46900 46200 5 10 0 0 180 0 1
device=CAPACITOR
T 46200 46900 5 10 1 1 0 0 1
refdes=Cg
T 46900 46000 5 10 0 0 180 0 1
symversion=0.1
T 46800 46900 5 10 1 1 0 0 1
value=10n
}
C 49700 45300 1 90 0 resistor-2.sym
{
T 49350 45700 5 10 0 0 90 0 1
device=RESISTOR
T 50000 46000 5 10 1 1 180 0 1
refdes=Rf
T 49800 45500 5 10 1 1 0 0 1
value=100k
}
C 44500 45300 1 0 0 vpulse-1.sym
{
T 45200 45950 5 10 1 1 0 0 1
refdes=Vin
T 45200 46150 5 10 0 0 0 0 1
device=vpulse
T 45200 46350 5 10 0 0 0 0 1
footprint=none
T 45200 45550 5 10 1 1 0 0 1
value=pulse -3 3 0 0 0 25m 50m
}
N 44800 46500 44800 46700 4
N 44800 45300 44800 45200 4
N 49600 46200 49600 47000 4
N 47800 45000 47800 46700 4
N 49600 45300 49600 45000 4
N 51100 47000 51200 47000 4
N 51200 47000 51200 46900 4
N 47800 45000 50400 45000 4
C 45000 46600 1 0 0 resistor-2.sym
{
T 45400 46950 5 10 0 0 0 0 1
device=RESISTOR
T 45100 46900 5 10 1 1 0 0 1
refdes=Rg
T 45500 46900 5 10 1 1 0 0 1
value=1k
}
N 45000 46700 44800 46700 4
{
T 44600 46800 5 10 1 1 0 0 1
netname=IN
}
N 45900 46700 46200 46700 4
C 50200 46200 1 270 0 capacitor-1.sym
{
T 50900 46000 5 10 0 0 270 0 1
device=CAPACITOR
T 50600 45900 5 10 1 1 0 0 1
refdes=Cf
T 51100 46000 5 10 0 0 270 0 1
symversion=0.1
T 50600 45500 5 10 1 1 0 0 1
value=100p
}
N 50400 46200 50400 46500 4
N 50400 46500 49600 46500 4
N 50400 45300 50400 45000 4
