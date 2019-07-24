FROM golang:stretch as builder

WORKDIR $GOPATH/src

RUN git clone -b yagpdb https://github.com/jonas747/discordgo github.com/jonas747/discordgo \
  && git clone -b dgofork https://github.com/jonas747/dutil github.com/jonas747/dutil \
  && git clone -b dgofork https://github.com/jonas747/dshardmanager github.com/jonas747/dshardmanager \
  && git clone -b dgofork https://github.com/jonas747/dcmd github.com/jonas747/dcmd

RUN go get -d -v \
  github.com/jonas747/yagpdb/cmd/yagpdb
RUN CGO_ENABLED=0 GOOS=linux go install -v \
  github.com/jonas747/yagpdb/cmd/yagpdb

FROM alpine:latest

WORKDIR /app
VOLUME /app/soundboard \
  /app/cert
EXPOSE 80 443

RUN apk --no-cache add ca-certificates ffmpeg curl su-exec libcap

RUN adduser -D yagpdb
COPY ./docker-entrypoint.sh /app/

# Handle templates for plugins automatically
COPY --from=builder /go/src/github.com/jonas747/yagpdb/*/assets/*.html templates/plugins/

COPY --from=builder /go/src/github.com/jonas747/yagpdb/cmd/yagpdb/templates templates/
COPY --from=builder /go/src/github.com/jonas747/yagpdb/cmd/yagpdb/posts posts/
COPY --from=builder /go/src/github.com/jonas747/yagpdb/cmd/yagpdb/static static/

COPY --from=builder /go/bin/yagpdb .
RUN setcap 'cap_net_bind_service=+ep' /app/yagpdb

ENTRYPOINT [ "/app/docker-entrypoint.sh" ]
CMD [ "/app/yagpdb", "-all", "-pa", "-exthttps=false", "-https=true" ]
