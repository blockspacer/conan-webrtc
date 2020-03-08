# NOTE:
# Dockerfile follows conan flow
# see https://docs.conan.io/en/latest/developing_packages/package_dev_flow.html

# ===
# STAGE FOR CONAN FLOW STEPS:
#   * conan build
#   * conan package
#   * conan export-pkg
#   * conan test
#   * conan create
#   * conan upload
# ===
# allows individual sections to be run by doing: docker build --target ...
# NOTE: can use `ARG` and `ENV` from base container
FROM conan_webrtc_repoadd_source_install as conan_webrtc_build_package_export_test_upload

ARG BUILD_TYPE=Release
ARG APT="apt-get -qq --no-install-recommends"
ARG LS_VERBOSE="ls -artl"
ARG CONAN="conan"
ARG PKG_NAME="conan_webrtc/69"
ARG PKG_CHANNEL="conan/stable"
ARG PKG_UPLOAD_NAME="conan_webrtc/69@conan/stable"
ARG CONAN_SOURCE="conan source"
ARG CONAN_INSTALL="conan install --build missing --profile gcc"

# see https://docs.conan.io/en/latest/reference/commands/development/build.html
ARG CONAN_BUILD="conan build --build-folder=."

# see https://docs.conan.io/en/latest/reference/commands/development/package.html
ARG CONAN_PACKAGE="conan package --build-folder=."

# see https://docs.conan.io/en/latest/reference/commands/creator/export-pkg.html
ARG CONAN_EXPORT_PKG="conan export-pkg --profile gcc --build-folder=."

# --> --> -->
# TODO: add `conan test`
# <-- <-- <--
# see https://docs.conan.io/en/latest/reference/commands/creator/test.html
#ARG CONAN_TEST="conan test --profile gcc"

# see https://docs.conan.io/en/latest/reference/commands/creator/create.html
# NOTE: prefer `--keep-source` and `--keep-build` because `conan build` already performed
#ARG CONAN_CREATE="conan create --profile gcc --keep-source"

# see https://docs.conan.io/en/latest/reference/commands/creator/upload.html
# Example: conan upload --all -r=conan-local -c --retry 3 --retry-wait 10 --force --confirm
ARG CONAN_UPLOAD=""

ARG CONAN_OPTIONS=""

ENV LC_ALL=C.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    #TERM=screen \
    PATH=/root/workspace/depot_tools:/usr/bin/:/usr/local/bin/:/go/bin:/usr/local/go/bin:/usr/local/include/:/usr/local/lib/:/usr/lib/clang/6.0/include:/usr/lib/llvm-6.0/include/:$PATH \
    LD_LIBRARY_PATH=/usr/local/lib/:$LD_LIBRARY_PATH \
    WDIR=/opt \
    # NOTE: PROJ_DIR must be within WDIR
    PROJ_DIR=/opt/project_copy \
    GOPATH=/go \
    CONAN_REVISIONS_ENABLED=1 \
    CONAN_PRINT_RUN_COMMANDS=1 \
    CONAN_LOGGING_LEVEL=10 \
    CONAN_VERBOSE_TRACEBACK=1

# NOTE: overrides old files from base image, so updated conanfile, CMakeLists, e.t.c. can be used
#
# NOTE: ADD invalidates the cache, COPY does not
COPY "conanfile.py" $PROJ_DIR/conanfile.py
#COPY "test_package" $PROJ_DIR/test_package
COPY "build.py" $PROJ_DIR/build.py
COPY "CMakeLists.txt" $PROJ_DIR/CMakeLists.txt
COPY "scripts/combine_webrtc_libs.sh" $PROJ_DIR/scripts/combine_webrtc_libs.sh
COPY "patches/webrtc/src/BUILD.gn" $PROJ_DIR/patches/webrtc/src/BUILD.gn
COPY "patches/webrtc/src/rtc_base/BUILD.gn" $PROJ_DIR/patches/webrtc/src/rtc_base/BUILD.gn
COPY "patches/webrtc/src/rtc_base/opensslutility.cc" $PROJ_DIR/patches/webrtc/src/rtc_base/opensslutility.cc
COPY "patches/webrtc/src/rtc_base/opensslsessioncache_unittest.cc" $PROJ_DIR/patches/webrtc/src/rtc_base/opensslsessioncache_unittest.cc

