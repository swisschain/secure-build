FROM python:3.8.13-slim-buster

RUN apt update && apt install git curl gpg expect -y

RUN curl -fsSL https://clis.cloud.ibm.com/install/linux | sh
RUN ibmcloud plugin install container-registry
RUN ibmcloud plugin install hpvs
RUN ibmcloud plugin list

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
