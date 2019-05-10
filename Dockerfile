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

RUN apk --no-cache add ca-certificates ffmpeg curl

# Handle templates for plugins automatically
COPY --from=builder /go/src/github.com/jonas747/yagpdb/*/assets/*.html templates/plugins/

COPY --from=builder /go/src/github.com/jonas747/yagpdb/cmd/yagpdb/templates templates/
COPY --from=builder /go/src/github.com/jonas747/yagpdb/cmd/yagpdb/posts posts/
COPY --from=builder /go/src/github.com/jonas747/yagpdb/cmd/yagpdb/static static/

COPY --from=builder /go/bin/yagpdb .

# `exec` allows us to receive shutdown signals.
CMD exec /app/yagpdb -all -pa -exthttps=$EXTHTTPS -https=$HTTPS
