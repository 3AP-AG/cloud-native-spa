FROM node:alpine as builder

WORKDIR /app
COPY . /app


# install deps and create build artifact
RUN yarn install --frozen-lockfile
RUN yarn run build

FROM nginx:alpine

RUN apk update && apk add bash

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/build /usr/share/nginx/html
COPY .env.template /
COPY nginx-entrypoint.sh /
COPY scripts/generate-env-file.sh /

ENV PORT 3000
EXPOSE 3000

RUN chmod +x generate-env-file.sh
ENTRYPOINT [ "sh", "/nginx-entrypoint.sh" ]
