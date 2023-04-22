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

download() {
  if command -v wget >/dev/null 2>&1; then
    wget --quiet --show-progress -O $2 $1
  elif command -v curl >/dev/null 2>&1; then
    curl -L --output $2 $1
  else
    ensure_command "wget"
    wget --quiet --show-progress -O $2 $1
  fi
}

mkdir -p build-em/
cd build-em/

# install cmake for vercel
if ! command -v cmake > /dev/null 2>&1; then
  download "https://github.com/Kitware/CMake/releases/download/v3.25.3/cmake-3.25.3-linux-x86_64.tar.gz" "cmake.tar.gz"
  tar -xf cmake.tar.gz
  rm cmake.tar.gz
  chmod +x cmake-3.25.3-linux-x86_64/bin/*
  PATH=`pwd`/cmake-3.25.3-linux-x86_64/bin:$PATH
  echo $PATH
fi

# download emsdk
if ! [ -d "emsdk-master" ] || ! [ -e "emsdk-master/emsdk_env.sh" ] || ! [ -e "emsdk-master/emsdk.py" ]; then
  download "https://github.com/emscripten-core/emsdk/archive/master.tar.gz" "master.tar.gz"
  ensure_command "xz"
  tar -xf master.tar.gz
  rm master.tar.gz
fi

# prepare emsdk env
emsdk-master/emsdk update
emsdk-master/emsdk install latest
emsdk-master/emsdk activate latest
source ./emsdk-master/emsdk_env.sh

# build
emcmake cmake .. && make -j
if [ $? -ne 0 ]; then
    echo "Error: build failed"
    exit
fi

# copy files to public folder
mkdir -p public
cp -r bin/whisper.wasm/* public/ && cp bin/libmain.worker.js public/
mkdir -p public/stream && cp -r bin/stream.wasm/* public/stream/ && cp bin/libstream.worker.js public/stream/
mkdir -p public/command && cp -r bin/command.wasm/* public/command/ && cp bin/libcommand.worker.js public/command/
mkdir -p public/talk && cp -r bin/talk.wasm/* public/talk/ && cp bin/libtalk.worker.js public/talk/
mkdir -p public/bench && cp -r bin/bench.wasm/* public/bench/ && cp bin/libbench.worker.js public/bench/

# add custom header config for netify/cloudflare pages
echo -e "/*\n  Cross-Origin-Embedder-Policy: require-corp\n  Cross-Origin-Opener-Policy: same-origin" > public/_headers

# done
echo "Output folder is: build-em/public"
echo "Done."
exit
