# SEE https://github.com/vsimon/webrtcbuilds/blob/master/util.sh#L232


# This function compile and combine build artifact objects into one library.
# $1 the output directory, 'Debug', 'Release'
# $2 additional gn arguments
# After check: find ../ -name 'libwebrtc_full*'
function compile-unix() {
  local outputdir="$1"

  local blacklist="unittest|examples|/yasm|protobuf_lite|main.o|\
video_capture_external.o|device_info_external.o"

  pushd $outputdir >/dev/null

  #rm -f libwebrtc_full.a || true
  # Produce an ordered objects list by parsing .ninja_deps for strings
  # matching .o files.
  local objlist=$(strings .ninja_deps | grep -o '.*\.o')
  echo "$objlist" | tr ' ' '\n' | grep -v -E $blacklist >libwebrtc_full.list
  # various intrinsics aren't included by default in .ninja_deps
  #local extras=$(find \
  #  ./obj/third_party/libvpx/libvpx_* \
  #  ./obj/third_party/libjpeg_turbo/simd_asm \
  #  ./obj/third_party/boringssl/boringssl_asm -name '*.o')
  local extras=$(find \
    ./obj/third_party/libvpx/libvpx_* \
    ./obj/third_party/libjpeg_turbo/simd_asm -name '*.o')
  echo "$extras" | tr ' ' '\n' >>libwebrtc_full.list
  # generate the archive
  cat libwebrtc_full.list | xargs ar -crs libwebrtc_full.a
  # generate an index list
  ranlib libwebrtc_full.a
  popd >/dev/null
}

# BASED ON http://technicaladventure.blogspot.com/2017/10/compiling-webrtc-on-ubuntu.html
function combine-includes() {
	mkdir include
	mkdir include/webrtc
	find ./ -name *.h -exec cp --parents '{}' include/webrtc ';'
	# SEE https://github.com/vsimon/webrtcbuilds/blob/master/util.sh#L345
	find . -path './third_party*' -prune -o -name '*.h' -exec cp --parents '{}' include/webrtc ';'
}


pushd ~/workspace/webrtc-checkout/src

compile-unix "out/release" "$common_args $target_args"
combine-includes

file ./out/release/libwebrtc_full.a

# USAGE https://github.com/BrandonMakin/Godot-Module-WebRTC/blob/master/godot/modules/webrtc/config.py
# USAGE https://github.com/BrandonMakin/Godot-Module-WebRTC/blob/master/godot/modules/webrtc/SCsub
