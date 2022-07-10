v 20130925 2
C 40000 40000 0 0 0 title-B.sym
C 44500 48100 1 0 0 spice-model-1.sym
{
T 44600 48800 5 10 0 1 0 0 1
device=model
T 44600 48700 5 10 1 1 0 0 1
refdes=A1
T 45800 48400 5 10 1 1 0 0 1
model-name=2N2222
T 45000 48200 5 10 1 1 0 0 1
file=2N2222.LIB
}
C 47400 46700 1 0 0 npn-3.sym
{
T 48300 47200 5 10 0 0 0 0 1
device=NPN_TRANSISTOR
T 48300 47300 5 10 1 1 0 0 1
refdes=Q1
T 48300 47000 5 10 1 1 0 0 1
model-name=2N2222
}
C 49600 47700 1 270 0 voltage-3.sym
{
T 50300 47500 5 8 0 0 270 0 1
device=VOLTAGE_SOURCE
T 50100 47400 5 10 1 1 0 0 1
refdes=V1
T 50100 47100 5 10 1 1 0 0 1
value=10
}
C 47900 45300 1 0 0 gnd-1.sym
N 49800 47700 49800 49000 4
N 49800 46800 49800 45600 4
N 44500 45600 49800 45600 4
C 48100 48000 1 90 0 resistor-2.sym
{
T 47750 48400 5 10 0 0 90 0 1
device=RESISTOR
T 48500 48600 5 10 1 1 180 0 1
refdes=Rc
T 48600 48400 5 10 1 1 180 0 1
value=5.1k
}
C 44200 45800 1 0 0 vsin-1.sym
{
T 44900 46450 5 10 1 1 0 0 1
refdes=Vin
T 44900 46650 5 10 0 0 0 0 1
device=vsin
T 44900 46850 5 10 0 0 0 0 1
footprint=none
T 44900 46250 5 10 1 1 0 0 1
value=sin 0 50m 3k
}
C 44600 47100 1 0 0 resistor-2.sym
{
T 45000 47450 5 10 0 0 0 0 1
device=RESISTOR
T 44700 47400 5 10 1 1 0 0 1
refdes=Rin
T 45100 47400 5 10 1 1 0 0 1
value=10k
}
C 46600 47400 1 180 0 capacitor-2.sym
{
T 46400 46700 5 10 0 0 180 0 1
device=POLARIZED_CAPACITOR
T 45800 47400 5 10 1 1 0 0 1
refdes=C1
T 46400 46500 5 10 0 0 180 0 1
symversion=0.1
T 46300 47400 5 10 1 1 0 0 1
value=10u
}
N 45500 47200 45700 47200 4
N 46600 47200 47400 47200 4
N 44500 47000 44500 47200 4
N 44500 47200 44600 47200 4
N 44500 45800 44500 45600 4
C 47000 48000 1 90 0 resistor-2.sym
{
T 46650 48400 5 10 0 0 90 0 1
device=RESISTOR
T 47100 48500 5 10 1 1 0 0 1
refdes=Rb1
T 47100 48300 5 10 1 1 0 0 1
value=100k
}
N 46900 48000 46900 47200 4
N 46900 49000 49800 49000 4
N 46900 48900 46900 49000 4
N 48000 47700 48000 48000 4
{
T 48200 47800 5 10 1 1 0 0 1
netname=OUT
}
N 48000 49000 48000 48900 4
C 46800 46600 1 270 0 resistor-2.sym
{
T 47150 46200 5 10 0 0 270 0 1
device=RESISTOR
T 47100 46300 5 10 1 1 0 0 1
refdes=Rb2
T 47100 46000 5 10 1 1 0 0 1
value=22k
}
C 47900 46600 1 270 0 resistor-2.sym
{
T 48250 46200 5 10 0 0 270 0 1
device=RESISTOR
T 48200 46300 5 10 1 1 0 0 1
refdes=Re
T 48200 46000 5 10 1 1 0 0 1
value=1k
}
N 48000 46600 48000 46700 4
N 48000 45700 48000 45600 4
N 46900 46600 46900 47200 4
N 46900 45700 46900 45600 4
C 48700 46600 1 270 0 capacitor-2.sym
{
T 49400 46400 5 10 0 0 270 0 1
device=POLARIZED_CAPACITOR
T 49200 46300 5 10 1 1 0 0 1
refdes=Ce
T 49600 46400 5 10 0 0 270 0 1
symversion=0.1
T 49200 46000 5 10 1 1 0 0 1
value=10u
}
N 48900 46600 48000 46600 4
N 48900 45700 48900 45600 4
