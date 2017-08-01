FROM alpine:3.6

ADD . /tmp/src/qucs

RUN set -xe \
    && apk add --update \

    && apk add --no-cache --virtual .deps \
           qt-x11 \
           ttf-ubuntu-font-family \

    && apk add --no-cache --virtual .build-deps \
           build-base \
           libtool \
           autoconf \
           automake \
           bison \
           flex \
           git \
           perl-gd \
           perl-xml-libxml \
           qt-dev \
           gperf \
           icu-dev \

    # Build deps

    # Build ADMS from master (avoid need of Perl and its modules)
    # ADMS is a codegenerator for the VERILOG-A(MS) language    
    && git clone https://github.com/Qucs/ADMS.git /tmp/src/adms \
    && cd /tmp/src/adms \
    && ./bootstrap.sh \
    && ./configure --disable-doc --prefix=/usr/local \
    && make \ 
    && make install \

    # Build asco
    # TODO ?

    # Build Qucs
    && cd /tmp/src/qucs \
    && ./bootstrap \
    && ./configure --disable-doc --prefix=/usr/local \
    && make \
    && make install \
	
    # Clean
    && rm -rf /tmp/* \
    && apk del --purge .build-deps

ENV DISPLAY=unix:0.0

ENTRYPOINT [ "qucs" ]
