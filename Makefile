USER_NAME ?= yourname

IMAGE_PATHS ?=	./src/comment \
								./src/post-py \
								./src/ui \
								./monitoring/blackbox_exporter \
								./monitoring/mongodb_exporter \
								./monitoring/prometheus

.PHONY: build pull push remove start stop

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

start:
	@cd ${CURDIR}/docker && docker-compose up -d

stop:
	@cd ${CURDIR}/docker && docker-compose down

default: build
