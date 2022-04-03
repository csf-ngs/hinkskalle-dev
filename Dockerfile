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

RUN mkdir -p ${GOPATH}/src/github.com/sylabs \
  && cd ${GOPATH}/src/github.com/sylabs \
  && git clone https://github.com/sylabs/singularity.git \
  && cd singularity \
  && git fetch --all \
  && git checkout v3.8.0 \
  && ./mconfig \
  && cd ./builddir \
  && make \
  && make install \
  && mv /usr/local/etc/singularity/singularity.conf /usr/local/etc/singularity/singularity.conf.bak \
  && sed -e 's/mount hostfs = no/mount hostfs = yes/' /usr/local/etc/singularity/singularity.conf.bak > /usr/local/etc/singularity/singularity.conf 

COPY share/*-plain-http.patch /tmp/

RUN cd ${GOPATH}/src/github.com/sylabs/singularity \
  && patch -p1 < /tmp/singularity-plain-http.patch \
  && patch -p1 < /tmp/oras-plain-http.patch \
  && cd ./builddir \
  && make \
  && cp singularity /usr/local/bin/singularity.dev 


FROM ubuntu:20.04

ENV TZ=Europe/Vienna

RUN apt-get update \
  && apt-get upgrade -y \
  && apt-get install -y --no-install-recommends bash curl locales gosu ca-certificates tzdata \
  && ln -sf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
  && sed -i -e 's/# \(en_US\.UTF-8 .*\)/\1/' /etc/locale.gen \
  && locale-gen

ENV LC_ALL en_US.UTF-8

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
      python3 python3-pip python3-dev python3-setuptools python3-distutils \
  && pip3 install --upgrade pip

RUN echo "deb http://apt.postgresql.org/pub/repos/apt focal-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
    && apt-get install --no-install-recommends -y gnupg2 \
  && curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
  && apt-get update \
  && apt-get install -y --no-install-recommends postgresql-client libpq-dev \
  && apt-get autoremove -y gnupg2

RUN pip3 install 'werkzeug>=2.0.0' 'flask>=2.0.0' SimpleJSON Flask-Session flask-rebar>=v2.0.0 'flask_wtf>=1.0.0' python-dotenv \
  && pip3 install requests PyYAML \
  && pip3 install gunicorn \
  && pip3 uninstall -y enum34 \
  && pip3 install Flask-SQLAlchemy Flask-Migrate \
  && apt-get install -y gcc \
  && pip3 install psycopg2 \
  && apt-get autoremove -y gcc \
  && pip3 install nose2 nose2-html-report nose2\[coverage_plugin\] fakeredis \
  && pip3 install passlib ldap3 Flask-RQ2 fakeredis pyjwt humanize 

RUN useradd -d /srv/hinkskalle -m -s /bin/bash hinkskalle

COPY --from=singularity-build /usr/local/bin/*singularity* /usr/local/bin/
COPY --from=singularity-build /usr/local/etc/singularity/ /usr/local/etc/singularity/
COPY --from=singularity-build /usr/local/libexec/singularity/ /usr/local/libexec/singularity/
COPY --from=singularity-build /usr/local/var/singularity/ /usr/local/var/singularity/

RUN curl -sL https://deb.nodesource.com/setup_16.x | bash - \
  && apt-get update \
  && apt-get install -y nodejs

RUN npm install -g @vue/cli yarn

WORKDIR /srv/hinkskalle/src
CMD gosu hinkskalle /srv/hinkskalle/src/script/start-dev.sh

EXPOSE 5000
LABEL org.opencontainers.image.source https://github.com/csf-ngs/hinkskalle-dev
