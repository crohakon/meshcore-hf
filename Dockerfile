FROM debian:bookworm-slim AS builder

RUN apt-get update && apt-get install -y \
    git build-essential libncurses-dev g++ libhidapi-dev

WORKDIR /build
RUN git clone https://github.com/RFnexus/modem73.git
RUN cd modem73 && make

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    socat alsa-utils libncurses6 libhidapi-hidraw0 \
    && rm -rf /var/lib/apt/lists*

COPY --from=builder /build/modem73 /usr/local/bin/modem73
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