# create all folders parent to $PROJ_DIR
RUN set -ex \
  && \
  echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections \
  && \
  $LS_VERBOSE $PROJ_DIR \
  && \
  mkdir -p $WDIR \
  && \
  cd $PROJ_DIR \
  && \
  $LS_VERBOSE $PROJ_DIR \
  && \
  ldconfig \
  && \
  export CC=clang-6.0 \
  && \
  export CXX=clang++-6.0 \
  && \
  export PATH=/root/workspace/depot_tools:$PATH \
  && \
  cd /root/workspace/webrtc-checkout/src/ \
  && \
  # APPLY PATCH
  cp -rf $PROJ_DIR/patches/webrtc/src/BUILD.gn /root/workspace/webrtc-checkout/src/BUILD.gn \
  && \
  # APPLY PATCH
  cp -rf $PROJ_DIR/patches/webrtc/src/rtc_base/BUILD.gn /root/workspace/webrtc-checkout/src/rtc_base/BUILD.gn \
  && \
  # APPLY PATCH
  cp -rf $PROJ_DIR/patches/webrtc/src/rtc_base/opensslutility.cc /root/workspace/webrtc-checkout/src/rtc_base/opensslutility.cc \
  && \
  # APPLY PATCH
  cp -rf $PROJ_DIR/patches/webrtc/src/rtc_base/opensslsessioncache_unittest.cc /root/workspace/webrtc-checkout/src/rtc_base/opensslsessioncache_unittest.cc \
  && \
  export GYP_DEFINES="target_arch=x64 host_arch=x64 build_with_chromium=0 build_with_mozilla=0 use_openssl=1 use_gtk=0 use_x11=0 include_examples=0 include_tests=0 fastbuild=1 remove_webcore_debug_symbols=1 include_pulse_audio=0 include_internal_video_render=0 clang=0" \
  && \
  cmake -E remove_directory  ./out/release \
  && \
  export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH" \
  && \
  gn gen out/release --args="is_debug=false use_rtti=true target_os=\"linux\" enable_iterator_debugging=false is_component_build=false rtc_use_x11=false rtc_build_json=true rtc_use_pipewire=false rtc_build_examples=false rtc_build_tools=false rtc_include_tests=false use_custom_libcxx=false proprietary_codecs=true use_custom_libcxx_for_host=false rtc_build_ssl=false rtc_ssl_root=\"$HOME/workspace/openssl\" " \
  && \
  ninja -C ./out/release rtc_base protobuf_lite p2p base64 jsoncpp rtc_json -t clean \
  && \
  ninja -C ./out/release -t clean \
  && \
  ninja -C ./out/release rtc_base protobuf_lite p2p base64 jsoncpp rtc_json \
  && \
  ninja -C ./out/release \
  && \
  ls -artlh ./out/release \
  && \
  ls -artlh ./out/release/obj/rtc_base \
  && \
# see combine_webrtc_libs.sh
  cmake -E remove ./out/release/libwebrtc_full.a \
  && \
# see combine_webrtc_libs.sh
  cmake -E remove_directory include \
  && \
  ls -artlh \
  && \
  cd $PROJ_DIR \
  && \
  bash scripts/combine_webrtc_libs.sh \
  && \
  cd /root/workspace/webrtc-checkout/src \
  && \
  git log -1 --pretty=%B \
  && \
  git branch \
  && \
  file /root/workspace/webrtc-checkout/src/out/release/libwebrtc_full.a
  #$CONAN_BUILD . $CONAN_OPTIONS \
  #&& \
  #$CONAN_PACKAGE . $CONAN_OPTIONS \
  #&& \
  #$CONAN_EXPORT_PKG . $PKG_CHANNEL --settings build_type=$BUILD_TYPE $CONAN_OPTIONS \
  #  # --> --> -->
  #  # TODO: add `conan test`
  #  # <-- <-- <--
  ##&& \
  ##$CONAN_TEST test_package $PKG_UPLOAD_NAME --settings build_type=$BUILD_TYPE $CONAN_OPTIONS \
  ##&& \
  ## NOTE: NO need for CONAN_CREATE
  ##$CONAN_CREATE . $PKG_UPLOAD_NAME --settings build_type=$BUILD_TYPE $CONAN_OPTIONS \
  #&& \
  #if [ ! -z "$CONAN_UPLOAD" ]; then \
  #  $CONAN_UPLOAD $PKG_UPLOAD_NAME \
  #  ; \
  #fi \
  # NOTE: no need to clean apt or build folders in dev env
