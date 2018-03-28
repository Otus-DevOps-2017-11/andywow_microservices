# Homework-30 kubernetes-3

## Базовая часть

Смотрим, как работает `kube-dns`:
```
# отключаем kube-dns и его autoscaler
➜  terraform git:(kubernetes-3) ✗ kubectl scale deployment --replicas 0
-n kube-system kube-dns-autoscaler
➜  terraform git:(kubernetes-3) ✗ kubectl scale deployment --replicas 0
-n kube-system kube-dns
# смотрим, что dns перестал работать
➜  terraform git:(kubernetes-3) ✗ kubectl exec -ti -n dev ui-8555b89475-fwnxt
nslookup comment
nslookup: can't resolve '(null)': Name does not resolve

nslookup: can't resolve 'comment': Try again
command terminated with exit code 1
# Возвращаем назад
➜  terraform git:(kubernetes-3) ✗ kubectl scale deployment --replicas 1 -n kube-system kube-dns-autoscaler
➜  terraform git:(kubernetes-3) ✗ kubectl exec -ti -n dev ui-8555b89475-fwnxt nslookup comment
nslookup: can't resolve '(null)': Name does not resolve

Name:      comment
Address 1: 10.63.247.110 comment.dev.svc.cluster.local
```

Для приложения `ui` сменили тип сервиса на `LoadBalancer` - успешно работает,
приложение доступно по `80`-му порту.

При конфигурации `Ingress`-а время ожидания применения конфигурации варьировалось
от 30 секунд до 3-х минут. Жалко, что нигде не отображается статус
`Configuring...`, например. Можно понять только на web-странице, когда
`Healthy`-стутус у instance-групп будет полностью готов.

Сделал самодописанный сертификат и загрузили его в кластер:
```
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=35.186.254.104"
kubectl create secret tls ui-ingress --key tls.key --cert tls.crt -n dev
```

Протокол `http` автоматически не удалился. Пересоздал `ingress`:
```
kubectl delete ingress ui -n dev
```


# Homework-29 kubernetes-2

## Базовая часть

Установили `kubectl` и `minikube`. Стартовал `minikube` на локальной машине:
```
export MINIKUBE_WANTUPDATENOTIFICATION=false
export MINIKUBE_WANTREPORTERRORPROMPT=false
export MINIKUBE_HOME=$HOME
export CHANGE_MINIKUBE_NONE_USER=true
mkdir $HOME/.kube || true
touch $HOME/.kube/config

export KUBECONFIG=$HOME/.kube/config
sudo -E minikube start --vm-driver=none
```

Задеплоили `ui-deployment`:

```
➜  kubernetes git:(kubernetes-2) ✗ kubectl apply -f ui-deployment.yml        
deployment "ui" created
➜  kubernetes git:(kubernetes-2) ✗ kubectl get deployment
NAME      DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
ui        3         3         3            3           21s
➜  kubernetes git:(kubernetes-2) ✗ kubectl get pods --selector component=ui
NAME                 READY     STATUS    RESTARTS   AGE
ui-b8d87b496-hndq7   1/1       Running   0          2m
ui-b8d87b496-nvrw2   1/1       Running   0          2m
ui-b8d87b496-tql5r   1/1       Running   0          2m
```

После попытки `port-forwarding` столкнулся с проблемой, что должен быть
установлен пакет `socat`. После установки перенаправление портов заработало.
Но начала падать сеть моей VM, в которой я делаю ДЗ. И тут я сделал то,
с чем разбирался потом несколько
часов. В настройках VM я сменил тип сети с `NAT` на `Bridge`. После этого DNS
в kubernetes-кластере просто перестал работать - pod-ы не видели друг друга по
имени. Посмотрев статус системных подов,
```
kubectl get pods --namespace kube-system
```
я увидел, что `kube-dns` постоянно перезапускается. Посмотрев логи убитых
контейнеров я увидел записи вида:
```
I0322 19:22:16.466054       1 nanny.go:108] dnsmasq[11]: Maximum number of concurrent DNS queries reached (max: 150)
I0322 19:22:23.886621       1 nanny.go:108] dnsmasq[11]: Maximum number of concurrent DNS queries reached (max: 150)
```
Нашел, что я неединственный такой: https://github.com/kubernetes/minikube/issues/2027
и выполнил work-around:
```
nameserver -> 8.8.8.8

sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved
```
После перезапуска кластера, все стало видно. Но шел я к этому очень долго.

