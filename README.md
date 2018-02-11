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

