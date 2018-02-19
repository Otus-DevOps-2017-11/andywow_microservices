FROM alpine:3.7

RUN apk add --no-cache ruby ruby-json && \
    apk add --no-cache --virtual .build ruby-dev \
                                        gcc \
                                        make \
                                        g++ \
                                        ruby-bundler

ENV APP_HOME /app
RUN mkdir "$APP_HOME"
WORKDIR $APP_HOME

COPY Gemfile* "$APP_HOME"/
RUN bundle install && apk del .build
COPY . "$APP_HOME"

ENV COMMENT_DATABASE_HOST=comment_db \
    COMMENT_DATABASE=comments

CMD ["puma"]
