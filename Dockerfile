FROM golang:1.13 as singularity-build

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    build-essential \
    libssl-dev \
    uuid-dev \
    libseccomp-dev \
    pkg-config \
    squashfs-tools \
    cryptsetup \
    git 

COPY share/singularity-plain-http.patch /tmp/

RUN mkdir -p ${GOPATH}/src/github.com/sylabs \
  && cd ${GOPATH}/src/github.com/sylabs \
  && git clone https://github.com/sylabs/singularity.git \
  && cd singularity \
  && git fetch --all \
  && git checkout v3.5.2 \
  && ./mconfig \
  && cd ./builddir \
  && make \
  && make install \
  && mv /usr/local/etc/singularity/singularity.conf /usr/local/etc/singularity/singularity.conf.bak \
  && sed -e 's/mount hostfs = no/mount hostfs = yes/' /usr/local/etc/singularity/singularity.conf.bak > /usr/local/etc/singularity/singularity.conf 

RUN cd ${GOPATH}/src/github.com/sylabs/singularity \
  && patch -p1 < /tmp/singularity-plain-http.patch \
  && ./mconfig \
  && cd ./builddir \
  && make \
  && cp singularity /usr/local/bin/singularity.dev 


FROM docker.ngs.vbcf.ac.at/flask-base:v1.1.2

RUN apt-get install gosu

RUN useradd -d /srv/hinkskalle -m -s /bin/bash hinkskalle

COPY --from=singularity-build /usr/local/bin/*singularity* /usr/local/bin/
COPY --from=singularity-build /usr/local/etc/singularity/ /usr/local/etc/singularity/
COPY --from=singularity-build /usr/local/libexec/singularity/ /usr/local/libexec/singularity/
COPY --from=singularity-build /usr/local/var/singularity/ /usr/local/var/singularity/

RUN pip3 install passlib

WORKDIR /srv/hinkskalle/src
CMD gosu hinkskalle /srv/hinkskalle/src/script/start.sh

EXPOSE 5000
