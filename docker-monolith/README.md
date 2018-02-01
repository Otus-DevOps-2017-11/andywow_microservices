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
