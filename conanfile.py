from conans import ConanFile, CMake, tools, AutoToolsBuildEnvironment, RunEnvironment
from conans.errors import ConanInvalidConfiguration, ConanException
from conans.tools import os_info
import os, re, stat, fnmatch, platform, glob
from functools import total_ordering

class webrtcConan(ConanFile):
    name = "webrtc_conan"
    version = "69"
    description = "Google's webrtc_conan library and framework."
    topics = ("conan", "webrtc", "rtc")
    #homepage = "https://github.com/grpc/grpc-web" # TODO
    repo_url = 'https://github.com/grpc/grpc-web.git'
    license = "Apache-2.0" # TODO
    exports_sources = ["*"]
    #exports_sources = ["CMakeLists.txt", "*LICENSE*", "lib", "include", "*.a", "*.lib", "*.so", "*.dll", "*.patch", "*patch*"]
    generators = "cmake", "cmake_paths", "virtualenv"#, "cmake_find_package_multi"
    short_paths = True

    settings = "os_build", "os", "arch", "compiler", "build_type"
    options = {
        # "shared": [True, False],
        "fPIC": [True, False]
    }
    default_options = {
        "fPIC": True
    }

    @property
    def _source_dir(self):
        return "."

    @property
    def _build_dir(self):
        return "."

    @property
    def _is_msvc(self):
        return self.settings.compiler == "Visual Studio"

    @property
    def _is_clangcl(self):
        return self.settings.compiler == "clang" and self.settings.os == "Windows"

    @property
    def _is_mingw(self):
        return self.settings.os == "Windows" and self.settings.compiler == "gcc"

    #@property
    #def _use_nmake(self):
    #    return self._is_clangcl or self._is_msvc
#
    #@property
    #def _make_program(self):
    #    if self._use_nmake:
    #        return "nmake"
    #    make_program = tools.get_env("CONAN_MAKE_PROGRAM", tools.which("make") or tools.which('mingw32-make'))
    #    make_program = tools.unix_path(make_program) if tools.os_info.is_windows else make_program
    #    if not make_program:
    #        raise Exception('could not find "make" executable. please set "CONAN_MAKE_PROGRAM" environment variable')
    #    return make_program

    @staticmethod
    def detected_os():
        if tools.OSInfo().is_macos:
            return "Macos"
        if tools.OSInfo().is_windows:
            return "Windows"
        return platform.system()

    #@property
    #def _cross_building(self):
    #    if tools.cross_building(self.settings):
    #        if self.settings.os == self.detected_os():
    #            if self.settings.arch == "x86" and tools.detected_architecture() == "x86_64":
    #                return False
    #        return True
    #    return False
#
    #@property
    #def _win_bash(self):
    #    return tools.os_info.is_windows and \
    #           not self._use_nmake and \
    #           (self._is_mingw or self._cross_building)
#
    #def requirements(self):
    #    # TODO: https://github.com/gaeus/conan-grpc
    #    #self.requires("protobuf/3.6.1@bincrafters/stable")
    #    #self.requires("grpc_conan/v1.26.x@conan/stable")
    #    self.requires("openssl/OpenSSL_1_1_1-stable@conan/stable")
    #    self.requires("zlib/v1.2.11@conan/stable")
    #    self.requires("c-ares/cares-1_15_0@conan/stable")
    #    self.requires("protobuf/v3.9.1@conan/stable")

    #def _run_make(self, targets=None, makefile=None, parallel=True):
    #    command = [self._make_program]
    #    if makefile:
    #        command.extend(["-f", makefile])
    #    if targets:
    #        command.extend(targets)
    #    if not self._use_nmake:
    #        command.append(("-j%s" % tools.cpu_count()) if parallel else "-j1")
    #    self.run(" ".join(command), win_bash=self._win_bash)

    def configure(self):
        if self.settings.os == "Windows" and self.settings.compiler == "Visual Studio":
            del self.options.fPIC
            compiler_version = tools.Version(self.settings.compiler.version)
            if compiler_version < 14:
                raise ConanInvalidConfiguration("webrtc can only be built with Visual Studio 2015 or higher.")

    def source(self):
        self.output.info('Prebuilt package \'{}\' from path \'{}\''.format(self.name, os.path.dirname(os.path.realpath(__file__))))
        #self.copy("*") # assume package as-is, but you can also copy specific files or rearrange

        # NOTE: about `--recurse-submodules -j8` see https://stackoverflow.com/a/4438292
        #self.run("git clone --recurse-submodules -j8 -b 1.26.x https://github.com/grpc/grpc.git " + self._source_dir)

        # NOTE: without submodules (!!!)
        #self.run('git clone --progress --depth 1 --branch {} {} {}'.format(self.version, self.repo_url, self._source_dir))

    def build(self):
        self.output.info('Building package \'{}\''.format(self.name))

        # see exports_sources
        #self.run('ls -artl \'{}\''.format(os.getcwd()))
        #self.run('mkdir -p \'{}\'/'.format(self._source_dir))
        #self.run('cp *.a \'{}\'/'.format(self._source_dir))
        #self.run('cp *.so \'{}\'/'.format(self._source_dir))
        #self.run('cp *.dll \'{}\'/'.format(self._source_dir))
        #self.run('cp *.lib \'{}\'/'.format(self._source_dir))
        #self.run('cp -r include \'{}\'/include'.format(self._source_dir))
        #self.run('cp -r lib \'{}\'/lib'.format(self._source_dir))
        #self.run('ls -artl \'{}\''.format(self._source_dir))

