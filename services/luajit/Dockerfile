FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y luajit libluajit-5.1-dev luarocks && rm -rf /var/lib/apt/lists/*
RUN luarocks install luasocket
WORKDIR /app
COPY libmathcore.so ./
COPY bridge.lua ./
COPY server.lua ./
EXPOSE 8080
CMD ["luajit", "server.lua"]
