FROM node:16-alpine

ARG target=test:hh

RUN apk add yarn && apk add git

COPY ./package.json ./package.json
RUN yarn

COPY . .
RUN yarn compile
RUN yarn $target