Далее возникли проблемы с взаимодействим сервисов `ui` и `post`. Путем
экспериментов собрал последние образа с использование `zipkin`, но в сервисе
`post` закоментировал обращение к нему, т.к. не смог понять, почему он
неправильно формирует строку обращения.

Из-за того, что пришлось разбираться с проблемой взаимодействия, порядок выполнения
ДЗ немного нарушился - попробовал в GKE все задеплоить, чтобы убедиться, что
проблема не в `minikube`.

Итоговый список команд, который использовался (опишу, дабы не забыть)
```
sudo -E minikube start --vm-driver=none
sudo minikube stop
sudo minikube delete
kubectl config get-contexts
kubectl config use-context minikube
kubectl get pods
kubectl get services
kubectl get deployment
kubectl get namespace
kubectl apply -f ./ [-n namespace]
kubectl delete -f ./
kubectl logs <pod-id>
kubectl logs deployment/ui
kubectl exec -it <podid> sh
kubectl describe service <service_name
kubectl port-forward <pod_id> 8080:9292>
minikube service ui
minikube addons list
minikube addons enable dashboard
```

Для GKE был создан кластер сначало руками, а затем с использование
[terraform](./kubernetes/terraform).

При работе с GKE сервис аккаунт для панели управления у меня создался
автоматически (при развертывании руками и через `terraform`). дополнительно
создавать не пришлось. YAML-конфигурацию для дашборда тоже не пришлось менять,
нужные записи уже были там. А вот назначение роли приложения пришлось сделать:
```
kubectl create clusterrolebinding kubernetes-dashboard  \
  --clusterrole=cluster-admin \
  --serviceaccount=kube-system:kubernetes-dashboard
```

## Задание *

`terraform` конфигурация находится в папке: [terraform](./kubernetes/terraform)

`yaml` манифесты находятся в папке [gke_yml](./kubernetes/gke_yml).

Экспортировать их можно командами:
```
kubectl get sa kubernetes-dashboard -n kube-system -o yaml
kubectl get clusterrolebinding kubernetes-dashboard -n kube-system -o yaml
```

Добавил описание для [kubernetes secret](./kubernetes/reddit/ui-ingress-secret.yml)

Включаем `Network Policy` в `GKE`:
```
gcloud beta container clusters update cluster-1 --zone=europe-west1-b --update-addons=NetworkPolicy=ENABLED
gcloud beta container clusters update cluster-1 --zone=europe-west1-b --enable-network-policy
```


# Homework-28 kubernetes-1

## Базовая часть

Описание деплоя `kubernetes` по гайду `the hard way` я думаю нет смыслы делать -
в мануале все очень подробно описано и не требует каких либо шагов в сторону.

Деплой наших деплойментов проверил на созданном кластере:

```
➜  kubernetes_the_hard_way git:(kubernetes-1) ✗ kubectl apply -f ../comment-deployment.yml
deployment "comment-deployment" configured
➜  kubernetes_the_hard_way git:(kubernetes-1) ✗ kubectl get pods -l app=comment
NAME                                  READY     STATUS    RESTARTS   AGE
comment-deployment-699f79f68c-5p6lv   1/1       Running   0          54s
```


# Homework-27 swarm-1

## Базовая часть

Сделали 3 VM для swarm-кластера - 1 master и 2 worker-а.

```
docker-machine create --driver google \
   --google-project  docker-XXXXXX  \
   --google-zone europe-west1-b \
   --google-machine-type g1-small \
   --google-machine-image $(gcloud compute images list --filter ubuntu-1604-lts --uri) \
   master-1
```

