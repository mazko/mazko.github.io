FROM ubuntu:18.04

ARG UID
RUN useradd -m -u ${UID} ci

WORKDIR /home/ci
COPY requirements.txt /patches/adsense.patch ./

RUN apt-get -qq update && \
    apt-get -qq install -y python python-pip git && \
    apt-get --reinstall install -qq language-pack-en language-pack-ru && \
    pip install -r requirements.txt

WORKDIR /usr/local/lib/python2.7/dist-packages/pelican/themes/notmyidea
RUN patch -p1 < /home/ci/adsense.patch

WORKDIR /home/ci
RUN rm requirements.txt adsense.patch

USER ci

RUN echo '#!/bin/bash' > server.sh && chmod +x server.sh && \
    echo 'rm -rf output/ && pelican --fatal warnings content && \
          [[ "`ls -A -1 -I '"'"'index?*.html'"'"' output/ | cksum`" == "1224166325 28" ]] && \
          cd output/ && python -m pelican.server' >> server.sh

RUN echo '#!/bin/bash' > deploy.sh && chmod +x deploy.sh && \
    echo 'gpg --output ~/github_deploy_key --decrypt github_deploy_key.enc > /dev/null 2>&1 && \
          chmod 600 ~/github_deploy_key && eval `ssh-agent -s` > /dev/null 2>&1 && \
          ssh-add ~/github_deploy_key > /dev/null 2>&1 && \
          git checkout master && git status --porcelain | wc -l | grep -q '"'"'^0$'"'"' && \
          pelican content --fatal warnings -o ~/pelican-content -s publishconf.py && \
          cp google6294828ff42db199.html ads.txt CNAME ~/pelican-content && \
          git checkout gh-pages && rm -rf * && mv ~/pelican-content/* . && \
          [[ "`ls -A -1 -I '"'"'index?*.html'"'"' -I '"'"'.git'"'"' | cksum`" != "946689073 281" ]] && \
          git add -A && git -c user.name='"'"'Docker CI'"'"' -c user.email='"'"'<>'"'"' commit -m '"'"'up'"'"' && \
          git status --porcelain | wc -l | grep -q '"'"'^0$'"'"' && \
          git push "git@github.com:mazko/mazko.github.io.git" gh-pages && \
          git checkout master && git push "git@github.com:mazko/mazko.github.io.git" master && \
          git pull' >> deploy.sh

RUN ssh -o StrictHostKeyChecking=no -T git@github.com > /dev/null 2>&1 || true

WORKDIR /home/src