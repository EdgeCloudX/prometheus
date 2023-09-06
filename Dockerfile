FROM --platform=$BUILDPLATFORM golang:1.19 as builder
ENV GOPATH /gopath/
ENV PATH $GOPATH/bin/$PATH

RUN go version
RUN  go env -w GOPROXY=https://goproxy.io,direct
RUN  go env -w GO111MODULE=on

COPY . /go/src/prometheus/
WORKDIR /go/src/prometheus/
RUN ls /go/src/prometheus/
RUN cat Makefile
RUN make package-build


FROM --platform=$BUILDPLATFORM  alpine:latest

COPY --from=builder /go/src/prometheus/build/prometheus   /bin/prometheus
COPY --from=builder /go/src/prometheus/build/promtool     /bin/promtool
COPY --from=builder /go/src/prometheus/documentation/examples/prometheus.yml  /etc/prometheus/prometheus.yml
COPY --from=builder /go/src/prometheus/console_libraries/                     /usr/share/prometheus/console_libraries/
COPY --from=builder /go/src/prometheus/consoles/                              /usr/share/prometheus/consoles/
COPY --from=builder /go/src/prometheus/LICENSE                                /LICENSE
COPY --from=builder /go/src/prometheus/NOTICE                                 /NOTICE
COPY --from=builder /go/src/prometheus/npm_licenses.tar.bz2                   /npm_licenses.tar.bz2
COPY --from=builder /go/src/prometheus/web/ui/static/react/index.html         /bin/web/ui/static/react/index.html

WORKDIR /prometheus
RUN ln -s /usr/share/prometheus/console_libraries /usr/share/prometheus/consoles/ /etc/prometheus/ && \
    chown -R nobody:nobody /etc/prometheus /prometheus

USER       nobody
EXPOSE     9090
VOLUME     [ "/prometheus" ]
ENTRYPOINT [ "/bin/prometheus" ]
CMD        [ "--config.file=/etc/prometheus/prometheus.yml", \
             "--storage.tsdb.path=/prometheus", \
             "--web.console.libraries=/usr/share/prometheus/console_libraries", \
             "--web.console.templates=/usr/share/prometheus/consoles" ]
