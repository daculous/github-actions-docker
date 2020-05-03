FROM ubuntu:20.04

LABEL "com.github.actions.name"="Docker Push"
LABEL "com.github.actions.description"="build, tag and pushes the container"
LABEL "com.github.actions.icon"="anchor"
LABEL "com.github.actions.color"="blue"

LABEL version=v0.1.0
LABEL repository="https://github.com/daculous/github-actions-docker"
LABEL maintainer="DACulous <info@daculous.com>"
LABEL homepage="https://daculous.com/"

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
