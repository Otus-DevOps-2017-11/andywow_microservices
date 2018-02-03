FROM alpine:3.7 as builder

RUN apk add --no-cache ruby \
                       ruby-json \
                       ruby-dev \
                       gcc \
                       make \
                       g++ \
                       ruby-bundler

RUN mkdir /tmp/build
WORKDIR /tmp/build

COPY Gemfile* /tmp/build/
RUN bundle install --standalone

###

FROM alpine:3.7

RUN apk add --no-cache ruby ruby-json

ENV APP_HOME /app
WORKDIR $APP_HOME
COPY . "$APP_HOME"
COPY --from=builder /tmp/build/bundle/ruby/*/bin/* /usr/local/bin/
COPY --from=builder /tmp/build/bundle/ruby /usr/lib/ruby/gems/

ENV COMMENT_SERVICE_HOST=comment \
    COMMENT_SERVICE_PORT=9292 \
    POST_SERVICE_HOST=post \
    POST_SERVICE_PORT=5000

CMD ["puma"]
