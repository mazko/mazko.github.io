[Pelican][1] blog:

    ~$ git clone https://github.com/mazko/mazko.github.io.git && cd mazko.github.io

Write some stuff, browse it http://localhost:8000/:

    ~$ ./docker_server.sh

Deploy:

    ~$ ./docker_deploy.sh

As a security precaution, GitHub automatically deletes SSH keys that haven't been used in a year.

    ~$ ssh-keygen -t ed25519 -C "o.mazko@mail.ru" -N '' -f ~/github_deploy_key
    ~$ gpg --output github_deploy_key.enc --symmetric --cipher-algo AES256 ~/github_deploy_key

[1]: http://docs.getpelican.com/