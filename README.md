# Homework-15 docker-1

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
