FROM grafana/grafana:5.0.0-beta4

COPY datasources/datasource.yml /etc/grafana/provisioning/datasources/datasource.yml
COPY dashboards/dashboards.yml /etc/grafana/provisioning/dashboards/dashboards.yml
COPY dashboards/*.json /var/lib/grafana/dashboards/
