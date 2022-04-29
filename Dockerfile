FROM ubuntu:18.04
RUN apt update && apt install software-properties-common -y
RUN add-apt-repository ppa:deadsnakes/ppa && install python3.8 -y
RUN ln -s /usr/bin/pip3 /usr/bin/pip && \
    ln -s /usr/bin/python3.8 /usr/bin/python

RUN apt update && apt install git curl gpg expect -y

RUN curl -fsSL https://clis.cloud.ibm.com/install/linux | sh

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
