FROM ubuntu:18.04
ENV TZ=Europe/Zurich
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
    python3.8 python3-pip python3.8-dev
RUN pip3 install setuptools-rust && \
    pip3 install --upgrade pip

RUN apt update && apt install git curl gpg expect -y

RUN curl -fsSL https://clis.cloud.ibm.com/install/linux | sh

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
