FROM quay.io/prometheus/busybox:latest

LABEL maintainer="Alexey Palazhchenko <alexey.palazhchenko@percona.com>"

COPY mongodb_exporter /bin/mongodb_exporter

EXPOSE 9216
ENTRYPOINT [ "/bin/mongodb_exporter" ]
