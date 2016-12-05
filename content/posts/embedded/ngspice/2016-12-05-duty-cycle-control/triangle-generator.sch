v 20130925 2
C 40000 40000 0 0 0 title-B.sym
C 48400 44300 1 0 0 spice-model-1.sym
{
T 48500 45000 5 10 0 1 0 0 1
device=model
T 48500 44900 5 10 1 1 0 0 1
refdes=A1
T 49700 44600 5 10 1 1 0 0 1
model-name=LT1007
T 48900 44400 5 10 1 1 0 0 1
file=LT1007CS.txt
}
C 52000 45800 1 270 0 voltage-3.sym
{
T 52700 45600 5 8 0 0 270 0 1
device=VOLTAGE_SOURCE
T 52600 45700 5 10 1 1 180 0 1
refdes=V1
T 52600 45200 5 10 1 1 180 0 1
value=10
}
C 47900 46000 1 0 0 opamp-2.sym
{
T 48700 47000 5 10 0 0 0 0 1
device=OPAMP
T 47600 46500 5 10 1 1 0 0 1
refdes=U1
T 48700 47200 5 10 0 0 0 0 1
symversion=0.1
T 48700 46100 5 10 1 1 0 0 1
model-name=LT1007
}
C 52100 44500 1 0 0 gnd-1.sym
C 48300 45600 1 0 0 gnd-1.sym
N 48400 45900 48400 46000 4
C 45800 46300 1 90 0 resistor-2.sym
{
T 45450 46700 5 10 0 0 90 0 1
device=RESISTOR
T 45900 46800 5 10 1 1 0 0 1
refdes=R1
T 45900 46500 5 10 1 1 0 0 1
value=1k
}
C 45800 45000 1 90 0 resistor-2.sym
{
T 45450 45400 5 10 0 0 90 0 1
device=RESISTOR
T 45900 45600 5 10 1 1 0 0 1
refdes=R2
T 46100 45400 5 10 1 1 180 0 1
value=1k
}
N 45700 45900 45700 46300 4
N 48400 47000 48400 48900 4
C 46300 47000 1 0 0 resistor-2.sym
{
T 46700 47350 5 10 0 0 0 0 1
device=RESISTOR
T 46500 47300 5 10 1 1 0 0 1
refdes=R3
T 46800 47300 5 10 1 1 0 0 1
value=47k
}
C 49500 47000 1 90 0 resistor-2.sym
{
T 49150 47400 5 10 0 0 90 0 1
device=RESISTOR
T 49200 47700 5 10 1 1 180 0 1
refdes=R4
T 48800 47300 5 10 1 1 0 0 1
value=100k
}
N 49400 47900 49400 48000 4
N 49400 48000 47400 48000 4
N 47400 48000 47400 46800 4
N 47400 46800 47900 46800 4
N 47200 47100 47400 47100 4
N 47900 46200 45700 46200 4
C 51700 47000 1 180 1 opamp-2.sym
{
T 52500 46000 5 10 0 0 180 6 1
device=OPAMP
T 51500 46500 5 10 1 1 180 6 1
refdes=U2
T 52500 45800 5 10 0 0 180 6 1
symversion=0.1
T 52600 46200 5 10 1 1 180 6 1
model-name=LT1007
}
N 49400 47000 49400 46500 4
N 49400 46500 49000 46500 4
N 49500 46200 49500 45500 4
N 47100 45500 49500 45500 4
N 47100 45500 47100 46200 4
C 49700 46700 1 0 0 resistor-2.sym
{
T 50100 47050 5 10 0 0 0 0 1
device=RESISTOR
T 49800 47000 5 10 1 1 0 0 1
refdes=R5
T 50100 47000 5 10 1 1 0 0 1
value=100k
}
N 49700 46800 49400 46800 4
C 51400 47100 1 90 0 capacitor-1.sym
{
T 50700 47300 5 10 0 0 90 0 1
device=CAPACITOR
T 50800 47700 5 10 1 1 0 0 1
refdes=C1
T 50500 47300 5 10 0 0 90 0 1
symversion=0.1
T 51400 47700 5 10 1 1 0 0 1
value=10n
}
N 46200 48600 53300 48600 4
N 46200 48600 46200 47100 4
C 52700 46900 1 0 0 gnd-1.sym
N 45700 47200 45700 48900 4
N 45700 48900 53600 48900 4
C 45600 44500 1 0 0 gnd-1.sym
N 45700 45000 45700 44800 4
N 46300 47100 46200 47100 4
N 51200 47100 51200 46800 4
N 51200 48000 51200 48600 4
N 51700 46800 50600 46800 4
N 52200 47000 52200 47300 4
N 52200 47300 52800 47300 4
N 52800 47300 52800 47200 4
N 49500 46200 51700 46200 4
N 52800 46500 53300 46500 4
N 53300 46500 53300 48600 4
{
T 52700 48300 5 10 1 1 0 0 1
netname=OUT
}
N 53600 48900 53600 45900 4
N 53600 45900 52200 45900 4
N 52200 45800 52200 46000 4
N 52200 44900 52200 44800 4
