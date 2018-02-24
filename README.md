# Homework-21 Monitoring-2

## Базовая часть

Разбили наш `docker-compose.yml` на 2 конфига - один для сервисов, второй для
мониторинга.

Установили `cAdvisor`. Сбор метрик с docker-контейнеров работает.

Установили `Grafana`. Сделали пару dashboard-ов. Добавили сборк метрик с
приложения `post`. Не совсем понял, почему метрика `post_count` появивилась не
сразу. Второй раз сэмелировать это не удалось.

Установили `alertmanager`. Настроили alerting на недоступность сервиса.
Настроили нотификацию в slack-чат.

URL dockerhub: https://hub.docker.com/r/andywow




# Homework-21 Monitoring-1

## Базовая часть

Развернули сервис мониторинга `prometheus`. посмотрели, как он мониторит сам
себя.

Переделали структуру проекта. Собрали образы наших 3-х приложений + сервиса
`prometheus` с тегом `latest`.

В процессе работы с `docker-compose` выяснил, что у приложения `comment` не
хватает в зависимостях гема `tzinfo-data`.

Подняли нашу новую инфраструктуру. Посмотрели метрики приложений в `prometheus`.
Посмотрели зависимости метрик.

У сервиса `comment` есть метрика, отвечающая за доступность БД:
`comment_health_mongo_availability`.

Поставили `node-explorter`, чтобы собирать метрики docker-хоста.

URL dockerhub: https://hub.docker.com/r/andywow

## Задание *

Выбрал 1-й экспортер из поика google-а: https://github.com/percona/mongodb_exporter
Заодно научился собирать go-программы ;)

Blackbox-экспортер также настроен.

Сначало хотел отказаться от создания management-сети, потом решил все таки
попробовать ее
сделать. Пришлось для хостов прописывать разные альясы в каждую из сетей, чтобы
в конфигах сервисов можно было их явно указывать. Основное условие - БД у нас
доступна только и `back_net` сети.

Приложение `prometheus` собирает все метрики из `management` сети с `exporter`-ов.

Makefile сделан. С `targets`: `[build, push, pull, remove, start, stop]`

Можно билдить отдельные образы : `make -e IMAGE_PATHS=./src/comment`

# Homework-20 Docker-7

## Базовая часть

Изменили pipeline, посмотрели, как для разных веток можно видоизменять pipeline.

## Задание * и **

Это было одно из самых интересных и сложных заданий. Предварительно было сделано:
1. В настройках runner-а добавлена опция:
```
[runners.docker]
  privileged = true
```
, чтобы он мог использовать docker демон.

2. В настройках проекта установлены следующие приватные переменные:

Имя|Описание
-|-
HUB_LOGIN | Логин на dockerhub
HUB_PASSWORD | Пароль на dockerhub
GITLAB_TOKEN | Token для нашего gitlab-а
GCE_KEY | Содержимое файла gce.key (сгенерировал в предыдущей ДЗ) в base64 формате

GCE-ключи преобразовали в base64 формат комадной `base64 -w 0 key.json`

GITLAB-токен нам нужен для того, чтобы с помощью gitlab web-api менять ссылку
в Environemnt-е на наш тестовый стенд.

Постарался использовать минимально необходимый образ, т.к. в ресурсах мы ограничены.
Думал, что лучше использовать terraform&ansible или docker-machine. Остановился
на втором, т.к. образ меньше, стартует быстрее, да и удаленная машина у нас одна,
без инфраструктуры, как таковой.

Кнопку `stop` также сделал. При реализации использовать `cache`-хост, соззданный
в предыдущей ДЗ, чтобы передавать бинарник `docker-machine` и его кэш из задания
деплоя приложения в задание по уничтожению окружения.

Commit-ов мало, т.к. делал все сначало в темповой ветке, чтобы не засорять основную.

UPD. переделал, чтобы VM создавался только 1 раз для ветки.

# Homework-19 Docker-6

Создаем правило в firewall-е для разрешения входящих соединений на порта 80 и 443
с тегом `gitlabci`.

UPD. добавил еще одно правило для коннекта на 2222-й порт.

Создаем gitlab хост
```
docker-machine create --driver google -google-project docker-193319  \
    --google-zone europe-west1-b --google-machine-type n1-standard-1 \
    --google-disk-size "100" --google-tags gitlabci --google-machine-image \
    $(gcloud compute images list --filter ubuntu-1604-lts --uri) \
    gitlab-ci
```
смотрим, что хост появился `docker-machine ls`

