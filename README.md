# About

wrtc with openssl support (patched)

added support for conan and docker 

TODO: ADD conan support

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

mkdir built_webrtc
cd built_webrtc

# copy files from docker container to host machine
docker run --cap-add=SYS_PTRACE --security-opt seccomp=unconfined \
    -it \
    --entrypoint="/bin/bash" \
    -v "$PWD":/home/u/host_dir \
    -w /home/u/host_dir \
    --name conan_webrtc \
    conan_webrtc_build_package_export_test_upload

# type in docker container
cp /root/workspace/webrtc-checkout/src/out/release/libwebrtc_full.a /home/u/host_dir/libwebrtc_full.a
cp -r /root/workspace/webrtc-checkout/src/include /home/u/host_dir/include

# exit to host machine from docker container
exit

# file must exist in host machine
file libwebrtc_full.a

sudo -E docker stop conan_webrtc
sudo -E docker rm conan_webrtc

# OPTIONAL: clear unused data
sudo -E docker rmi conan_webrtc_*
```

## Local build

```bash
export PKG_NAME=webrtc_conan/69@conan/stable
conan remove $PKG_NAME
conan create . conan/stable -s build_type=Debug --profile gcc --build missing
CONAN_REVISIONS_ENABLED=1 CONAN_VERBOSE_TRACEBACK=1 CONAN_PRINT_RUN_COMMANDS=1 CONAN_LOGGING_LEVEL=10 conan upload $PKG_NAME --all -r=conan-local -c --retry 3 --retry-wait 10 --force
```

## How to diagnose errors in conanfile (CONAN_PRINT_RUN_COMMANDS)

```bash
# NOTE: about `--keep-source` see https://bincrafters.github.io/2018/02/27/Updated-Conan-Package-Flow-1.1/
CONAN_REVISIONS_ENABLED=1 CONAN_VERBOSE_TRACEBACK=1 CONAN_PRINT_RUN_COMMANDS=1 CONAN_LOGGING_LEVEL=10 conan create . conan/stable -s build_type=Debug --profile gcc --build missing --keep-source
```
