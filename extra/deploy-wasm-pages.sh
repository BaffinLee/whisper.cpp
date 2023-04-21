#!/bin/bash

if ! command -v cmake &> /dev/null; then
  if command -v yum >/dev/null 2>&1; then
    yum install -y cmake
  elif command -v apt-get >/dev/null 2>&1; then
    apt-get install -y cmake
  fi
fi

mkdir -p build-em/
cd build-em/

if ! [ -d "emsdk-master" ]; then
  wget -q https://github.com/emscripten-core/emsdk/archive/master.tar.gz
  tar -xvf master.tar.gz
  rm master.tar.gz
fi

emsdk-master/emsdk update
emsdk-master/emsdk install latest
emsdk-master/emsdk activate latest

source ./emsdk-master/emsdk_env.sh
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
