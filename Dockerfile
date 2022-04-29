FROM ubuntu:18.04
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
    python3.8 python3-pip python3.8-dev
RUN apt update && apt install software-properties-common -y

RUN apt update && apt install git curl gpg expect -y

RUN curl -fsSL https://clis.cloud.ibm.com/install/linux | sh

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