Проинициализировали swarm-кластер на master-е
```
docker swarm init
```
Ввели worker-ы в кластер
```
docker swarm join --token MY-TOKEN 10.132.0.6:2377
```
Проверили, что все узлы активны
```
➜  docker git:(swarm-1) ✗ docker node ls
ID                            HOSTNAME            STATUS              AVAILABILITY        MANAGER STATUS
xbw9110t3fdax1l8cb5audm89 *   master-1            Ready               Active              Leader
vnkkdygops3b25ns31958knpb     worker-1            Ready               Active              
l36wlz9ll76k9enlsfr0biakx     worker-2            Ready               Active              
```
Деплоим наши сервисы:
```
docker stack deploy --compose-file=<(docker-compose -f docker-compose.yml config 2>/dev/null) DEV
```
Смотрим результат деплоя стека:
```
➜  docker git:(swarm-1) ✗ docker stack services DEV
ID                  NAME                MODE                REPLICAS            IMAGE                    PORTS
alg1014kowz2        DEV_comment         replicated          1/1                 andywow/comment:latest   
ctzlrdnjy946        DEV_post            replicated          1/1                 andywow/post:latest      
oz43yjbdzquh        DEV_post_db         replicated          1/1                 mongo:3.2                
zf5e1zlzgmok        DEV_ui              replicated          1/1                 andywow/ui:latest        *:9292->9292/tcp
```
Устанавливаем метки узлам и смотрим их:
```
docker node update --label-add reliability=high master-1
docker node ls -q | xargs docker node inspect  -f '{{ .ID }} [{{ .Description.Hostname }}]: {{ .Spec.Labels }}'
```
В `docker-compose.yml` файле установили опцию деплоя сервисов по меткам и
передеплоили сервисы.

У меня возникли проблемы с деплоем сервисов, для себя понял, что смотреть логи
сервиса можно командой
```
docker service logs <SERVICE_NAME>
```
Деплоим наши сервисы и смотрим, где они расположились
```
docker stack deploy --compose-file=<(docker-compose -f docker-compose.yml config 2>/dev/null) DEV
docker stack ps DEV
```
Далее мы увеличили количество реплик для сервисов до двух (кроме БД) и
задеплоили снова. Видим, что количество реплик увеличилось
```
➜  docker git:(swarm-1) ✗ docker stack services DEV                                                                        
ID                  NAME                MODE                REPLICAS            IMAGE                    PORTS
1yeyq483ueej        DEV_comment         replicated          2/2                 andywow/comment:latest   
ql4t2a31vd13        DEV_post_db         replicated          1/1                 mongo:3.2                
u182tagxakwk        DEV_post            replicated          2/2                 andywow/post:latest      
x553ddogx57m        DEV_ui              replicated          2/2                 andywow/ui:latest        *:9292->9292/tcp
```

Добавили в кластер еще 1 worker:

```
docker-machine create --driver google \                                                                                           
   --google-project  docker-XXXXXX  \
   --google-zone europe-west1-b \
   --google-machine-type g1-small \
   --google-machine-image $(gcloud compute images list --filter ubuntu-1604-lts --uri) \
   worker-3
...
docker swarm join --token XXXXXXX 10.132.0.6:2377
...
➜  docker git:(swarm-1) ✗ docker node ls                     
ID                            HOSTNAME            STATUS              AVAILABILITY        MANAGER STATUS
xbw9110t3fdax1l8cb5audm89 *   master-1            Ready               Active              Leader
vnkkdygops3b25ns31958knpb     worker-1            Ready               Active              
l36wlz9ll76k9enlsfr0biakx     worker-2            Ready               Active              
4fwuzlwtojyeh1oq5ceblujgj     worker-3            Ready               Active
```
Автоматически запустилось на 3-м worker-е только `node-exporter`
```
➜  docker git:(swarm-1) ✗ docker stack ps DEV                                                                                                               
ID                  NAME                                          IMAGE                                  NODE                DESIRED STATE       CURRENT STATE            ERROR                       PORTS
2ur03h6m8bdh        DEV_node-exporter.4fwuzlwtojyeh1oq5ceblujgj   prom/node-exporter:latest              worker-3            Running             Running 2 minutes ago
...
```
увеличили количество реплик до трех и передеплоили. На 3-м worker-е дополнительно
запустились `ui`, `post` и `comment` сервисы.

Добавили поддержку `rolling update` для сервисов.
Настроили ограничение по ресурсам для контейнеров и политики перезапуска, в
случае падения.

Файл `docker-compose-monitoring.yml` был создан в рамках предыдущего ДЗ.



## Задание ***

Первое, что пришло в голову - параметризировать все порты сервисов и версии
docker image-й. Это  было не ошибочно, т.к. не до конца разобрался с сетевыми
драйверами. В итоге параметризируем только порты сервисов, которые выносим
наружу.

