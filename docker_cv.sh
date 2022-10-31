#!/bin/bash

cd "`dirname "${BASH_SOURCE[0]}"`"

export LC_ALL=C

docker run --rm -it -p 8080:8080 -v `pwd`:/home/oleg -w /home node:10.6.0 bash -c '
git clone https://github.com/salomonelli/best-resume-ever.git --depth 1
cd best-resume-ever
echo "
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
3kG+aSfoG9qGef8A4yxMTExgKD//2Q==" | base64 -d > resume/id.jpg
echo "
LyogIyovIGV4cG9ydCBjb25zdCBQRVJTT04gPSBgCiMgQW55IGZpZWxkcyBsZWZ0IHVuY2hhbmdl
ZCwgcGxlYXNlIGRlbGV0ZSBzbyB5b3VyIHJlc3VtZSBpcyBmdWxseSB5b3VycyEKCm5hbWU6CiAg
Zmlyc3Q6IE9sZWcKICBsYXN0OiBNYXprbwphYm91dDogSSBsaWtlIEVtYmVkZGVkLCBBSSwgUHl0
aG9uLCBMaW51eCwgU21hcnQgSG9tZS4KICAgICAgIEkgZGlzbGlrZSBzb2NpYWwgbmV0d29ya2lu
ZywgYmFua2luZywgZ2FtYmxpbmcuCgpwb3NpdGlvbjogU29mdHdhcmUgLyBFbWJlZGRlZCAvIEFJ
CgpiaXJ0aDoKICB5ZWFyOiAxMy4wNC44NAogIGxvY2F0aW9uOiBLYW1pYW5za2UgQ2l0eQoKIyB5
b3UgbWF5IGFkZCBtb3JlIGV4cGVyaWVuY2VzIGJ5IGR1cGxpY2F0aW5nIHRoZSB0ZW1wbGF0ZQoK
ZXhwZXJpZW5jZToKLSBjb21wYW55OiBBMUMKICBwb3NpdGlvbjogU29mdHdhcmUgLyBFbWJlZGRl
ZCBEZXZlbG9wZXIKICB0aW1lcGVyaW9kOiAyMDE3IC0gMjAyMQogIGRlc2NyaXB0aW9uOiBJb1Qs
IEFJLCBTcGVlY2ggUmVjb2duaXRpb24sIEVTUDMyLCBTVE0zMgoKLSBjb21wYW55OiBCcmFudG8g
SW5jCiAgcG9zaXRpb246IFNvZnR3YXJlIC8gRW1iZWRkZWQgRGV2ZWxvcGVyCiAgdGltZXBlcmlv
ZDogMjAxMyAtIDIwMTUKICBkZXNjcmlwdGlvbjogTGludXgsIEVtYmVkZGVkLCBQSUMzMiwgUHl0
aG9uCgotIGNvbXBhbnk6IENvaG9ycyBMTEMKICBwb3NpdGlvbjogU29mdHdhcmUgRGV2ZWxvcGVy
CiAgdGltZXBlcmlvZDogMjAxMSAtIDIwMTIKICBkZXNjcmlwdGlvbjog0KEjIGF1dG9tYXRpb24g
Zm9yIG1hdGggd2ViIHNlcnZpY2VzCgotIGNvbXBhbnk6IEl2ZW9uaWsgU3lzdGVtcwogIHBvc2l0
aW9uOiBTb2Z0d2FyZSBEZXZlbG9wZXIKICB0aW1lcGVyaW9kOiAyMDA4IC0gMjAxMAogIGRlc2Ny
aXB0aW9uOiBDIywgV2ViIGNyYXdsZXJzLCBMdWNlbmUKCi0gY29tcGFueTog0JzQodChCiAgcG9z
aXRpb246IEVtYmVkZGVkIERldmVsb3BlcgogIHRpbWVwZXJpb2Q6IDIwMDcgLSAyMDA4CiAgZGVz
Y3JpcHRpb246IE1pY3JvY2hpcCBNQ1UsIFJldmVyc2UgRW5naW5lZXJpbmcsIEdQUywgR1NNCgpl
ZHVjYXRpb246Ci0gZGVncmVlOiBFbGVjdHJvbmljIEVuZ2luZWVyaW5nCiAgdGltZXBlcmlvZDog
MjAwMCAtIDIwMDYKICBkZXNjcmlwdGlvbjogREdUVSAtIEthbWlhbnNrZQogIHdlYnNpdGU6IGh0
dHBzOi8vd3d3LmRzdHUuZHAudWEvCgojIHNraWxsIGxldmVsIGdvZXMgZnJvbSAwIHRvIDEwMApz
a2lsbHM6Ci0gbmFtZTogTGludXgKICBsZXZlbDogOTkKLSBuYW1lOiBFU1AzMgogIGxldmVsOiA5
NQotIG5hbWU6IEZyZWVSVE9TCiAgbGV2ZWw6IDk3Ci0gbmFtZTogSW9UCiAgbGV2ZWw6IDkzCi0g
bmFtZTogTmV0d29ya2luZyBQcm90b2NvbHMKICBsZXZlbDogNjAKLSBuYW1lOiBFbGVjdHJvbmlj
IFNjaGVtYXRpY3MKICBsZXZlbDogODAKLSBuYW1lOiBQeXRob24KICBsZXZlbDogNzAKLSBuYW1l
OiBDIC8gQysrCiAgbGV2ZWw6IDcwCi0gbmFtZTogVGVuc29yZmxvdwogIGxldmVsOiA3MAotIG5h
bWU6IEFJCiAgbGV2ZWw6IDcwCi0gbmFtZTogU3BlZWNoIFJlY29nbml0aW9uCiAgbGV2ZWw6IDcw
Ci0gbmFtZTogUmVpbmZvcmNlbWVudCBMZWFybmluZwogIGxldmVsOiA3MAotIG5hbWU6IERvY2tl
cgogIGxldmVsOiA5OQoKcHJvamVjdHM6Ci0gbmFtZTogYXdrLmpzCiAgcGxhdGZvcm06IGpRdWVy
eSwgQm9vdHN0cmFwLCBFbXNjcmlwdGVuCiAgdXJsOiBodHRwczovL2F3ay5qcy5vcmcKCi0gbmFt
ZTogTUNVIHNpbXVsYXRvcgogIHBsYXRmb3JtOiBBbmd1bGFyMiwgQm9vdHN0cmFwLCBFbXNjcmlw
dGVuCiAgdXJsOiBodHRwOi8vbWF6a28uZ2l0aHViLmlvL01TUDQzMC5qcy8zNTIzZTAxZTNlNmM5
NjA4OGQwYWM2YTRjMzM1NjA5YgoKLSBuYW1lOiBLZXl3b3JkIFNwb3R0aW5nCiAgcGxhdGZvcm06
IFRlbnNvcmZsb3csIExpbnV4CiAgdXJsOiBodHRwczovL2dpdGh1Yi5jb20vNDJpby90ZmxpdGVf
a3dzCgotIG5hbWU6IEphdmEgUGFyc2VyCiAgcGxhdGZvcm06IENvbXBpbGVycywgQWJzdHJhY3Qg
U3ludGF4IFRyZWUKICB1cmw6IGh0dHBzOi8vbWF6a28uZ2l0aHViLmlvL2pzamF2YXBhcnNlcgoK
Y29udHJpYnV0aW9uczoKLSBuYW1lOiBDUFUgVXNhZ2UgTEVEcwogIGRlc2NyaXB0aW9uOiBBcnRp
Y2xlIGluIHBvcHVsYXIgUnVzc2lhbiBqb3VybmFsCiAgdXJsOiBodHRwOi8vd3d3LnJhZGlvLnJ1
L2FyY2hpdmUvMjAwNi8wMy9hMTguc2h0bWwKCmNvbnRhY3Q6CiAgZW1haWw6IG1hemtvb2xlZ0Bn
bWFpbC5jb20KICBwaG9uZTogJysweDU4YjI4NjIyZjYnCiAgY2l0eTogS2FtaWFuc2tlLCBEbmlw
cm9wZXRyb3ZzayBPYmxhc3QKICB3ZWJzaXRlOiBodHRwczovL21hemtvLmdpdGh1Yi5pbwogIGdp
dGh1YjogbWF6a28KIyBlbiwgZGUsIGZyLCBwdCwgY2EsIGNuLCBpdCwgZXMsIHRoLCBwdC1iciwg
cnUsIHN2LCBpZCwgaHUsIHBsLCBqYSwga2EsIG5sLCBoZSwgemgtdHcsIGx0LCBrbywgZWwsIG5i
LW5vCmxhbmc6IGVuCmAK" | base64 -d > resume/data.yml
apt update
apt install -yq xvfb gconf-service libasound2 libatk1.0-0 libc6 libcairo2 \
    libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgcc1 libgconf-2-4 \
    libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 \
    libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 \
    libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 \
    libxss1 libxtst6 ca-certificates fonts-liberation libnss3 lsb-release \
    xdg-utils
npm install && npm run export
cp pdf/cool.pdf /home/oleg/best-resume-ever-cool.pdf
'