# mazko.github.io [![1]][2]

[Pelican][3] blog:

    ~$ virtualenv ~/virtualenvs/pelican
    ~$ cd ~/virtualenvs/pelican && . bin/activate ; cd -
    ~$ pip install -r requirements.txt
    ~$ git clone -b src https://github.com/mazko/mazko.github.io.git
    ~$ cd mazko.github.io
    ~$ pelican --fatal warnings content && \
         [[ "`ls -A -1 -I 'index?*.html' output/ | cksum`" == "1224166325 28" ]] && \
         bash -c 'cd output/ && python -m pelican.server'

Browse http://localhost:8000/

[1]: https://travis-ci.org/mazko/mazko.github.io.svg?branch=src "Build Status"
[2]: https://travis-ci.org/mazko/mazko.github.io
[3]: http://docs.getpelican.com/