далаем его текущим `eval $(docker-machine env gitlab-ci)`

Docker на нашем сервере появился автоматически, т.к. установку делали с помощью
`docker-machine`. Docker-compose пришлось доустановить.

Подключаемся по ssh к машине gitlabci `docker-machine ssh gitlabci`.

Добавляем текущего пользователя в группу `docker`. Создаем директории и файл
`docker-compose.yml`.

Запускаем наш контейнер `docker-compose up -d`.

Запускаем gitlab runner:
```
docker run -d --name gitlab-runner --restart always \
    -v /srv/gitlab-runner/config:/etc/gitlab-runner \
    -v /var/run/docker.sock:/var/run/docker.sock \
    gitlab/gitlab-runner:latest
```
Регистриуем gitlab runner:
```
docker exec -it gitlab-runner gitlab-runner register
```

Для сохранения пароля к http запросам git-а можно использовать credential helper:
```
git config --global credential.helper "cache --timeout=3600"
```

## Задание *

Интеграция c slack настроена по гайду в самом slack-е
https://devops-team-otus.slack.com/services/B7LR04ZTN#service_setup
Результат работы можно посмотреть в канале #andrey-susoev

Для масштабирования оптимальным вариантом мне показалось использование
autoscale runner-а, появившегося в gitlab 11.

Предварительно в GCE необходимо создать сервисный аккаунт, скачать json-файл
авторизации, залить его на docker-хост (gitlab-ci) машину.

Я следовал этим гайдам:
- https://docs.gitlab.com/runner/install/autoscaling.html
- https://docs.gitlab.com/runner/configuration/autoscale.html

Дописал под него docker-compose файл:
```
web:
  image: 'gitlab/gitlab-ce:latest'
  restart: always
  hostname: 'gitlab.example.com'
  environment:
    GITLAB_OMNIBUS_CONFIG: |
      external_url 'http://35.195.210.5'
  ports:
    - '80:80'
    - '443:443'
    - '2222:22'
  volumes:
    - '/srv/gitlab/config:/etc/gitlab'
    - '/srv/gitlab/logs:/var/log/gitlab'
    - '/srv/gitlab/data:/var/opt/gitlab'

registry:
  image: registry:2
  restart: always
  environment:
    REGISTRY_PROXY_REMOTEURL: https://registry-1.docker.io
  ports:
    - '6000:5000'

cache:
  image: minio/minio:latest
  restart: always
  ports:
    - '9005:9000'
  volumes:
    - '/.minio:/root/.minio'
    - '/export:/export'
  command: ["server", "/export"]

runner:
  image: 'gitlab/gitlab-runner:latest'
  restart: always
  environment:
    - GOOGLE_APPLICATION_CREDENTIALS=/etc/gitlab-runner/gce.json
  volumes:
    - '/srv/gitlab/runnercfg:/etc/gitlab-runner'
```

После запуска runner-а, его необходимо проинициализировать, как в базовой части ДЗ,
затем выключить и полученный конфигурационный файл отредактировать и запустить снова.

Сам конфиг runner-а:
```
concurrent = 5
check_interval = 0

[[runners]]
  name = "auto-scale-runner"
  url = "http://GITLAB-IP"
  token = "PRIVATE_TOKEN"
  executor = "docker+machine"
  [runners.docker]
    tls_verify = false
    image = "alpine:latest"
    privileged = false
    disable_cache = false
    volumes = ["/cache"]
    shm_size = 0
  [runners.cache]
    Type = "s3"
    ServerAddress = "GITLAB-IP:9005"
    AccessKey = "AccessKey"
    SecretKey = "SecretKey"
    BucketName = "runner"
    Insecure = true
  [runners.machine]
    IdleCount = 0
    IdleTime = 300
    MachineDriver = "google"
    MachineName = "gitlab-runner-%s"
    MachineOptions = [
      "google-project=docker-XXXXXX",
      "google-machine-type=g1-small",
      "google-machine-image=ubuntu-os-cloud/global/images/ubuntu-1604-xenial-v20180126",
      "google-tags=default-allow-ssh",
      "google-preemptible=true",
      "google-zone=europe-west1-b",
      "google-use-internal-ip=true"
    ]
    OffPeakTimezone = ""
    OffPeakIdleCount = 0
    OffPeakIdleTime = 0
```

Конфиг, конечно, не оптимальный. Выставлял маленький тайм-аут для того, чтобы
убедиться, что VM удаляются. Ну и надо было ограничить количество VM, т.к. в
одном регионе GCE нельзя больше 8 CPU использовать.

