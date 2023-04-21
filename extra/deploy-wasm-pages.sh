#!/bin/bash

ensure_command() {
  if ! command -v $1 > /dev/null 2>&1; then
    if command -v yum >/dev/null 2>&1; then
      yum install -y ${2:-$1}
    elif command -v apt-get >/dev/null 2>&1; then
      apt-get install -y ${2:-$1}
    elif command -v brew >/dev/null 2>&1; then
      brew install ${2:-$1}
    else
      echo "Please install $1 manually"
      exit 1
    fi
  fi
}

ensure_command "cmake"

mkdir -p build-em/
cd build-em/

if ! [ -d "emsdk-master" ]; then
  url=https://github.com/emscripten-core/emsdk/archive/master.tar.gz
  if command -v wget >/dev/null 2>&1; then
    wget --quiet --show-progress -O master.tar.gz $url
  elif command -v curl >/dev/null 2>&1; then
    curl -L --output master.tar.gz $url
  else
    ensure_command "wget"
    wget --quiet --show-progress -O master.tar.gz $url
  fi
  ensure_command "xz" "xz-utils"
  tar -xvf master.tar.gz
  rm master.tar.gz
fi

emsdk-master/emsdk update
emsdk-master/emsdk install latest
emsdk-master/emsdk activate latest

source ./emsdk-master/emsdk_env.sh

if [ -z "$EMSDK_NODE" ]; then
  EMSDK_NODE=$(which node)
fi

if ! command -v emcmake > /dev/null 2>&1; then
  PATH=`pwd`/build-em/emsdk-master/upstream/emscripten:$PATH
fi

emcmake cmake ..
make -j

# copy files to public folder
rm -rf public
mkdir public
cp -r bin/whisper.wasm/* public/ && cp bin/libmain.worker.js public/
mkdir -p public/stream && cp -r bin/stream.wasm/* public/stream/ && cp bin/libstream.worker.js public/stream/
mkdir -p public/command && cp -r bin/command.wasm/* public/command/ && cp bin/libcommand.worker.js public/command/
mkdir -p public/talk && cp -r bin/talk.wasm/* public/talk/ && cp bin/libtalk.worker.js public/talk/
mkdir -p public/bench && cp -r bin/bench.wasm/* public/bench/ && cp bin/libbench.worker.js public/bench/

# custom header config for netify/cloudflare pages
echo -e "/*\n  Cross-Origin-Embedder-Policy: require-corp\n  Cross-Origin-Opener-Policy: same-origin" > public/_headers

echo -e "Done.\nOutput folder is: build-em/public"
