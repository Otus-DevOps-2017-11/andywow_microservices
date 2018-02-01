# Homework-15 Docker-3

## Базовая часть
Начнем с Dockerfile для `post-py`. Смотрел на слайд, думал заменить ADD на COPY,
а мне IDE это сама выдает во всплывающей подсказке ;) Плюс на слайде дубляж
установки библиотек, которые уже есть в reauirements.txt.

С Dockerfile для `comment` таже история.

Восопльзовался linter-ом - куча полезных комментов
- использование `--no-install-recommends` для уменьшения размера образа
- удаление закшеированных пакетов

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


