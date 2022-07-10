v 20130925 2
C 40000 40000 0 0 0 title-B.sym
C 46400 48000 1 0 0 gnd-1.sym
C 46300 49300 1 270 0 voltage-3.sym
{
T 47000 49100 5 8 0 0 270 0 1
device=VOLTAGE_SOURCE
T 46800 49100 5 10 1 1 0 0 1
refdes=V1
T 47000 48700 5 10 1 1 180 0 1
value=3
}
C 46300 49400 1 0 0 vcc-1.sym
C 43200 48000 1 0 0 gnd-1.sym
C 44800 48000 1 0 0 gnd-1.sym
C 51200 48000 1 0 0 spice-model-1.sym
{
T 51300 48700 5 10 0 1 0 0 1
device=model
T 51300 48600 5 10 1 1 0 0 1
refdes=A2
T 52500 48300 5 10 1 1 0 0 1
model-name=NAND
T 51700 48100 5 10 1 1 0 0 1
file=nand.lib
}
N 52700 46900 53200 46900 4
{
T 53200 47000 5 10 1 1 0 0 1
netname=Q
}
N 52700 44900 53200 44900 4
{
T 53200 45000 5 10 1 1 0 0 1
netname=nQ
}
N 50700 46700 51400 46700 4
N 50900 45100 51400 45100 4
N 52800 46900 52800 46000 4
N 52800 46000 50900 46000 4
N 50900 46000 50900 45100 4
N 52800 44900 52800 45800 4
N 52800 45800 50700 45800 4
N 50700 45800 50700 46700 4
C 43000 48400 1 0 0 vpwl-1.sym
{
T 43500 48450 5 10 1 1 0 0 1
refdes=V2
T 43700 49250 5 10 0 0 0 0 1
device=vpwl
T 43700 49450 5 10 0 0 0 0 1
footprint=none
T 43700 48850 5 10 0 1 0 0 1
value=pwl 3 0 {3+1p} 3 6 3 {6+1p} 0 8 0 {8+1p} 3
}
C 44600 48400 1 0 0 vpwl-1.sym
{
T 45100 48450 5 10 1 1 0 0 1
refdes=V3
T 45300 49250 5 10 0 0 0 0 1
device=vpwl
T 45300 49450 5 10 0 0 0 0 1
footprint=none
T 45300 48450 5 10 0 1 0 0 1
value=pwl 1 0 {1+1p} 3 2 3 {2+1p} 0 4 0 {4+1p} 3 5 3 {5+1p} 0 7 0 {7+1p} 3 9 3 {9+1p} 0
}
N 43300 49600 43300 49700 4
{
T 43500 49500 5 10 1 1 0 0 1
netname=Data
}
N 44900 49600 44900 49700 4
{
T 45100 49500 5 10 1 1 0 0 1
netname=Clock
}
N 43300 48400 43300 48300 4
N 44900 48300 44900 48400 4
N 46500 49400 46500 49300 4
N 46500 48300 46500 48400 4
C 51400 46400 1 0 0 nand42.sym
{
T 51700 47300 5 10 1 1 0 0 1
refdes=U7
T 51895 48100 5 10 0 1 0 0 1
device=nand
T 51700 46300 5 10 0 1 0 0 1
model-name=NAND
}
C 51400 44400 1 0 0 nand42.sym
{
T 51700 45300 5 10 1 1 0 0 1
refdes=U9
T 51895 46100 5 10 0 1 0 0 1
device=nand
T 51700 44300 5 10 0 1 0 0 1
model-name=NAND
}
C 49500 46600 1 0 0 nand42.sym
{
T 49800 47500 5 10 1 1 0 0 1
refdes=U6
T 49995 48300 5 10 0 1 0 0 1
device=nand
T 49800 46500 5 10 0 1 0 0 1
model-name=NAND
}
C 49500 44200 1 0 0 nand42.sym
{
T 49800 45100 5 10 1 1 0 0 1
refdes=U8
T 49995 45900 5 10 0 1 0 0 1
device=nand
T 49800 44100 5 10 0 1 0 0 1
model-name=NAND
}
C 47400 43200 1 0 0 nand42.sym
{
T 47700 44100 5 10 1 1 0 0 1
refdes=U11
T 47895 44900 5 10 0 1 0 0 1
device=nand
T 47700 43100 5 10 0 1 0 0 1
model-name=NAND
}
N 49400 44900 49400 46900 4
N 49500 46900 49400 46900 4
N 49500 44900 49400 44900 4
N 48600 47300 49500 47300 4
{
T 48500 47400 5 10 1 1 0 0 1
netname=S
}
N 48900 45500 49400 45500 4
N 48900 43700 48900 45500 4
N 47800 47000 48600 47000 4
N 47800 45000 48600 45000 4
{
T 48500 45100 5 10 1 1 0 0 1
netname=R
}
N 46400 47200 46500 47200 4
N 46400 44800 46500 44800 4
N 46100 46800 46500 46800 4
N 46300 45200 46500 45200 4
N 47900 47000 47900 46100 4
N 47900 46100 46300 46100 4
N 46300 46100 46300 45200 4
N 47900 45000 47900 45900 4
N 47900 45900 46100 45900 4
N 46100 45900 46100 46800 4
C 46500 46500 1 0 0 nand42.sym
{
T 46995 48200 5 10 0 1 0 0 1
device=nand
T 46800 47400 5 10 1 1 0 0 1
refdes=U2
T 46800 46400 5 10 0 1 0 0 1
model-name=NAND
}
C 46500 44500 1 0 0 nand42.sym
{
T 46995 46200 5 10 0 1 0 0 1
device=nand
T 46800 45400 5 10 1 1 0 0 1
refdes=U5
T 46800 44400 5 10 0 1 0 0 1
model-name=NAND
}
C 45100 46700 1 0 0 nand42.sym
{
T 45595 48400 5 10 0 1 0 0 1
device=nand
T 45400 47600 5 10 1 1 0 0 1
refdes=U1
T 45400 46600 5 10 0 1 0 0 1
model-name=NAND
}
C 45100 44300 1 0 0 nand42.sym
{
T 45595 46000 5 10 0 1 0 0 1
device=nand
T 45400 45200 5 10 1 1 0 0 1
refdes=U4
T 45400 44200 5 10 0 1 0 0 1
model-name=NAND
}
N 45000 43700 45000 47000 4
N 45100 47000 45000 47000 4
N 48600 47000 48600 47300 4
N 48600 45000 48600 44500 4
N 48600 44500 49500 44500 4
N 47300 43500 47300 43900 4
N 47400 43900 47300 43900 4
N 47400 43500 47300 43500 4
N 48900 43700 48700 43700 4
N 45100 47400 43000 47400 4
{
T 42900 47600 5 10 1 1 0 0 1
netname=Data
}
N 44900 43700 47300 43700 4
C 43500 46700 1 270 0 nand42.sym
{
T 44400 46100 5 10 1 1 0 0 1
refdes=U3
T 45200 46205 5 10 0 1 270 0 1
device=nand
T 44200 45500 5 10 0 1 0 0 1
model-name=NAND
}
N 44200 46800 43800 46800 4
N 44000 46800 44000 47400 4
N 44200 46800 44200 46700 4
N 43800 46800 43800 46700 4
N 44000 45400 44000 44600 4
N 45100 45000 45000 45000 4
N 45100 44600 44000 44600 4
C 43600 43200 1 0 0 nand42.sym
{
T 43900 44100 5 10 1 1 0 0 1
refdes=U10
T 44095 44900 5 10 0 1 0 0 1
device=nand
T 43900 43100 5 10 0 1 0 0 1
model-name=NAND
}
N 43000 43700 43500 43700 4
{
T 42800 43900 5 10 1 1 0 0 1
netname=Clock
}
N 43500 43500 43500 43900 4
N 43600 43900 43500 43900 4
N 43500 43500 43600 43500 4
C 50100 48400 1 90 0 resistor-2.sym
{
T 49750 48800 5 10 0 0 90 0 1
device=RESISTOR
T 49800 49100 5 10 1 1 180 0 1
refdes=R1
T 49500 48700 5 10 1 1 0 0 1
value=10k
}
C 48200 48000 1 0 0 gnd-1.sym
N 50800 47100 51400 47100 4
C 49600 42700 1 0 0 nand42.sym
{
T 50095 44400 5 10 0 1 0 0 1
device=nand
T 49900 42600 5 10 0 1 0 0 1
model-name=NAND
T 49900 43600 5 10 1 1 0 0 1
refdes=U12
}
C 51100 42700 1 0 0 nand42.sym
{
T 51595 44400 5 10 0 1 0 0 1
device=nand
T 51400 42600 5 10 0 1 0 0 1
model-name=NAND
T 51400 43600 5 10 1 1 0 0 1
refdes=U13
}
N 51100 43400 51000 43400 4
N 51000 43000 51000 43400 4
N 51100 43000 51000 43000 4
N 50900 43200 51000 43200 4
N 49200 43000 49600 43000 4
{
T 49000 43100 5 10 1 1 0 0 1
netname=CLR
}
N 50800 44700 50900 44700 4
N 50900 44700 50900 44000 4
N 49500 43400 49500 44000 4
N 49500 44000 50900 44000 4
N 49600 43400 49500 43400 4
N 52400 43200 52400 44000 4
N 52400 44000 51300 44000 4
N 51300 44000 51300 44700 4
N 51400 44700 51300 44700 4
C 49800 49400 1 0 0 vcc-1.sym
C 48500 48400 1 90 0 capacitor-1.sym
{
T 47800 48600 5 10 0 0 90 0 1
device=CAPACITOR
T 48200 49200 5 10 1 1 180 0 1
refdes=C1
T 47600 48600 5 10 0 0 90 0 1
symversion=0.1
T 48200 48700 5 10 1 1 180 0 1
value=0.1u
}
N 48300 48400 48300 48300 4
N 48300 49300 48300 49600 4
{
T 48400 49500 5 10 1 1 0 0 1
netname=CLR
}
N 50000 48400 50000 48100 4
{
T 50100 48100 5 10 1 1 0 0 1
netname=CLR
}
N 50000 49400 50000 49300 4
C 51200 49000 1 0 0 spice-directive-1.sym
{
T 51300 49300 5 10 0 1 0 0 1
device=directive
T 51300 49400 5 10 1 1 0 0 1
refdes=A1
T 51300 49100 5 10 0 1 0 0 1
file=unknown
T 51300 49100 5 10 1 1 0 0 1
value=.ic v(CLR)=0
}
