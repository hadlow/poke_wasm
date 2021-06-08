# Modified from https://hub.docker.com/r/robertaboukhalil/emsdk/tags?page=1&ordering=last_updated
FROM ubuntu:latest

# Main dependencies
RUN apt-get update && \
    apt-get install -y git python build-essential openjdk-8-jre-headless

# Setup emsdk
RUN git clone https://github.com/emscripten-core/emsdk.git
WORKDIR /emsdk
RUN git pull

RUN ./emsdk install latest
RUN ./emsdk activate latest
RUN ./emsdk construct_env
RUN echo "./emsdk/emsdk_set_env.sh" >> ~/.bashrc
RUN ./emsdk help

RUN mkdir /src
WORKDIR /src

ENV TZ=Europe/London
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Book dependencies (putting those here so we don't rebuild scratch every time we add a dependency)
# Tools we'll use while building packages + OpenGL support + SDL2 support
RUN apt-get install -y procps
RUN apt-get install -y gcc
RUN apt-get install -y vim
RUN apt-get install -y libz-dev
RUN apt-get install -y autoconf
RUN apt-get install -y libtool
RUN apt-get install -y cmake
RUN apt-get install -y libgles2-mesa-dev
RUN apt-get install -y libsdl2-dev
RUN apt-get install -y libsdl2-image-dev
RUN apt-get install -y libsdl2-mixer-dev
RUN apt-get install -y libsdl2-ttf-dev
RUN apt-get install -y curl

# Setup & launch web server
ENV PORT 80
ENV WEB_SERVER_CODE "\
import SimpleHTTPServer, SocketServer \n\n\
class Handler(SimpleHTTPServer.SimpleHTTPRequestHandler): \n\
    pass \n\n\
Handler.extensions_map['.wasm'] = 'application/wasm' \n\n\
print('Launching server on port {}...'.format($PORT)) \n\
httpd = SocketServer.TCPServer(('', $PORT), Handler) \n\
httpd.serve_forever()\n"

RUN echo "$WEB_SERVER_CODE" > /emsdk/server.py
CMD python /emsdk/server.py

# Export port
EXPOSE $PORT
