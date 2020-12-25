# About

wrtc with openssl support (patched)

added support for conan and docker

supports conan, but as pre-built package (pre-built binaries/libs/includes can be extracted from docker as below)

TODO: ADD conan support for builds from source

## Docker build with `--no-cache`

```bash
export MY_IP=$(ip route get 8.8.8.8 | sed -n '/src/{s/.*src *\([^ ]*\).*/\1/p;q}')
sudo -E docker build \
    --build-arg PKG_NAME=webrtc_conan \
    --build-arg PKG_CHANNEL=conan/stable \
    --build-arg PKG_UPLOAD_NAME=webrtc_conan/69@conan/stable \
    --build-arg CONAN_EXTRA_REPOS="conan-local http://$MY_IP:8081/artifactory/api/conan/conan False" \
    --build-arg CONAN_EXTRA_REPOS_USER="user -p password1 -r conan-local admin" \
    --build-arg CONAN_UPLOAD="conan upload --all -r=conan-local -c --retry 3 --retry-wait 10 --force" \
    --build-arg BUILD_TYPE=Debug \
    -f conan_webrtc_source.Dockerfile --tag conan_webrtc_repoadd_source_install . --no-cache

sudo -E docker build \
    --build-arg PKG_NAME=webrtc_conan/69 \
    --build-arg PKG_CHANNEL=conan/stable \
    --build-arg PKG_UPLOAD_NAME=webrtc_conan/69@conan/stable \
    --build-arg CONAN_EXTRA_REPOS="conan-local http://$MY_IP:8081/artifactory/api/conan/conan False" \
    --build-arg CONAN_EXTRA_REPOS_USER="user -p password1 -r conan-local admin" \
    --build-arg CONAN_UPLOAD="conan upload --all -r=conan-local -c --retry 3 --retry-wait 10 --force" \
    --build-arg BUILD_TYPE=Debug \
    -f conan_webrtc_build.Dockerfile --tag conan_webrtc_build_package_export_test_upload . --no-cache

# copy files from docker container to host machine
(docker stop conan_webrtc || true)
(docker rm conan_webrtc || true)
docker run --cap-add=SYS_PTRACE --security-opt seccomp=unconfined \
    -it \
    --entrypoint="/bin/bash" \
    -v "$PWD":/home/u/host_dir \
    -w /home/u/host_dir \
    --name conan_webrtc \
    conan_webrtc_build_package_export_test_upload

# type in docker container
# Copy pre-built webrtc library to "lib" folder
mkdir -p /home/u/host_dir/lib
cp /root/workspace/webrtc-checkout/src/out/release/libwebrtc_full.a /home/u/host_dir/lib/libwebrtc_full.a
# Copy pre-built webrtc include files to "include" folder
mkdir -p /home/u/host_dir/include/webrtc
cd /root/workspace/webrtc-checkout/src
find . -name "*.hpp" -type f | xargs -I {} cp --parents {} /home/u/host_dir/include/webrtc
find . -name "*.hxx" -type f | xargs -I {} cp --parents {} /home/u/host_dir/include/webrtc
find . -name "*.hh" -type f | xargs -I {} cp --parents {} /home/u/host_dir/include/webrtc
find . -name "*.inc" -type f | xargs -I {} cp --parents {} /home/u/host_dir/include/webrtc
find . -name "*.h" -type f | xargs -I {} cp --parents {} /home/u/host_dir/include/webrtc
ls -artl /home/u/host_dir/include
ls -artl /home/u/host_dir/include/webrtc

# exit to host machine from docker container
exit

sudo chown -R $USER .

# file must exist in host machine
file lib/libwebrtc_full.a

# file must exist in host machine
file include/webrtc/api/array_view.h
file include/webrtc/rtc_base/opensslutility.h

(docker stop conan_webrtc || true)
(docker rm conan_webrtc || true)

# OPTIONAL: clear unused data
sudo -E docker rmi conan_webrtc_*
```

## Local build

Copy pre-built webrtc library to "lib" folder
Copy pre-built webrtc include dir to "include" folder

```bash
export PKG_NAME=webrtc_conan/69@conan/stable
(conan remove --force $PKG_NAME || true)
conan create . conan/stable -s build_type=Debug --profile clang --build missing
CONAN_REVISIONS_ENABLED=1 CONAN_VERBOSE_TRACEBACK=1 CONAN_PRINT_RUN_COMMANDS=1 CONAN_LOGGING_LEVEL=10 conan upload $PKG_NAME --all -r=conan-local -c --retry 3 --retry-wait 10 --force

# clean build cache
conan remove "*" --build --force
```

## How to package webrtc without Docker

Follow commands from Dockerfile-s to build webrtc locally

You can manually copy build artifacts and package with conan as stated in `Local build` section above

## How to diagnose errors in conanfile (CONAN_PRINT_RUN_COMMANDS)

```bash
# NOTE: about `--keep-source` see https://bincrafters.github.io/2018/02/27/Updated-Conan-Package-Flow-1.1/
CONAN_REVISIONS_ENABLED=1 CONAN_VERBOSE_TRACEBACK=1 CONAN_PRINT_RUN_COMMANDS=1 CONAN_LOGGING_LEVEL=10 conan create . conan/stable -s build_type=Debug --profile clang --build missing --keep-source

# clean build cache
conan remove "*" --build --force
```
