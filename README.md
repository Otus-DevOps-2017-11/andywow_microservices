# Homework-15 docker-1

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
