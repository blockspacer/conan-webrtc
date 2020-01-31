from conans import ConanFile, CMake, tools, AutoToolsBuildEnvironment
from conans.errors import ConanInvalidConfiguration, ConanException
from conans.tools import os_info
import os, re, stat, fnmatch, platform
from functools import total_ordering

class grpcwebConan(ConanFile):
    name = "grpcweb_conan"
    version = "1.0.7"
    description = "Google's RPC library and framework."
    topics = ("conan", "grpc", "rpc")
    homepage = "https://github.com/grpc/grpc-web"
    repo_url = 'https://github.com/grpc/grpc-web.git'
    license = "Apache-2.0"
    exports_sources = ["CMakeLists.txt"]
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
        return "source_subfolder"

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

    @property
    def _use_nmake(self):
        return self._is_clangcl or self._is_msvc

    @property
    def _make_program(self):
        if self._use_nmake:
            return "nmake"
        make_program = tools.get_env("CONAN_MAKE_PROGRAM", tools.which("make") or tools.which('mingw32-make'))
        make_program = tools.unix_path(make_program) if tools.os_info.is_windows else make_program
        if not make_program:
            raise Exception('could not find "make" executable. please set "CONAN_MAKE_PROGRAM" environment variable')
        return make_program

    @staticmethod
    def detected_os():
        if tools.OSInfo().is_macos:
            return "Macos"
        if tools.OSInfo().is_windows:
            return "Windows"
        return platform.system()

    @property
    def _cross_building(self):
        if tools.cross_building(self.settings):
            if self.settings.os == self.detected_os():
                if self.settings.arch == "x86" and tools.detected_architecture() == "x86_64":
                    return False
            return True
        return False

    @property
    def _win_bash(self):
        return tools.os_info.is_windows and \
               not self._use_nmake and \
               (self._is_mingw or self._cross_building)

    def requirements(self):
        # TODO: https://github.com/gaeus/conan-grpc
        #self.requires("protobuf/3.6.1@bincrafters/stable")
        self.requires("grpc_conan/v1.26.x@conan/stable")
        self.requires("openssl/OpenSSL_1_1_1-stable@conan/stable")
        self.requires("zlib/v1.2.11@conan/stable")
        self.requires("c-ares/cares-1_15_0@conan/stable")
        self.requires("protobuf/v3.9.1@conan/stable")

    def _run_make(self, targets=None, makefile=None, parallel=True):
        command = [self._make_program]
        if makefile:
            command.extend(["-f", makefile])
        if targets:
            command.extend(targets)
        if not self._use_nmake:
            command.append(("-j%s" % tools.cpu_count()) if parallel else "-j1")
        self.run(" ".join(command), win_bash=self._win_bash)

    def configure(self):
        if self.settings.os == "Windows" and self.settings.compiler == "Visual Studio":
            del self.options.fPIC
            compiler_version = tools.Version(self.settings.compiler.version)
            if compiler_version < 14:
                raise ConanInvalidConfiguration("grpcweb can only be built with Visual Studio 2015 or higher.")

    def source(self):
        # NOTE: about `--recurse-submodules -j8` see https://stackoverflow.com/a/4438292
        #self.run("git clone --recurse-submodules -j8 -b 1.26.x https://github.com/grpc/grpc.git " + self._source_dir)

        # NOTE: without submodules (!!!)
        self.run('git clone --progress --depth 1 --branch {} {} {}'.format(self.version, self.repo_url, self._source_dir))

    def build(self):
        self.output.info('Building package \'{}\''.format(self.name))

        # NOTE: without submodules (!!!)
        #with tools.chdir(self._source_dir + "/third_party/grpc"):
        #    self._run_make(parallel=False)
        #with tools.chdir(self._source_dir + "/third_party/grpc/third_party/protobuf"):
        #    self._run_make(parallel=False)
        with tools.chdir(self._source_dir):
            self._run_make(targets=["plugin"], parallel=False)

    def package(self):
        self.output.info('Packaging package \'{}\''.format(self.name))

        self.copy(pattern="LICENSE", dst="licenses")
        self.copy('*', dst='include', src='{}/include'.format(self._source_dir))
        self.copy('*.cmake', dst='lib', src='{}/lib'.format(self._build_dir), keep_path=True)
        self.copy("*.lib", dst="lib", src="", keep_path=False)
        self.copy("*.a", dst="lib", src="", keep_path=False)
        #self.copy("*", dst="bin", src="bin")
        #self.copy("*.dll", dst="bin", keep_path=False)
        self.copy("*.so", dst="lib", keep_path=False)

        self.copy("*", dst="bin", src='{}/javascript/net/grpc/web'.format(self._source_dir))

        tools.rmdir(os.path.join(self.package_folder, "lib", "pkgconfig"))

        # TODO: chmod +x bin/protoc-gen-grpc-web

    def package_info(self):
        self.cpp_info.includedirs = ['{}/include'.format(self.package_folder)]
        self.env_info.PATH.append(os.path.join(self.package_folder, "bin"))
        self.env_info.LD_LIBRARY_PATH.append(os.path.join(self.package_folder, "lib"))
        self.env_info.PATH.append(os.path.join(self.package_folder, "lib"))
        self.cpp_info.libdirs = ["lib"]
        self.cpp_info.bindirs = ["bin"]
        # collects libupb, make sure to remove 03-simple.a
        self.cpp_info.libs = tools.collect_libs(self)

        if self.settings.compiler == "Visual Studio":
            self.cpp_info.system_libs += ["wsock32", "ws2_32"]
        for libpath in self.deps_cpp_info.lib_paths:
            self.env_info.LD_LIBRARY_PATH.append(libpath)

        protoc_gen_grpc_web = "protoc-gen-grpc-web.exe" if self.settings.os_build == "Windows" else "protoc-gen-grpc-web"
        self.env_info.PROTOC_WEB_BIN = os.path.normpath(os.path.join(self.package_folder, "bin", protoc_gen_grpc_web))

        self.cpp_info.names["cmake_find_package"] = "grpcweb"
        self.cpp_info.names["cmake_find_package_multi"] = "grpcweb"

    # see `conan install . -g deploy` in https://docs.conan.io/en/latest/devtools/running_packages.html
    def deploy(self):
        #self.copy("*", dst="/usr/local/bin", src="bin", keep_path=False)
        #self.copy("*protoc-gen-grpc-web*", dst="/usr/local/bin", src="bin", keep_path=False)
        self.copy("*", dst="bin", src="bin", keep_path=False)