#!/bin/sh
set -e

version="v24.8.0"

query_component() {
  component=$1
  curl 'https://ci.openharmony.cn/api/daily_build/build/list/component' \
    -H 'Accept: application/json, text/plain, */*' \
    -H 'Content-Type: application/json' \
    --data-raw '{"projectName":"openharmony","branch":"master","pageNum":1,"pageSize":10,"deviceLevel":"","component":"'${component}'","type":1,"startTime":"2025080100000000","endTime":"20990101235959","sortType":"","sortField":"","hardwareBoard":"","buildStatus":"success","buildFailReason":"","withDomain":1}'
}

# setup LLVM-19
llvm19_download_url=$(query_component "LLVM-19" | jq -r ".data.list.dataList[0].obsPath")
curl $llvm19_download_url -o LLVM-19.tar.gz
mkdir -p /opt/llvm-19
tar -zxf LLVM-19.tar.gz -C /opt/llvm-19
rm -rf LLVM-19.tar.gz
cd /opt/llvm-19
tar -zxf llvm-linux-x86_64.tar.gz
tar -zxf ohos-sysroot.tar.gz
rm -rf *.tar.gz
cd -

git clone --branch $version --depth 1 https://github.com/nodejs/node.git
cd node
export CC="/opt/llvm-19/llvm/bin/aarch64-unknown-linux-ohos-clang -Wno-error=implicit-function-declaration"
export CXX="/opt/llvm-19/llvm/bin/aarch64-unknown-linux-ohos-clang++ -Wno-error=implicit-function-declaration"
export CC_host="gcc"
export CXX_host="g++"
./configure --dest-cpu=arm64 --dest-os=openharmony --cross-compiling --partly-static --prefix=node-${version}-openharmony-arm64-with-partly-static
make -j$(nproc)
make install

cp LICENSE node-${version}-openharmony-arm64-with-partly-static
tar -zcf node-${version}-openharmony-arm64-no-partly-static.tar.gz node-${version}-openharmony-arm64-with-partly-static
