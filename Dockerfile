FROM ruby:2.1.8

RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" >> /etc/apt/sources.list.d/postgresql.list'

RUN apt-get update && apt-get install -y \
  build-essential \

  # for postgres
  libpq-dev \
  postgresql-client-9.5 \

  # for nokogiri
  libxml2-dev \
  libxslt1-dev \

  # for capybara-webkit Qt4
  libqt4-webkit \
  libqt4-dev \
  xvfb \

  # for capybara-webkit Qt5
  # qt5-default \
  # libqt5webkit5-dev \
  # gstreamer1.0-plugins-base \
  # gstreamer1.0-tools \
  # gstreamer1.0-x \
  # xvfb \

  # for a JS runtime
  # nodejs \
  npm \
  imagemagick \

  # debug tools
  vim

RUN gem install bundler -v 1.16.0
RUN gem install rubocop -v 0.48.0
RUN gem install rubocop-rspec -v 1.15.1

RUN ln -s /usr/bin/nodejs /usr/bin/node
RUN npm install -g n
RUN n 6.9.2
RUN npm install -g bower \
                   phantomjs@1.9.8

ENV APP_HOME /srv/app

ENV CI_REPORTS=shippable/testresults
ENV COVERAGE_REPORTS=shippable/codecoverage

# RUN mkdir $APP_HOME

WORKDIR $APP_HOME

ENV BUNDLE_GEMFILE=$APP_HOME/Gemfile \
    BUNDLE_JOBS=8 \
    BUNDLE_PATH=/bundle_cache