# Homework-17 Docker-4

## Базовая часть
```
docker run --network none --rm -d --name net_test \
        joffotron/docker-net-tools -c "sleep 100"
docker run --network host --rm -d --name net_test \
        joffotron/docker-net-tools -c "sleep 100"
```

- стр. 11 - выводы одинаковые, т.к. контейнер выполняется в сетевыи драйвером host

- стр. 12 - запущен 1 контейнер nginx, т.к. `network = host`, а 80-й порт у нас один.

- стр. 13 - если контейнер запускается с сетевым драйвером хоста, новый сетевой
namespace не создается. Если в драйвером none, то создается новый namespace.

```
docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db mongo:latest
docker run -d --network=reddit --network-alias=post andywow/post:1.1
docker run -d --network=reddit --network-alias=comment andywow/comment:2.1
docker run -d --network=reddit -p 9292:9292 andywow/ui:5.3
```

создаем сети
```
docker network create back_net —subnet=10.0.2.0/24
docker network create front_net --subnet=10.0.1.0/24
```

подключаем контейнеры к сетям
```
docker network connect front_net <container_id> --alias comment
docker network connect front_net <container_id> --alias post
```

- на стр. 24 надо нашего пользователя `docker-user` добавить в группу `docker`

- стр. 35 - файл с переменными окружения должен называться `.env`

- стр. 36 - базовое имя проекта задается переменной окружения
`COMPOSE_PROJECT_NAME` или флагом `-p` в вызове утилиты.

## Задание *

Предварительо скопируем требуемые файлы приложений на `docker-host`:

```
docker-machine scp -r ./post-py docker-user@docker-host:/apps
docker-machine scp -r ./ui docker-user@docker-host:/apps
docker-machine scp -r ./comment docker-user@docker-host:/apps
```
либо смонтировать удаленную директорию хоста командой `docker-machine mount`

Далее монитруем volume-ы в каталоги `/app` контейнеров и изменяем строчку запуска
директивой `command` (посмотреть, что она изменилась, можно командой
  `docker-compose ps`)

# Homework-16 Docker-3

## Базовая часть
Начнем с Dockerfile для `post-py`. Смотрел на слайд, думал заменить ADD на COPY,
а мне IDE это сама выдает во всплывающей подсказке ;) Плюс на слайде дубляж
установки библиотек, которые уже есть в reauirements.txt.

С Dockerfile для `comment` таже история.

Восопльзовался linter-ом - куча полезных комментов
- использование `--no-install-recommends` для уменьшения размера образа
- удаление закшеированных пакетов

Нашел ещё web-линтер https://www.fromlatest.io/ , если обычный нет возможности установить.

После сравнений до и после оптимизаций линтераЮ разница в образах `comment` и `ui`
получилась ~ 10 Мб.

Сборка `ui` началась не с первого шага, т.к. несколько слоев уже были в кеше после
сборки образа `comment`.

```
docker network create reddit
docker run -d --network=reddit --network-alias=post_db \
              --network-alias=comment_db mongo:latest
docker run -d --network=reddit --network-alias=post andywow/post:1.0
docker run -d --network=reddit --network-alias=comment andywow/comment:1.0
docker run -d --network=reddit -p 9292:9292 --network-alias=ui andywow/ui:1.0
```

## Задание *

```
docker run -d --network=reddit --network-alias=docker_post_db \
              --network-alias=docker_comment_db mongo:latest
docker run -d --network=reddit --network-alias=docker_post \
              -e POST_DATABASE_HOST=docker_post_db andywow/post:1.0
docker run -d --network=reddit --network-alias=docker_comment \
              -e COMMENT_DATABASE_HOST=docker_comment_db andywow/comment:1.0
docker run -d --network=reddit -p 9292:9292 --network-alias=ui \
              -e COMMENT_SERVICE_HOST=docker_comment \
              -e POST_SERVICE_HOST=docker_post andywow/ui:1.0
```

Изменение сервиса `ui` - после смены базового образа на `ubuntu`, размер образа
уменьшился до 391 Мб (Dockerfile переименовал в `Dockerfile_ubuntu`).

Далее продолжил эксперимент с `alpine` получилось ужать образ до 203 Мб. Стоит
добавить, что наверно ruby-json стоит включить в `Gemfile` для проекта, т.к. иначе
при старте приложение падает. `apk del .build` оставил, хотя, как я понял, он
все равно удаляется при остановке контейнера сборки.

