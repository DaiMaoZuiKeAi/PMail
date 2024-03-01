FROM node:lts-alpine as febuild
WORKDIR /work

COPY fe .

RUN yarn && yarn build


FROM golang:alpine as serverbuild

WORKDIR /work

COPY server .
COPY --from=febuild /work/dist /work/http_server/dist

RUN apk update && apk add git
RUN go build -ldflags "-X 'main.goVersion=$(go version)' -X 'main.gitHash=$(git show -s --format=%H)' -X 'main.buildTime=$(TZ=UTC-8 date +%Y-%m-%d" "%H:%M:%S)'" -o pmail main.go
RUN cd /work/hooks/telegram_push && go build -ldflags "-s -W" -o output/telegram_push main.go
RUN cd /work/hooks/web_push && go build -ldflags "-s -W" -o output/web_push main.go
RUN cd /work/hooks/wechat_push && go build -ldflags "-s -W" -o output/wechat_push main.go


FROM alpine

WORKDIR /work

# 设置时区
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories
RUN apk add --no-cache tzdata \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone \
    &&rm -rf /var/cache/apk/* /tmp/* /var/tmp/* $HOME/.cache


COPY --from=serverbuild /work/pmail .
COPY --from=serverbuild /work/hooks/telegram_push/output/* ./plugin/
COPY --from=serverbuild /work/hooks/web_push/output/* ./plugin/
COPY --from=serverbuild /work/hooks/wechat_push/output/* ./plugin/

CMD /work/pmail