#        # NOTE: make sure `protoc` can be found using PATH environment variable
#        bin_path = ""
#        for p in self.deps_cpp_info.bin_paths:
#            bin_path = "%s%s%s" % (p, os.pathsep, bin_path)
#
#        lib_path = ""
#        for p in self.deps_cpp_info.lib_paths:
#            lib_path = "%s%s%s" % (p, os.pathsep, lib_path)
#
#        # NOTE: make sure `/lib` from `protobuf` can be found using PATH environment variable
#        for p in self.deps_cpp_info["protobuf"].lib_paths:
#            lib_path = "%s%s%s" % (p, os.pathsep, lib_path)
#            self.output.info('protobuf lib_path += %s' % (p))
#            files = [f for f in glob.glob(p + "/**", recursive=True)]
#            for f in files:
#                self.output.info('protobuf libs: %s' % (f))
#
#        include_path = ""
#        for p in self.deps_cpp_info.includedirs:
#            include_path = "%s%s%s" % (p, os.pathsep, include_path)
#
#        # NOTE: make sure `/include` from `protobuf` can be found using PATH environment variable
#        for p in self.deps_cpp_info["protobuf"].include_paths:
#            include_path = "%s%s%s" % (p, os.pathsep, include_path)
#
#        # NOTE: make sure `grpc_cpp_plugin` can be found using PATH environment variable
#        path_to_grpc_cpp_plugin = os.path.join(os.getcwd(), "bin")
#
#        # see https://docs.conan.io/en/latest/reference/build_helpers/autotools.html
#        # AutoToolsBuildEnvironment sets LIBS, LDFLAGS, CFLAGS, CXXFLAGS and CPPFLAGS based on requirements
#        env_build = AutoToolsBuildEnvironment(self)
#        self.output.info('AutoToolsBuildEnvironment include_paths = %s' % (','.join(env_build.include_paths)))
#
#        env = {
#             "LIBS": "%s%s%s" % (env_build.vars["LIBS"] if "LIBS" in env_build.vars else "", " ", os.environ["LIBS"] if "LIBS" in os.environ else ""),
#             "LDFLAGS": "%s%s%s" % (env_build.vars["LDFLAGS"] if "LDFLAGS" in env_build.vars else "", " ", os.environ["LDFLAGS"] if "LDFLAGS" in os.environ else ""),
#             "CFLAGS": "%s%s%s" % (env_build.vars["CFLAGS"] if "CFLAGS" in env_build.vars else "", " ", os.environ["CFLAGS"] if "CFLAGS" in os.environ else ""),
#             "CXXFLAGS": "%s%s%s" % (env_build.vars["CXXFLAGS"] if "CXXFLAGS" in env_build.vars else "", " ", os.environ["CXXFLAGS"] if "CXXFLAGS" in os.environ else ""),
#             "CPPFLAGS": "%s%s%s" % (env_build.vars["CPPFLAGS"] if "CPPFLAGS" in env_build.vars else "", " ", os.environ["CPPFLAGS"] if "CPPFLAGS" in os.environ else ""),
#             "PATH": "%s%s%s%s%s%s%s" % (path_to_grpc_cpp_plugin, os.pathsep, bin_path, os.pathsep, include_path, os.pathsep, os.environ["PATH"] if "PATH" in os.environ else ""),
#             "LD_LIBRARY_PATH": "%s%s%s" % (lib_path, os.pathsep, os.environ["LD_LIBRARY_PATH"] if "LD_LIBRARY_PATH" in os.environ else "")
#        }

