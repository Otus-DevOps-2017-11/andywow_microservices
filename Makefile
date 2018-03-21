#include ./docker/.env

USER_NAME ?= yourname

IMAGE_PATHS ?=	./src/comment \
		./src/post-py \
		./src/ui \
		./monitoring/mongodb_exporter \
		./monitoring/prometheus \
		./monitoring/alertmanager \
		./monitoring/grafana \
		./docker/fluentd

STACKS ?= DEV

#NETWORKS ?= front_net back_net mgmt_net

.PHONY: build pull push remove deploy
#	start-network start-service start-logging start-monitor start \
#	stop-network stop-service stop-logging stop-monitor stop

define get_image_name
	${USER_NAME}/$(lastword $(subst /, " ", "$1"))
endef

build:
	@$(foreach IMAGE_PATH, $(IMAGE_PATHS), \
		echo Building ${IMAGE_PATH}; \
		cd ${IMAGE_PATH}; \
		if [ -f ./docker_build.sh ]; then \
			bash docker_build.sh; \
		else \
			docker build -t $(call get_image_name,${IMAGE_PATH}) . ; \
		fi; \
		cd ${CURDIR}; \
	)

#logs:
#	@cd ${CURDIR}/docker && docker-compose \
#		-f docker-compose.yml \
#		-f docker-compose-monitoring.yml \
#		logs ${CONTAINER}


push:
	@$(foreach IMAGE_PATH, $(IMAGE_PATHS), \
		docker push $(call get_image_name,${IMAGE_PATH}); \
	)

pull:
	@$(foreach IMAGE_PATH, $(IMAGE_PATHS), \
		docker pull $(call get_image_name,${IMAGE_PATH}); \
	)

remove:
	@$(foreach IMAGE_PATH, $(IMAGE_PATHS), \
		docker rmi $(call get_image_name,${IMAGE_PATH}); \
	)

deploy:
	@echo "Deploying stacks"
	@$(foreach STACK, $(STACKS), \
		cd ${CURDIR}/docker && \
		cp .env_${STACK} .env && \
		docker-compose -f docker-compose.yml -f docker-compose-monitoring.yml config 1>united.yml 2>/dev/null && \
		docker stack deploy --compose-file=united.yml ${STACK} ; \
	)

#start-network:
#	@echo "Starting network"
#	@$(foreach NETWORK, $(NETWORKS), \
#		docker network inspect ${NETWORK} 1>/dev/null 2>&1 || \
#		docker network create ${NETWORK}; \
#	)

#start-service:
#	@echo "Starting services"
#	@cd ${CURDIR}/docker && docker-compose up -d

#start-logging:
#	@echo "Starting logging services"
#	@cd ${CURDIR}/docker && docker-compose \
#		-f docker-compose-logging.yml up -d

#start-monitor:
#	@echo "Starting monitor services"
#	@cd ${CURDIR}/docker && docker-compose \
#		-f docker-compose-monitoring.yml up -d

#start: start-network start-service start-monitor

#stop-network:
#	@echo "Stopping network"
#	@$(foreach NETWORK, $(NETWORKS), \
#		docker network inspect ${NETWORK} 1>/dev/null 2>&1 && \
#		docker network rm ${NETWORK} || \
#		true; \
#	)

#stop-service:
#	@echo "Stopping services"
#	@cd ${CURDIR}/docker && docker-compose down

#stop-logging:
#	@echo "Stopping logging services"
#	@cd ${CURDIR}/docker && docker-compose -f docker-compose-logging.yml down

#stop-monitor:
#	@echo "Stopping monitor services"
#	@cd ${CURDIR}/docker && docker-compose -f docker-compose-monitoring.yml down

#stop: stop-monitor stop-service stop-network

default: build
