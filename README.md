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

As a security precaution, GitHub automatically deletes SSH keys that haven't been used in a year.

	~: ssh-keygen -t ed25519 -C "o.mazko@mail.ru" -N '' -f ~/github_deploy_key
	~: cd mazko.github.io && travis encrypt-file ~/github_deploy_key

[1]: https://travis-ci.org/mazko/mazko.github.io.svg?branch=src "Build Status"
[2]: https://travis-ci.org/mazko/mazko.github.io
[3]: http://docs.getpelican.com/