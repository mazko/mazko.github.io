v 20130925 2
C 40000 40000 0 0 0 title-B.sym
C 46200 46300 1 0 0 gnd-1.sym
C 47800 48100 1 270 0 diode-1.sym
{
T 48400 47700 5 10 0 0 270 0 1
device=DIODE
T 48300 47700 5 10 1 1 0 0 1
refdes=D1
T 48200 47500 5 10 1 1 0 0 1
model-name=d1n4007
}
N 44600 48100 44600 48700 4
{
T 47900 48800 5 10 1 1 0 0 1
netname=n1
}
N 44600 48700 48000 48700 4
N 44600 46600 48000 46600 4
N 44600 47200 44600 46600 4
C 45400 47200 1 0 0 spice-model-1.sym
{
T 45500 47900 5 10 0 1 0 0 1
device=model
T 45500 47800 5 10 1 1 0 0 1
refdes=A1
T 46700 47500 5 10 1 1 0 0 1
model-name=d1n4007
T 45900 47300 5 10 1 1 0 0 1
file=1n4007.txt
}
N 48000 47200 48000 46600 4
N 48000 48100 48000 48700 4
C 44800 47200 1 90 0 current-1.sym
{
T 43800 47800 5 10 0 0 90 0 1
device=CURRENT_SOURCE
T 45000 47900 5 10 1 1 180 0 1
refdes=I1
T 44800 47200 5 10 0 2 0 0 1
value=1
}