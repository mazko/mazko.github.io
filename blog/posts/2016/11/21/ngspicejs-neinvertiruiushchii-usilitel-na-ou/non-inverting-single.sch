v 20130925 2
C 40000 40000 0 0 0 title-B.sym
C 46200 43800 1 0 0 spice-model-1.sym
{
T 46300 44500 5 10 0 1 0 0 1
device=model
T 46300 44400 5 10 1 1 0 0 1
refdes=A1
T 47500 44100 5 10 1 1 0 0 1
model-name=LT1007
T 46700 43900 5 10 1 1 0 0 1
file=LT1007CS.txt
}
C 48700 48300 1 0 0 voltage-3.sym
{
T 48900 49000 5 8 0 0 0 0 1
device=VOLTAGE_SOURCE
T 48900 48400 5 10 1 1 180 0 1
refdes=V1
T 49600 48400 5 10 1 1 180 0 1
value=30
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
C 44700 45400 1 0 0 gnd-1.sym
C 49900 45900 1 90 0 resistor-2.sym
{
T 49550 46300 5 10 0 0 90 0 1
device=RESISTOR
T 50000 46500 5 10 1 1 0 0 1
refdes=Rf
T 50000 46200 5 10 1 1 0 0 1
value=100k
}
C 49700 45700 1 270 0 resistor-2.sym
{
T 50050 45300 5 10 0 0 270 0 1
device=RESISTOR
T 50000 45400 5 10 1 1 0 0 1
refdes=Rg
T 50000 45100 5 10 1 1 0 0 1
value=50k
}
N 49800 46800 49800 47000 4
N 47600 45800 47600 46700 4
N 47600 46700 47900 46700 4
N 44800 47100 44800 47300 4
N 46700 48500 48700 48500 4
N 48400 48500 48400 47500 4
C 49700 47900 1 0 0 gnd-1.sym
N 49600 48500 49800 48500 4
N 49800 48500 49800 48200 4
C 48300 46100 1 0 0 gnd-1.sym
N 49800 45900 49800 45700 4
N 47600 45800 49800 45800 4
C 49700 43400 1 0 0 gnd-1.sym
N 51400 47000 51900 47000 4
N 51900 47000 51900 46600 4
N 48400 46400 48400 46500 4
C 46600 48400 1 270 0 resistor-2.sym
{
T 46950 48000 5 10 0 0 270 0 1
device=RESISTOR
T 46900 48000 5 10 1 1 0 0 1
refdes=Rb1
T 46900 47700 5 10 1 1 0 0 1
value=100k
}
C 46600 47100 1 270 0 resistor-2.sym
{
T 46950 46700 5 10 0 0 270 0 1
device=RESISTOR
T 46900 46700 5 10 1 1 0 0 1
refdes=Rb2
T 46900 46400 5 10 1 1 0 0 1
value=100k
}
N 46700 48400 46700 48500 4
C 46600 45400 1 0 0 gnd-1.sym
N 46700 46200 46700 45700 4
N 46700 47100 46700 47500 4
C 45300 47100 1 0 0 capacitor-1.sym
{
T 45500 47800 5 10 0 0 0 0 1
device=CAPACITOR
T 45300 47500 5 10 1 1 0 0 1
refdes=C1
T 45500 48000 5 10 0 0 0 0 1
symversion=0.1
T 45900 47500 5 10 1 1 0 0 1
value=1u
}
N 46200 47300 46700 47300 4
N 47900 47300 46700 47300 4
{
T 47100 47400 5 10 1 1 0 0 1
netname=IN
}
N 44800 47300 45300 47300 4
C 44500 45900 1 0 0 vsin-1.sym
{
T 45200 46650 5 10 1 1 0 0 1
refdes=Vin
T 45200 46750 5 10 0 0 0 0 1
device=vsin
T 45200 46950 5 10 0 0 0 0 1
footprint=none
T 45200 46350 5 10 1 1 0 0 1
value=sin 0 1 10k
}
N 44800 45900 44800 45700 4
C 49600 44700 1 270 0 capacitor-1.sym
{
T 50300 44500 5 10 0 0 270 0 1
device=CAPACITOR
T 50000 44400 5 10 1 1 0 0 1
refdes=C2
T 50500 44500 5 10 0 0 270 0 1
symversion=0.1
T 50200 44100 5 10 1 1 180 0 1
value=1u
}
N 49800 44800 49800 44700 4
N 49800 43800 49800 43700 4