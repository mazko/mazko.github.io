v 20130925 2
C 40000 40000 0 0 0 title-B.sym
C 42000 45200 1 0 0 spice-model-1.sym
{
T 42100 45900 5 10 0 1 0 0 1
device=model
T 42100 45800 5 10 1 1 0 0 1
refdes=A1
T 43300 45500 5 10 1 1 0 0 1
model-name=nMOSe
T 42500 45300 5 10 1 1 0 0 1
file=nMOSe.txt
}
C 44000 48000 1 90 0 voltage-3.sym
{
T 43300 48200 5 8 0 0 90 0 1
device=VOLTAGE_SOURCE
T 44800 48700 5 10 1 1 180 0 1
refdes=VnMOSe
T 44300 48400 5 10 1 1 180 0 1
value=10
}
C 43700 46500 1 0 0 gnd-1.sym
C 42200 48000 1 90 0 voltage-3.sym
{
T 41500 48200 5 8 0 0 90 0 1
device=VOLTAGE_SOURCE
T 42600 48700 5 10 1 1 180 0 1
refdes=Vin
T 42600 48400 5 10 1 1 180 0 1
value=DC
}
C 43300 47000 1 0 0 nmos-3.sym
{
T 43900 47500 5 10 0 0 0 0 1
device=NMOS_TRANSISTOR
T 44000 47600 5 10 1 1 0 0 1
refdes=M1
T 44000 47200 5 10 1 1 0 0 1
model-name=nMOSe
}
C 42100 49400 1 180 0 gnd-1.sym
C 43900 49400 1 180 0 gnd-1.sym
N 43800 46800 43800 47000 4
N 43800 48000 43800 47800 4
N 43800 49100 43800 48900 4
C 45600 47000 1 0 0 nmos-2.sym
{
T 46200 47500 5 10 0 0 0 0 1
device=NMOS_TRANSISTOR
T 46400 47600 5 10 1 1 0 0 1
refdes=M2
T 46400 47200 5 10 1 1 0 0 1
model-name=nMOSd
}
C 47700 47000 1 0 0 2N5245-1.sym
{
T 48550 47500 5 10 1 1 0 0 1
refdes=J1
T 48100 48350 5 10 0 0 0 0 1
footprint=TO92
T 48600 47100 5 10 1 1 0 0 1
value=nJFET
}
C 46000 46500 1 0 0 gnd-1.sym
C 48200 46400 1 0 0 gnd-1.sym
C 46200 49400 1 180 0 gnd-1.sym
C 48400 49400 1 180 0 gnd-1.sym
C 46300 48000 1 90 0 voltage-3.sym
{
T 45600 48200 5 8 0 0 90 0 1
device=VOLTAGE_SOURCE
T 47100 48700 5 10 1 1 180 0 1
refdes=VnMOSd
T 46600 48400 5 10 1 1 180 0 1
value=10
}
C 48500 48000 1 90 0 voltage-3.sym
{
T 47800 48200 5 8 0 0 90 0 1
device=VOLTAGE_SOURCE
T 49300 48700 5 10 1 1 180 0 1
refdes=VnJFET
T 48800 48400 5 10 1 1 180 0 1
value=10
}
N 46100 49100 46100 48900 4
N 48300 49100 48300 48900 4
N 46100 48000 46100 47800 4
N 48300 48000 48300 47800 4
N 46100 47000 46100 46800 4
N 48300 47000 48300 46700 4
N 42000 46300 47200 46300 4
N 42000 46300 42000 48000 4
N 42000 49100 42000 48900 4
N 43300 47200 42000 47200 4
C 44700 45200 1 0 0 spice-model-1.sym
{
T 44800 45900 5 10 0 1 0 0 1
device=model
T 44800 45800 5 10 1 1 0 0 1
refdes=A2
T 46000 45500 5 10 1 1 0 0 1
model-name=nMOSd
T 45200 45300 5 10 1 1 0 0 1
file=nMOSd.txt
}
C 47400 45200 1 0 0 spice-model-1.sym
{
T 47500 45900 5 10 0 1 0 0 1
device=model
T 47500 45800 5 10 1 1 0 0 1
refdes=A3
T 48700 45500 5 10 1 1 0 0 1
model-name=nJFET
T 47900 45300 5 10 1 1 0 0 1
file=nJFET.txt
}
N 45600 47400 45000 47400 4
N 45000 47400 45000 46300 4
N 47700 47400 47200 47400 4
N 47200 47400 47200 46300 4
N 46300 47400 46300 46900 4
N 46300 46900 46100 46900 4
