FROM --platform=$BUILDPLATFORM node:lts as npm

RUN mkdir -p /usr/src/build 
WORKDIR /usr/src/build

ARG NODE_ENV
ENV NODE_ENV $NODE_ENV

COPY install/package.json /usr/src/build/package.json

RUN npm install --omit=dev

FROM node:lts as rebuild

ARG BUILDPLATFORM
ARG TARGETPLATFORM

RUN mkdir -p /usr/src/build

COPY --from=npm /usr/src/build /usr/src/build

RUN if [ $BUILDPLATFORM != $TARGETPLATFORM ]; then \
    npm rebuild && \
    npm cache clean --force; fi

FROM node:lts-slim as run

ARG NODE_ENV
ENV NODE_ENV=$NODE_ENV \
    daemon=false \
    silent=false

RUN mkdir -p /usr/src/app

COPY --from=rebuild /usr/src/build /usr/src/app


WORKDIR /usr/src/app

COPY . /usr/src/app

EXPOSE 4567
VOLUME ["/usr/src/app/node_modules", "/usr/src/app/build", "/usr/src/app/public/uploads", "/opt/config"]
ENTRYPOINT ["./install/docker/entrypoint.sh"]
