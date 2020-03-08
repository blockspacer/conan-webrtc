# NOTE:
# Dockerfile follows conan flow
# see https://docs.conan.io/en/latest/developing_packages/package_dev_flow.html
# Dockerfile separates source step from build, e.t.c. using multi-stage builds
# see https://docs.docker.com/develop/develop-images/multistage-build/

# ===
# STAGE FOR CONAN FLOW STEPS:
#   * conan remote add
#   * conan source
#   * conan install
# ===
# allows individual sections to be run by doing: docker build --target ...
FROM conan_build_env as conan_webrtc_repoadd_source_install
ARG BUILD_TYPE=Release
ARG APT="apt-get -qq --no-install-recommends"
ARG LS_VERBOSE="ls -artl"
ARG CONAN="conan"
ARG PKG_NAME="conan_webrtc/69"
ARG PKG_CHANNEL="conan/stable"
ARG PKG_UPLOAD_NAME="conan_webrtc/69@conan/stable"
ARG CONAN_SOURCE="conan source"
ARG CONAN_INSTALL="conan install --build missing --profile gcc"
#ARG CONAN_CREATE="conan create --profile gcc"
# Example: conan upload --all -r=conan-local -c --retry 3 --retry-wait 10 --force --confirm
ARG CONAN_UPLOAD=""
ARG CONAN_OPTIONS=""
# Example: --build-arg CONAN_EXTRA_REPOS="conan-local http://localhost:8081/artifactory/api/conan/conan False"
ARG CONAN_EXTRA_REPOS=""
# Example: --build-arg CONAN_EXTRA_REPOS_USER="user -p password -r conan-local admin"
ARG CONAN_EXTRA_REPOS_USER=""
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
    CONAN_VERBOSE_TRACEBACK=1 \
    DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true

# create all folders parent to $PROJ_DIR
RUN set -ex \
  && \
  echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections \
  && \
  mkdir -p $WDIR

# NOTE: ADD invalidates the cache, COPY does not
COPY "conanfile.py" $PROJ_DIR/conanfile.py
#COPY "test_package" $PROJ_DIR/test_package
COPY "build.py" $PROJ_DIR/build.py
COPY "CMakeLists.txt" $PROJ_DIR/CMakeLists.txt
WORKDIR $PROJ_DIR

