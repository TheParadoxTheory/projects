FROM gitpod/workspace-full

RUN apt-get update && apt-get install -y \

USER gitpod

USER root