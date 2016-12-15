v 20130925 2
C 40000 40000 0 0 0 title-B.sym
C 45000 43400 1 0 0 spice-model-1.sym
{
T 45100 44100 5 10 0 1 0 0 1
device=model
T 45100 44000 5 10 1 1 0 0 1
refdes=A1
T 46300 43700 5 10 1 1 0 0 1
model-name=1N4107
T 45500 43500 5 10 1 1 0 0 1
file=1N4107.LIB
}
C 45600 45400 1 0 0 gnd-1.sym
C 44900 47100 1 270 0 voltage-3.sym
{
T 45600 46900 5 8 0 0 270 0 1
device=VOLTAGE_SOURCE
T 45400 46800 5 10 1 1 0 0 1
refdes=V1
T 45400 46500 5 10 1 1 0 0 1
value=42
}
C 48300 43400 1 0 0 spice-model-1.sym
{
T 48400 44100 5 10 0 1 0 0 1
device=model
T 48400 44000 5 10 1 1 0 0 1
refdes=A2
T 49600 43700 5 10 1 1 0 0 1
model-name=2N2222
T 48800 43500 5 10 1 1 0 0 1
file=2N2222.LIB
}
C 51600 43400 1 0 0 spice-model-1.sym
{
T 51700 44100 5 10 0 1 0 0 1
device=model
T 51700 44000 5 10 1 1 0 0 1
refdes=A3
T 52900 43700 5 10 1 1 0 0 1
model-name=Q2n5686
T 52100 43500 5 10 1 1 0 0 1
file=2N5686.LIB
}
C 45200 47600 1 0 0 resistor-2.sym
{
T 45600 47950 5 10 0 0 0 0 1
device=RESISTOR
T 45300 47900 5 10 1 1 0 0 1
refdes=R1
T 45600 47900 5 10 1 1 0 0 1
value=4.3k
}
N 45200 47700 45100 47700 4
N 45100 47700 45100 47100 4
N 46100 47700 47500 47700 4
{
T 47300 47800 5 10 1 1 0 0 1
netname=OUT_A
}
N 46300 47700 46300 47200 4
N 45100 46200 45100 45800 4
N 45100 45800 47500 45800 4
N 46300 45800 46300 46300 4
N 45700 45700 45700 45800 4
C 47400 47200 1 270 0 resistor-2.sym
{
T 47750 46800 5 10 0 0 270 0 1
device=RESISTOR
T 47700 46900 5 10 1 1 0 0 1
refdes=R3
T 47400 47200 5 10 0 1 0 0 1
value=1g
}
N 47500 47200 47500 47700 4
N 47500 46300 47500 45800 4
C 46500 46300 1 90 0 zener-1.sym
{
T 45900 46700 5 10 0 0 90 0 1
device=ZENER_DIODE
T 46800 46800 5 10 1 1 180 0 1
refdes=X1
T 46400 46300 5 10 1 1 0 0 1
model-name=1N4107
}
C 52100 47100 1 90 0 npn-3.sym
{
T 51600 48000 5 10 0 0 90 0 1
device=NPN_TRANSISTOR
T 51000 47900 5 10 1 1 0 0 1
refdes=Q1
T 52000 47900 5 10 1 1 0 0 1
value=Q2n5686
}
C 51400 46300 1 90 0 npn-3.sym
{
T 50900 47200 5 10 0 0 90 0 1
device=NPN_TRANSISTOR
T 50500 47200 5 10 1 1 180 0 1
refdes=Q2
T 51100 46300 5 10 1 1 0 0 1
value=2N2222
}
C 51100 45000 1 90 0 zener-1.sym
{
T 50500 45400 5 10 0 0 90 0 1
device=ZENER_DIODE
T 51400 45800 5 10 1 1 180 0 1
refdes=X2
T 51200 45300 5 10 1 1 0 0 1
value=1N4107
}
C 50600 46200 1 180 0 resistor-2.sym
{
T 50200 45850 5 10 0 0 180 0 1
device=RESISTOR
T 49700 46300 5 10 1 1 0 0 1
refdes=R4
T 50100 46300 5 10 1 1 0 0 1
value=4.3k
}
C 48500 47100 1 270 0 voltage-3.sym
{
T 49200 46900 5 8 0 0 270 0 1
device=VOLTAGE_SOURCE
T 49000 46700 5 10 1 1 0 0 1
refdes=V2
T 49000 46400 5 10 1 1 0 0 1
value=42
}
N 48700 47100 48700 47700 4
N 48700 47700 51100 47700 4
N 50400 46900 50100 46900 4
N 50100 46900 50100 47700 4
N 51400 46900 51600 46900 4
N 51600 46900 51600 47100 4
N 48700 46200 48700 46000 4
C 48600 45700 1 0 0 gnd-1.sym
N 50600 46100 50900 46100 4
N 50900 45900 50900 46300 4
C 50800 44600 1 0 0 gnd-1.sym
N 50900 45000 50900 44900 4
C 53100 46100 1 90 0 resistor-2.sym
{
T 52750 46500 5 10 0 0 90 0 1
device=RESISTOR
T 53500 46800 5 10 1 1 180 0 1
refdes=R5
T 53100 46100 5 10 0 1 0 0 1
value=1g
}
N 52100 47700 53000 47700 4
{
T 53100 47800 5 10 1 1 0 0 1
netname=OUT_B
}
N 53000 47700 53000 47000 4
C 52900 45700 1 0 0 gnd-1.sym
N 53000 46100 53000 46000 4
N 49700 46100 49500 46100 4
N 49500 46100 49500 47700 4