v 20130925 2
C 40000 40000 0 0 0 title-B.sym
C 49800 44700 1 0 0 spice-model-1.sym
{
T 49900 45400 5 10 0 1 0 0 1
device=model
T 49900 45300 5 10 1 1 0 0 1
refdes=A1
T 51100 45000 5 10 1 1 0 0 1
model-name=LT1007
T 50300 44800 5 10 1 1 0 0 1
file=LT1007CS.txt
}
C 48300 45500 1 90 0 voltage-3.sym
{
T 47600 45700 5 8 0 0 90 0 1
device=VOLTAGE_SOURCE
T 48300 46100 5 10 1 1 0 0 1
refdes=V2
T 48500 45800 5 10 1 1 180 0 1
value=15
}
C 48400 48100 1 0 0 voltage-3.sym
{
T 48600 48800 5 8 0 0 0 0 1
device=VOLTAGE_SOURCE
T 48600 48200 5 10 1 1 180 0 1
refdes=V1
T 49300 48200 5 10 1 1 180 0 1
value=15
}
C 51500 46300 1 0 0 gnd-1.sym
C 50100 46900 1 0 0 resistor-2.sym
{
T 50500 47250 5 10 0 0 0 0 1
device=RESISTOR
T 50300 47200 5 10 1 1 0 0 1
refdes=R
T 50600 47200 5 10 1 1 0 0 1
value=1k
}
N 48700 47000 50100 47000 4
{
T 49300 47200 5 10 1 1 0 0 1
netname=OUT
}
C 47600 46500 1 0 0 opamp-2.sym
{
T 48400 47500 5 10 0 0 0 0 1
device=OPAMP
T 47300 47500 5 10 1 1 0 0 1
refdes=U1
T 48400 47700 5 10 0 0 0 0 1
symversion=0.1
T 48400 46600 5 10 1 1 0 0 1
model-name=LT1007
}
C 43600 46300 1 270 0 voltage-3.sym
{
T 44300 46100 5 8 0 0 270 0 1
device=VOLTAGE_SOURCE
T 43300 46100 5 10 1 1 0 0 1
refdes=Vin1
T 43300 45500 5 10 1 1 0 0 1
value=DC
}
C 43700 45000 1 0 0 gnd-1.sym
C 47300 44400 1 90 0 resistor-2.sym
{
T 46950 44800 5 10 0 0 90 0 1
device=RESISTOR
T 47400 45000 5 10 1 1 0 0 1
refdes=Rf
T 47400 44700 5 10 1 1 0 0 1
value=10k
}
C 45900 46600 1 0 0 resistor-2.sym
{
T 46300 46950 5 10 0 0 0 0 1
device=RESISTOR
T 46000 46900 5 10 1 1 0 0 1
refdes=Rg1
T 46400 46900 5 10 1 1 0 0 1
value=10k
}
N 46800 46700 47600 46700 4
N 43800 45400 43800 45300 4
N 43800 46300 43800 46700 4
N 48400 48300 48100 48300 4
N 48100 48300 48100 47500 4
C 49400 47700 1 0 0 gnd-1.sym
N 49300 48300 49500 48300 4
N 49500 48300 49500 48000 4
N 48100 46500 48100 46400 4
C 48000 45100 1 0 0 gnd-1.sym
N 48100 45500 48100 45400 4
C 47100 46900 1 0 0 gnd-1.sym
N 51000 47000 51600 47000 4
N 51600 47000 51600 46600 4
N 47600 47300 47200 47300 4
N 47200 47300 47200 47200 4
N 47200 44400 47200 44300 4
N 47200 44300 49500 44300 4
N 49500 44300 49500 47000 4
N 47200 45300 47200 46700 4
N 45900 46700 43800 46700 4
C 44400 45700 1 270 0 voltage-3.sym
{
T 45100 45500 5 8 0 0 270 0 1
device=VOLTAGE_SOURCE
T 44100 45500 5 10 1 1 0 0 1
refdes=Vin2
T 44700 45500 5 10 1 1 0 0 1
value=3
}
C 44500 44400 1 0 0 gnd-1.sym
C 45900 46000 1 0 0 resistor-2.sym
{
T 46300 46350 5 10 0 0 0 0 1
device=RESISTOR
T 46000 46300 5 10 1 1 0 0 1
refdes=Rg2
T 46400 46300 5 10 1 1 0 0 1
value=10k
}
N 45900 46100 44600 46100 4
N 44600 46100 44600 45700 4
N 46800 46100 47200 46100 4
C 45600 44300 1 90 0 voltage-3.sym
{
T 44900 44500 5 8 0 0 90 0 1
device=VOLTAGE_SOURCE
T 44900 45000 5 10 1 1 0 0 1
refdes=Vin3
T 45500 45000 5 10 1 1 0 0 1
value=5
}
C 45900 45400 1 0 0 resistor-2.sym
{
T 46300 45750 5 10 0 0 0 0 1
device=RESISTOR
T 46000 45700 5 10 1 1 0 0 1
refdes=Rg3
T 46400 45700 5 10 1 1 0 0 1
value=10k
}
N 46800 45500 47200 45500 4
N 45900 45500 45400 45500 4
N 45400 45200 45400 47000 4
C 45300 43900 1 0 0 gnd-1.sym
N 44600 44700 44600 44800 4
N 45400 44200 45400 44300 4
C 44200 48100 1 0 0 resistor-2.sym
{
T 44600 48450 5 10 0 0 0 0 1
device=RESISTOR
T 44400 48400 5 10 1 1 0 0 1
refdes=Rx1
T 44800 48400 5 10 1 1 0 0 1
value=10k
}
C 44200 47500 1 0 0 resistor-2.sym
{
T 44600 47850 5 10 0 0 0 0 1
device=RESISTOR
T 44400 47800 5 10 1 1 0 0 1
refdes=Rx2
T 44800 47800 5 10 1 1 0 0 1
value=10k
}
C 44200 46900 1 0 0 resistor-2.sym
{
T 44600 47250 5 10 0 0 0 0 1
device=RESISTOR
T 44400 47200 5 10 1 1 0 0 1
refdes=Rx3
T 44800 47200 5 10 1 1 0 0 1
value=10k
}
N 45100 48200 45800 48200 4
N 45800 48200 45800 46700 4
N 45100 47600 45600 47600 4
N 45600 47600 45600 46100 4
N 45100 47000 45400 47000 4
C 43700 47200 1 90 0 resistor-2.sym
{
T 43350 47600 5 10 0 0 90 0 1
device=RESISTOR
T 43300 47900 5 10 1 1 180 0 1
refdes=Rx
T 42900 47500 5 10 1 1 0 0 1
value=1meg
}
C 43500 46800 1 0 0 gnd-1.sym
N 44200 48200 43600 48200 4
{
T 43400 48400 5 10 1 1 0 0 1
netname=TEST
}
N 43600 48200 43600 48100 4
N 44200 47600 44000 47600 4
N 44000 47000 44000 48200 4
N 44000 47000 44200 47000 4
N 43600 47200 43600 47100 4