Далее появился вопрос: как передавать `.env` файл для разных окружений.
В результате раздумий для деплоя доработал `Makefile` из предыдущих ДЗ ;)

Для его выполнения были созданы 2 файла `.env_STAGE` и `.env_DEV`
(STAGE и DEV - имена соответствующих окружений)

Пример выполнения скрипта (большой листинг):

```
➜  andywow_microservices git:(swarm-1) ✗ make -e STACKS=STAGE deploy
Deploying stacks
Updating service STAGE_mongodb-exporter (id: f3ep00ed1i0zi07ks5vul6f7m)
Updating service STAGE_stackdriver-exporter (id: tzgf1c1wn8nzkb5aef9dba1j5)
Updating service STAGE_alertmanager (id: kugkxe6s7tpudymeieqy24iq8)
Updating service STAGE_node-exporter (id: uepst9jcgf5savx7tpx50zuma)
Updating service STAGE_post_db (id: i463x5buxqasp2ypjuwjxxp9p)
Updating service STAGE_comment (id: k6hksh0bqbth3mgpr7m62zfna)
Updating service STAGE_grafana (id: kk4r3otvggoh48jq7q5b2nmu9)
Updating service STAGE_post (id: uzdphp5firc3hwkzpo3unmum1)
Updating service STAGE_blackbox-exporter (id: jdyhbyzpcq6ze385fjpuxwu0s)
Updating service STAGE_cadvisor (id: 88ce6euuzlnap4ygrm8n92vh1)
Updating service STAGE_prometheus (id: q7ed8vtp1c7wx5f92gwbqeaoj)
Updating service STAGE_ui (id: bdfkwdbx3etkhzny5fru94p2s)
➜  andywow_microservices git:(swarm-1) ✗ make -e STACKS=DEV deploy  
Deploying stacks
Updating service DEV_cadvisor (id: i3g06oetpzh0teg0gzgg2lake)
Updating service DEV_post (id: efywfi6eg8f4vuw0vuomh00z2)
Updating service DEV_comment (id: qx2ffxnb2f2unw8fliz55qbkb)
Updating service DEV_node-exporter (id: hwe623s9irgu1kfdzr0y48vef)
Updating service DEV_post_db (id: zcby4yuagqwmcrnz2dwsjmrjf)
Updating service DEV_grafana (id: aptuaab7ly4fzwskpzjdj9q5i)
Updating service DEV_stackdriver-exporter (id: frhm7vnqd0bqupbxi9109wln1)
Updating service DEV_blackbox-exporter (id: z92m9as8zdd0tc9thf9gg9vpi)
Updating service DEV_ui (id: vu43b1gclwxsetsm3pcfxvgr3)
Updating service DEV_mongodb-exporter (id: z0i8gmjw84t9v67dgjmgwiw9c)
Updating service DEV_alertmanager (id: 8cs96rswxu7j9prjo7szlb7ek)
Updating service DEV_prometheus (id: 5p82y3156760rzu6zd6e7btl4)
➜  andywow_microservices git:(swarm-1) ✗ docker stack services STAGE                                                                                                       
ID                  NAME                         MODE                REPLICAS            IMAGE                                  PORTS
88ce6euuzlna        STAGE_cadvisor               global              4/4                 google/cadvisor:v0.29.0                
bdfkwdbx3etk        STAGE_ui                     replicated          3/3                 andywow/ui:latest                      *:9293->9292/tcp
f3ep00ed1i0z        STAGE_mongodb-exporter       replicated          1/1                 andywow/mongodb_exporter:latest        
i463x5buxqas        STAGE_post_db                replicated          1/1                 mongo:3.2                              
jdyhbyzpcq6z        STAGE_blackbox-exporter      replicated          1/1                 prom/blackbox-exporter:latest          
k6hksh0bqbth        STAGE_comment                replicated          3/3                 andywow/comment:latest                 
kk4r3otvggoh        STAGE_grafana                replicated          1/1                 andywow/grafana:latest                 *:3001->3000/tcp
kugkxe6s7tpu        STAGE_alertmanager           replicated          1/1                 andywow/alertmanager:latest            
q7ed8vtp1c7w        STAGE_prometheus             replicated          1/1                 andywow/prometheus:latest              *:9091->9090/tcp
tzgf1c1wn8nz        STAGE_stackdriver-exporter   replicated          1/1                 frodenas/stackdriver-exporter:latest   
uepst9jcgf5s        STAGE_node-exporter          global              4/4                 prom/node-exporter:latest              
uzdphp5firc3        STAGE_post                   replicated          3/3                 andywow/post:latest
➜  andywow_microservices git:(swarm-1) ✗ docker stack services DEV   
ID                  NAME                       MODE                REPLICAS            IMAGE                                  PORTS
5p82y3156760        DEV_prometheus             replicated          1/1                 andywow/prometheus:latest              *:9090->9090/tcp
8cs96rswxu7j        DEV_alertmanager           replicated          1/1                 andywow/alertmanager:latest            
aptuaab7ly4f        DEV_grafana                replicated          1/1                 andywow/grafana:latest                 *:3000->3000/tcp
efywfi6eg8f4        DEV_post                   replicated          3/3                 andywow/post:latest                    
frhm7vnqd0bq        DEV_stackdriver-exporter   replicated          1/1                 frodenas/stackdriver-exporter:latest   
hwe623s9irgu        DEV_node-exporter          global              4/4                 prom/node-exporter:latest              
i3g06oetpzh0        DEV_cadvisor               global              4/4                 google/cadvisor:v0.29.0                
qx2ffxnb2f2u        DEV_comment                replicated          3/3                 andywow/comment:latest                 
vu43b1gclwxs        DEV_ui                     replicated          3/3                 andywow/ui:latest                      *:9292->9292/tcp
z0i8gmjw84t9        DEV_mongodb-exporter       replicated          1/1                 andywow/mongodb_exporter:latest        
z92m9as8zdd0        DEV_blackbox-exporter      replicated          1/1                 prom/blackbox-exporter:latest          
zcby4yuagqwm        DEV_post_db                replicated          1/1                 mongo:3.2
```