#        self.output.info("=================linux environment for %s=================\n" % (self.name))
#        self.output.info('PATH = %s' % (env['PATH']))
#        self.output.info('LD_LIBRARY_PATH = %s' % (env['LD_LIBRARY_PATH']))
#        self.output.info('')
#        with tools.environment_append(env):
#            # NOTE: without submodules (!!!)
#            #with tools.chdir(self._source_dir + "/third_party/grpc"):
#            #    self._run_make(parallel=False)
#            #with tools.chdir(self._source_dir + "/third_party/grpc/third_party/protobuf"):
#            #    self._run_make(parallel=False)
#            with tools.chdir(self._source_dir):
#                #self._run_make(targets=["plugin"], parallel=False)
#                env_build.make(vars=env, target="plugin")

    def package(self):
        #self.copy("*") # assume package as-is, but you can also copy specific files or rearrange

        self.output.info('Packaging package \'{}\''.format(self.name))

        #self.run('ls -artl \'{}\''.format(os.getcwd()))
        self.run('ls -artl include')
        self.run('ls -artl include/webrtc')

        self.copy('*', dst='{}/include'.format(self.package_folder), src='include', keep_path=True, symlinks=True, ignore_case=True) # assume package as-is, but you can also copy specific files or rearrange
        self.copy('*', dst='{}/lib'.format(self.package_folder), src='lib') # assume package as-is, but you can also copy specific files or rearrange

        #self.copy('*', dst='{}/include'.format(self._source_dir), src='include') # assume package as-is, but you can also copy specific files or rearrange
        #self.copy('*', dst='{}/lib'.format(self._source_dir), src='lib') # assume package as-is, but you can also copy specific files or rearrange

        #self.copy('*', dst='include', src='{}/include'.format(self._source_dir))
        #self.copy('*', dst='lib', src='{}/lib'.format(self._source_dir))

        self.copy(pattern="LICENSE", dst="licenses")

        self.copy('*.cmake', dst='lib', src='{}/lib'.format(self._build_dir), keep_path=True)
        self.copy("*.lib", dst="lib", src="", keep_path=False)
        self.copy("*.a", dst="lib", src="", keep_path=False)
        self.copy("*.dll", dst="lib", src="", keep_path=False)
        self.copy("*.so", dst="lib", src="", keep_path=False)
        #self.copy("*", dst="bin", src="bin")
        #self.copy("*.dll", dst="bin", keep_path=False)

        #self.copy("*", dst="bin", src='{}/javascript/net/grpc/web'.format(self._source_dir))

        tools.rmdir(os.path.join(self.package_folder, "lib", "pkgconfig"))

        # TODO: chmod +x bin/protoc-gen-grpc-web

    def package_info(self):
        #self.cpp_info.includedirs = ['{}/include'.format(self.package_folder)]
        #self.cpp_info.includedirs += ['{}/include/include'.format(self.package_folder)]
        self.cpp_info.includedirs = ['{}/include/webrtc'.format(self.package_folder)]
        self.cpp_info.includedirs += ['{}/include/webrtc/include'.format(self.package_folder)]
        self.env_info.PATH.append(os.path.join(self.package_folder, "bin"))
        self.env_info.LD_LIBRARY_PATH.append(os.path.join(self.package_folder, "lib"))
        self.env_info.PATH.append(os.path.join(self.package_folder, "lib"))
        self.cpp_info.libdirs = ["lib"]
        self.cpp_info.bindirs = ["bin"]
        # collects libupb, make sure to remove 03-simple.a
        self.cpp_info.libs = tools.collect_libs(self)
        #self.cpp_info.libs += ["webrtc_full"]

        if self.settings.compiler == "Visual Studio":
            self.cpp_info.system_libs += ["wsock32", "ws2_32"]
        for libpath in self.deps_cpp_info.lib_paths:
            self.env_info.LD_LIBRARY_PATH.append(libpath)

        #protoc_gen_grpc_web = "protoc-gen-grpc-web.exe" if self.settings.os_build == "Windows" else "protoc-gen-grpc-web"
        #self.env_info.PROTOC_WEB_BIN = os.path.normpath(os.path.join(self.package_folder, "bin", protoc_gen_grpc_web))

        self.cpp_info.names["cmake_find_package"] = "webrtc"
        self.cpp_info.names["cmake_find_package_multi"] = "webrtc"

    # see `conan install . -g deploy` in https://docs.conan.io/en/latest/devtools/running_packages.html
    #def deploy(self):
        #self.copy("*", dst="/usr/local/bin", src="bin", keep_path=False)
        #self.copy("*protoc-gen-grpc-web*", dst="/usr/local/bin", src="bin", keep_path=False)
    #    self.copy("*", dst="bin", src="bin", keep_path=False)