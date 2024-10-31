FROM alpine:3.20

ARG USER=default
ENV HOME /home/$USER
ENV GOROOT /usr/lib/go
ENV GOPATH /go
ENV PATH /go/bin:$PATH

RUN apk update \
    && apk add --no-cache bash sudo go git

RUN go install golang.org/x/tools/gopls@latest

RUN wget https://github.com/opentofu/opentofu/releases/download/v1.8.4/tofu_1.8.4_amd64.apk && \
    apk add --allow-untrusted tofu_1.8.4_amd64.apk

RUN adduser -D -s /bin/bash $USER \
    && echo "$USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USER \
    && chmod 0440 /etc/sudoers.d/$USER

USER $USER

WORKDIR /app