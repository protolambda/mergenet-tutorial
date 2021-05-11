FROM ubuntu:20.10
RUN apt-get update
RUN apt-get install -y tzdata

RUN apt-get install -y python3-dev python3-venv python3-pip
RUN python3 -m venv /venv
COPY requirements.txt /requirements.txt
RUN /venv/bin/pip install -r /requirements.txt
ENV PATH=$PATH:/venv/bin VIRTUAL_ENV=/venv

RUN apt-get install -y curl
RUN curl https://dl.google.com/go/go1.16.3.linux-amd64.tar.gz | tar -xz -C /usr/local
ENV PATH=$PATH:/usr/local/gopath/bin:/usr/local/go/bin GOPATH=/usr/local/gopath

RUN go install github.com/protolambda/eth2-testnet-genesis@latest
RUN go install github.com/protolambda/eth2-val-tools@latest
