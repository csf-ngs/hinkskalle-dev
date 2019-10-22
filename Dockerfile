FROM docker.ngs.vbcf.ac.at/flask-base

RUN apt-get install gosu

RUN pip install mongodb-migrations

RUN useradd -d /srv/hinkskalle -m -s /bin/bash hinkskalle

WORKDIR /srv/hinkskalle/src
CMD gosu hinkskalle /srv/hinkskalle/src/script/start.sh

EXPOSE 5000
