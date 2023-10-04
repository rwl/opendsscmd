FROM ubuntu:focal as cmdbuilder

RUN apt-get update && apt-get install -yq --no-install-recommends \
	build-essential ca-certificates wget valgrind

RUN mkdir -p /workspace
WORKDIR /workspace
RUN wget https://altushost-swe.dl.sourceforge.net/project/lazarus/Lazarus%20Linux%20amd64%20DEB/Lazarus%202.2.6/fpc-src_3.2.2-210709_amd64.deb
RUN wget https://netix.dl.sourceforge.net/project/lazarus/Lazarus%20Linux%20amd64%20DEB/Lazarus%202.2.6/fpc-laz_3.2.2-210709_amd64.deb
RUN dpkg -i fpc-src_3.2.2-210709_amd64.deb fpc-laz_3.2.2-210709_amd64.deb

COPY klusolve /usr/src/klusolve

RUN cd /usr/src/klusolve \
	&& mkdir -p Lib \
	&& make clean all \
	&& cp Lib/libklusolve.a /usr/local/lib \
	&& ldconfig

RUN ln -sv /usr/lib/x86_64-linux-gnu/libstdc++.so.6 /usr/lib/x86_64-linux-gnu/libstdc++.so
RUN ln -sv /lib/x86_64-linux-gnu/libgcc_s.so.1 /lib/x86_64-linux-gnu/libgcc_s.so

#COPY lib/opendss /usr/src/opendss
COPY dsscapi /usr/src/opendss

RUN make -C /usr/src/opendss clean check install

ENTRYPOINT ["opendsscmd"]