RUN set -ex \
  && \
  $APT update \
  && \
  $APT install -y \
    clang-6.0 \
    build-essential \
    libcurl4 \
    libgtk2.0-dev \
    libx11-dev \
    g++ \
    python-dev \
    autotools-dev \
    libicu-dev \
    libbz2-dev \
    #add-apt-repository ppa:jonathonf/ffmpeg-4 && apt-get update
    #ffmpeg \
    #libavcodec-dev \
    #libavformat-dev \
    #libavutil-dev \
    wget \
    lsb-release \
    sudo \
    alsa-utils \
    pulseaudio \
    binutils \
    # dev_list
    #bison \
    #bzip2 \
    #cdbs \
    #curl \
    #dbus-x11 \
    #dpkg-dev \
    #elfutils \
    #devscripts \
    #fakeroot \
    #flex \
    #git-core \
    #gperf \
    #libappindicator3-dev \
    #libasound2-dev \
    #libatspi2.0-dev \
    #libbrlapi-dev \
    #libbz2-dev \
    #libcairo2-dev \
    #libcap-dev \
    #libc6-dev \
    #libcups2-dev \
    #libcurl4-gnutls-dev \
    #libdrm-dev \
    #libelf-dev \
    #libevdev-dev \
    #libffi-dev \
    #libgbm-dev \
    #libglib2.0-dev \
    #libglu1-mesa-dev \
    #libgtk-3-dev \
    #libkrb5-dev \
    #libnspr4-dev \
    #libnss3-dev \
    #libpam0g-dev \
    #libpci-dev \
    #libpulse-dev \
    #libsctp-dev \
    #libspeechd-dev \
    #libsqlite3-dev \
    #libssl-dev \
    #libudev-dev \
    #libwww-perl \
    #libxslt1-dev \
    #libxss-dev \
    #libxt-dev \
    #libxtst-dev \
    #locales \
    #openbox \
    #p7zip \
    #patch \
    #perl \
    #pkg-config \
    #python \
    #python-cherrypy3 \
    #python-crypto \
    #python-dev \
    #python-numpy \
    #python-opencv \
    #python-openssl \
    #python-psutil \
    #python-yaml \
    #rpm \
    #ruby \
    #subversion \
    #uuid-dev \
    #wdiff \
    #x11-utils \
    #xcompmgr \
    #xz-utils \
    #zip \
    ## common \
    #libappindicator3-1 \
    #libasound2 \
    #libatk1.0-0 \
    #libatspi2.0-0 \
    #libc6 \
    #libcairo2 \
    #libcap2 \
    #libcups2 \
    #libdrm2 \
    #libevdev2 \
    #libexpat1 \
    #libffi6 \
    #libfontconfig1 \
    #libfreetype6 \
    #libgbm1 \
    #libglib2.0-0 \
    #libgtk-3-0 \
    #libpam0g \
    #libpango1.0-0 \
    #libpci3 \
    #libpcre3 \
    #libpixman-1-0 \
    #libspeechd2 \
    #libstdc++6 \
    #libsqlite3-0 \
    #libuuid1 \
    #libwayland-egl1-mesa \
    #libx11-6 \
    #libx11-xcb1 \
    #libxau6 \
    #libxcb1 \
    #libxcomposite1 \
    #libxcursor1 \
    #libxdamage1 \
    #libxdmcp6 \
    #libxext6 \
    #libxfixes3 \
    #libxi6 \
    #libxinerama1 \
    #libxrandr2 \
    #libxrender1 \
    #libxtst6 \
    #zlib1g \
  && \
  # TODO: Build WebRTC with dummy audio (so that PulseAudio isn't a requirement)
  echo "pcm.default pulse\nctl.default pulse" > .asoundrc \
  && \
  cd $PROJ_DIR \
  && \
  $LS_VERBOSE $PROJ_DIR \
  && \
  echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections \
  && \
  ldconfig \
  && \
  export CC=clang-6.0 \
  && \
  export CXX=clang++-6.0 \
  && \
  $APT remove libssl*-dev \
  && \
  mkdir -p /root/workspace/openssl \
  && \
  cd /root/workspace/openssl \
  && \
  git clone https://github.com/openssl/openssl.git -b OpenSSL_1_1_1-stable . \
  && \
  git checkout OpenSSL_1_1_1-stable \
  && \
  ./config --prefix=/usr/ \
  && \
  make \
  && \
  make install \
  && \
  export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH" \
  #&& \
  #ldd $(type -p openssl) \
  && \
  openssl version \
  && \
  ldd /usr/bin/openssl \
  && \
  stat /usr/lib/libssl.so.* \
  && \
  stat /usr/lib/libcrypto.so.* \
  && \
  cmake -E make_directory /root/workspace \
  && \
  cd /root/workspace/ \
  && \
  (git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git /root/workspace/depot_tools || true) \
  && \
  ls -artl /root/workspace/depot_tools \
  && \
  export PATH=/root/workspace/depot_tools:$PATH \
  && \
#mkdir -p webrtc-checkout
  cmake -E make_directory webrtc-checkout \
  && \
  cd webrtc-checkout \
  && \
  (fetch --nohooks webrtc || true) \
  && \ 
  ls -artl \
  && \ 
  cd src \
  && \
  git config branch.autosetupmerge always \
  && \
  git config branch.autosetuprebase always \
  && \
# reset local changes
  git checkout -- . \
  && \
# checkout https://chromium.googlesource.com/external/webrtc/+/branch-heads/71/
#git checkout -b branch-heads/69 || true
#git checkout branch-heads/69 || true
  (git checkout -b 69 refs/remotes/branch-heads/69 || true) \
  && \
  (git checkout 69 || true) \
  && \
  (git checkout branch-heads/69 || true) \
  && \
#git checkout master
#git checkout 4036b0bc638a17021e316cbcc901ad09b509853d
  gclient sync \
  && \
  gclient runhooks \
  && \
# checkout https://chromium.googlesource.com/external/webrtc/+/branch-heads/71/
  (git checkout -b 69 refs/remotes/branch-heads/69 || true) \
  && \
  (git checkout 69 || true) \
  && \
  (git checkout branch-heads/69 || true) \
  && \
  (./build/install-build-deps.sh --no-prompt || true) \
  && \
  if [ ! -z "$CONAN_EXTRA_REPOS" ]; then \
    ($CONAN remote add $CONAN_EXTRA_REPOS || true) \
    ; \
  fi \
  && \
  if [ ! -z "$CONAN_EXTRA_REPOS_USER" ]; then \
    $CONAN $CONAN_EXTRA_REPOS_USER \
    ; \
  fi \
  && \
  cd /root/workspace/webrtc-checkout/src \
  && \
  git log -1 --pretty=%B \
  && \
  git branch \
  && \
  ls -artlh /root/workspace/webrtc-checkout/src/
  #&& \
  #$CONAN_SOURCE . $CONAN_OPTIONS \
  #&& \
  #$CONAN_INSTALL -s build_type=$BUILD_TYPE $CONAN_OPTIONS .