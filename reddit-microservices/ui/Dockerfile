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

ENV COMMENT_SERVICE_HOST  comment
ENV COMMENT_SERVICE_PORT  9292
ENV POST_SERVICE_HOST     post
ENV POST_SERVICE_PORT     5000

CMD ["puma"]