Ну и наконец, решил поэкспериментировать с `BUILDON` - 5-я версия UI образа вышла
в 36 Мб. Конечно я криво копировал библиотеки ruby, но в ruby я не силен, буду
рад подсказке, как это делать правильно.

Вообщем, что получилось в итоге

```
REPOSITORY            TAG                 IMAGE ID            CREATED             SIZE
andywow/ui            5.0                 a877ea0ba920        9 minutes ago       36.4MB
andywow/post          1.1                 4e0ab14c7285        5 hours ago         102MB
andywow/comment       2.1                 b3dfb77f5638        5 hours ago         195MB
andywow/comment       2.0                 97e29a6d3ba7        5 hours ago         195MB
andywow/comment       1.1                 7f1ba95bdd63        5 hours ago         757MB
andywow/ui            4.0                 8388c1b3d439        16 hours ago        203MB
andywow/ui            4.1                 310cbd064525        16 hours ago        203MB
andywow/ui            3.0                 92bb0cac58b7        17 hours ago        203MB
andywow/ui            2.0                 fd6fe5c32d60        37 hours ago        391MB
andywow/ui            1.0                 3874e2057405        38 hours ago        764MB
andywow/comment       1.0                 6faf20076458        38 hours ago        757MB
andywow/post          1.0                 2c2c364e9c99        38 hours ago        102MB
```

UPD. добавил директиву `ARG` вместо `ENV` для использования переменной только на
стадии сборки.

```
docker tag andywow/ui:5.4 andywow/ui:latest
docker tag andywow/post:1.1 andywow/post:latest
docker tag andywow/comment:2.1 andywow/comment:latest
```

Запуск БД с подключенным volume:

```
docker run -d --network=reddit --network-alias=docker_post_db \
            -v reddit_db:/data/db
            --network-alias=docker_comment_db mongo:latest
```

# Homework-15 docker-2

Что было сделано:
- создан новые проекс в GCE c именем `docker` и установлен в качестве рабочего проекта
```
gcloud init
```
- Создали VM docker-host
```
docker-machine create --driver google -google-project docker-193319 \
--google-zone europe-west1-b --google-machine-type g1-small \
--google-machine-image \
$(gcloud compute images list --filter ubuntu-1604-lts --uri) \
docker-host
```
- Работаем с docker клиентом
```
# список docker VM
docker-machine ls
# параметры для настройки клиента docker для работы с docker VM
docker-machine env <VM NAME>
# просматриваем активность внутри docker контейнера
docker run --rm -ti tehbilly/htop
# просматриваем активность внутри хоста docker контейнера
docker run --rm --pid host -ti tehbilly/htop
```
- создали Dockerfile с описанием деплоя и запуска mongod и сервиса puma
- сборка и запуск собственного контейнера
```
# собираем образ
docker build -t reddit:latest .
# смотрим список образов
docker images -a
# Запускаем наш контейнер на хосте GCE с сетевым стеком хоста
docker run --name reddit -d --network=host reddit:latest
```
- push контейнера в удаленный репозиторий
```
# делаем тег для нашего образа
docker tag reddit:latest andywow/otus-reddit:1.0
# делаем пуш в удаленный репозиторий
docker push andywow/otus-reddit:1.0
```

# Homework-14 docker-1

## Базовая часть
Небольшой cheatsheet, чтобы не забыть
```
docker info
docker run <image> [--rm] # rm remove image after stop
docker ps
docker ps -a
docker ps -a --format "table {{.ID}}\t{{.Image}}\t{{.CreatedAt}}\t{{.Names}}
docker images
docker run -it <image>:<version> <cmd>
docker run -dt <image>:<version> <cmd>
docker start <container_id>
docker attach <container_id>
# ctrl+p ctrl+q - exit without stop
docker exec -it <container_id> <cmd>
docker commit <u_container_id> <image_name> # create image
docker kill <containerid>
docker stop <containerid>
docker system df
docker rm <image> [-f] # stop & remove
docker rmi <image> # remove if no depencies
```

## Задание *
Вывод команды `docker inspect` отличается, т.к. в превом случае мы указываем id
контейнера, а во втором случае id образа контейнера.
Соответственно, в первом случае у нас указываются ресурсы (cpu / net / disk),
которые потребляет контейнер, в т.ч. образ, из которого он создан.
В во втором случае отображается информация об образе, соответственно, отсутсвует
информация о текущем статусе, железе, но присустсвует информация о контейнере,
на базе которого собран это образ. Если проводить аналогию с виртуальными машинами,
то контейнер - это VM, а image - шаблон VM.