Попробовал указывать файл конфига внутри `docker-compose` файла

```
env_file:
  - ./Docker/api/api.env
```
но, как я понял, он отвечает за передачу переменных внутрь контейнера, а не
`docker-compose` файла

# Homework-25 Logging-1

## Базовая часть

Обновили код микросервисов, пришлось пофиксить код и зависимости, изменить
`Dockerfile`-ы у образов.

Создали новую VM. Развернули в ней стек `EFK` и наши микросервисы.

Настроили передачу логов из сервисов в `fluentd` и далее в `elasticsearch`.

Настроили парсинг json-логов сервиса `post` и неструктурированных логов
сервиса `ui` (grok).

Настроили pattern для поиска по индексу в `kibana`.

Настроили сервис `zipkin` для просмотра распределенного трейсинга.
Для сервиса `post` пришлось изменить версию `python` на `2.7` - иначе трассировка
`zypkin` не работала (на сайте заявлена поддержка `3.6`, но у меня не сработала).

## Задание *

grok-парсер настроен.

`bugged` приложение тормозило потому, что в его коде есть строчка с
зашитым таймаутом

```
time.sleep(3)
```

# Homework-23 Monitoring-2

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

## Задание *

`Makefile` доработан.

Забор метрик из `Dockerfile`-а:

На docker-хосте `vm1` создан файл `/etc/docker/daemon.json`:
```
{
  "metrics-addr" : "0.0.0.0:9323",
  "experimental" : true
}
```
docker-демон был перезапущен.

После этого добавлена запись о docker-хосте в `prometheus.yml` и пересобран
образ `prometheus`.

На сайте prometheus нашел 2 утилиты для валидации конфигов `prometheus` и
`alertmanager`:

```
go get github.com/prometheus/prometheus/cmd/promtool
go get github.com/prometheus/alertmanager/cmd/amtool
```

Алертинг по email-у настроен.

## Задание **

Пришлось сделать отдельный образ для `grafana` и в него копировать наш datasource
и дашборды. Пришлось забить в параметры дашбордов железно имя источника, т.к.
динамически они передавать пока еще не научили:

https://github.com/grafana/grafana/issues/10786

Добавил интеграцию со `stackdriver` - использовал образ
https://github.com/frodenas/stackdriver_exporter

Собрал, указанные в дефолтовом примере: загрузка cpu, кол-во ядер, кол-во информации,
записанной на диск.

В приложение `post-py` добавил простенькую метрику, которая считает количество vote-ов для
постов.

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

