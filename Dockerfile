ARG APP_ROOT=/src/app
ARG RUBY_VERSION=2.3.8

FROM ruby:${RUBY_VERSION}-alpine AS gem
ARG APP_ROOT

RUN apk add --no-cache build-base postgresql-dev gcompat git

RUN mkdir -p ${APP_ROOT}
COPY Gemfile Gemfile.lock ${APP_ROOT}/

ENV BUNDLE_GITLAB__COM=${GITLAB_TOKEN_NAME}:${GITLAB_TOKEN_TOKEN}

WORKDIR ${APP_ROOT}
RUN gem install bundler:2.3.27 \
    && bundle config --local deployment 'true' \
    && bundle config --local frozen 'true' \
    && bundle config --local no-cache 'true' \
    && bundle config --local without 'development test' \
    && bundle install \
    && find ${APP_ROOT}/vendor/bundle -type f -name '*.c' -delete \
    && find ${APP_ROOT}/vendor/bundle -type f -name '*.h' -delete \
    && find ${APP_ROOT}/vendor/bundle -type f -name '*.o' -delete \
    && find ${APP_ROOT}/vendor/bundle -type f -name '*.gem' -delete

FROM ruby:${RUBY_VERSION}-alpine
ARG APP_ROOT

RUN apk add --no-cache curl imagemagick shared-mime-info tzdata postgresql-libs pkgconf pkgconf-dev poppler-utils mupdf-tools nodejs
RUN cp /usr/share/zoneinfo/Asia/Taipei /etc/localtime

COPY --from=gem /usr/local/bundle/config /usr/local/bundle/config
COPY --from=gem /usr/local/bundle /usr/local/bundle
COPY --from=gem ${APP_ROOT}/vendor/bundle ${APP_ROOT}/vendor/bundle

RUN mkdir -p ${APP_ROOT}

ENV RAILS_ENV=production
ENV RAILS_LOG_TO_STDOUT=true
ENV RAILS_SERVE_STATIC_FILES=yes
ENV APP_ROOT=$APP_ROOT

COPY . ${APP_ROOT}

ARG REVISION
ENV REVISION $REVISION
ENV COMMIT_SHORT_SHA $REVISION
RUN echo "${REVISION}" > ${APP_ROOT}/REVISION

ARG SENTRY_RELEASE
ENV SENTRY_RELEASE $SENTRY_RELEASE

# Apply Execute Permission
RUN adduser -h ${APP_ROOT} -D -s /bin/nologin ruby ruby && \
    chown ruby:ruby ${APP_ROOT} && \
    chown -R ruby:ruby ${APP_ROOT}/log && \
    chown -R ruby:ruby ${APP_ROOT}/tmp && \
    chmod -R +r ${APP_ROOT}

RUN chown -R ruby:ruby ${APP_ROOT}

USER ruby
WORKDIR ${APP_ROOT}

RUN bundle exec rake assets:precompile

EXPOSE 3000
HEALTHCHECK CMD curl -f http://localhost:3000/status || exit 1
ENTRYPOINT ["bin/entrypoint"]
CMD ["server"]
