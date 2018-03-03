FROM python:3.6.0-alpine

RUN apk add --no-cache --virtual .build gcc \
                                        musl-dev

WORKDIR /app
COPY . /app

RUN pip install -r /app/requirements.txt && apk del .build

ENV POST_DATABASE_HOST=post_db \
    POST_DATABASE=posts

CMD ["python3", "post_app.py"]
