v 20130925 2
C 40000 40000 0 0 0 title-B.sym
C 43600 46200 1 0 0 spice-model-1.sym
{
T 43700 46900 5 10 0 1 0 0 1
device=model
T 43700 46800 5 10 1 1 0 0 1
refdes=A1
T 44900 46500 5 10 1 1 0 0 1
model-name=TLC555
T 44100 46300 5 10 1 1 0 0 1
file=tlc555.mod
}
C 49500 45400 1 0 0 gnd-1.sym
C 45400 43800 1 0 0 lm555-1.sym
{
T 47700 46200 5 10 0 0 0 0 1
device=LM555
T 47200 43800 5 10 1 1 0 0 1
refdes=U1
T 45700 43600 5 10 0 1 0 0 1
model-name=TLC555
}
C 49400 46700 1 270 0 voltage-3.sym
{
T 50100 46500 5 8 0 0 270 0 1
device=VOLTAGE_SOURCE
T 49900 46400 5 10 1 1 0 0 1
refdes=V1
T 49900 46100 5 10 1 1 0 0 1
value=3
}
N 49600 46700 49600 46800 4
N 47000 46700 47000 46600 4
N 46200 46600 46200 46800 4
C 44200 43700 1 0 0 gnd-1.sym
C 47300 46600 1 0 0 resistor-2.sym
{
T 47700 46950 5 10 0 0 0 0 1
device=RESISTOR
T 47400 46900 5 10 1 1 0 0 1
refdes=R1
T 47800 46900 5 10 1 1 0 0 1
value=3meg
}
C 48800 43800 1 0 0 gnd-1.sym
C 47900 44100 1 0 0 resistor-2.sym
{
T 48300 44450 5 10 0 0 0 0 1
device=RESISTOR
T 48100 44400 5 10 1 1 0 0 1
refdes=R
T 48400 44400 5 10 1 1 0 0 1
value=1k
}
N 49600 45700 49600 45800 4
N 47700 45300 48300 45300 4
{
T 48000 45400 5 10 0 1 0 0 1
netname=R
}
N 47800 43800 47800 44200 4
{
T 48000 43700 5 10 1 1 0 0 1
netname=OUT
}
N 47700 44200 47900 44200 4
C 46000 46800 1 0 0 vcc-1.sym
C 49400 46800 1 0 0 vcc-1.sym
N 43400 44000 44900 44000 4
N 45400 44200 44900 44200 4
N 44900 44200 44900 44000 4
N 43400 45500 45400 45500 4
{
T 43400 45600 5 10 1 1 0 0 1
netname=IN
}
N 45400 45300 45400 45500 4
N 43400 45500 43400 45300 4
C 43100 44100 1 0 0 vpulse-1.sym
{
T 43800 44750 5 10 1 1 0 0 1
refdes=Vin
T 43800 44950 5 10 0 0 0 0 1
device=vpulse
T 43800 45150 5 10 0 0 0 0 1
footprint=none
T 43800 44550 5 10 1 1 0 0 1
value=pulse 3 0 1 0 0 0.1 5
}
N 43400 44100 43400 44000 4
C 47800 44700 1 0 0 capacitor-1.sym
{
T 48000 45400 5 10 0 0 0 0 1
device=CAPACITOR
T 47900 45000 5 10 1 1 0 0 1
refdes=C2
T 48000 45600 5 10 0 0 0 0 1
symversion=0.1
T 48400 45000 5 10 1 1 0 0 1
value=10p
}
N 48800 44200 48900 44200 4
N 48900 44100 48900 45400 4
N 48700 44900 48900 44900 4
N 47800 44900 47700 44900 4
N 46200 46700 47300 46700 4
N 48200 46700 48900 46700 4
N 48300 45300 48300 46700 4
N 48300 45700 47700 45700 4
C 48700 46300 1 270 0 capacitor-1.sym
{
T 49400 46100 5 10 0 0 270 0 1
device=CAPACITOR
T 48600 46000 5 10 1 1 0 0 1
refdes=C1
T 49600 46100 5 10 0 0 270 0 1
symversion=0.1
T 49000 46000 5 10 1 1 0 0 1
value=1u
}
N 48900 46300 48900 46700 4