FROM alpine:3.20

ARG USER=default
ENV HOME /home/$USER

RUN apk update \
    && apk add --no-cache bash sudo opentofu

RUN adduser -D -s /bin/bash $USER \
    && echo "$USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USER \
    && chmod 0440 /etc/sudoers.d/$USER

USER $USER
WORKDIR /app