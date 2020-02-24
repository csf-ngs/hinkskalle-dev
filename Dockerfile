FROM docker.ngs.vbcf.ac.at/singularity-base as singularity

FROM docker.ngs.vbcf.ac.at/flask-base:v1.1.1

RUN apt-get install gosu

RUN pip install mongodb-migrations

RUN useradd -d /srv/hinkskalle -m -s /bin/bash hinkskalle

COPY --from=singularity /usr/local/bin/*singularity* /usr/local/bin/
COPY --from=singularity /usr/local/etc/singularity/ /usr/local/etc/singularity/
COPY --from=singularity /usr/local/libexec/singularity/ /usr/local/libexec/singularity/
COPY --from=singularity /usr/local/var/singularity/ /usr/local/var/singularity/

WORKDIR /srv/hinkskalle/src
CMD gosu hinkskalle /srv/hinkskalle/src/script/start.sh

EXPOSE 5000
