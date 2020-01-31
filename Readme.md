# About

```bash
export PKG_NAME=grpcweb_conan/1.0.7@conan/stable
conan remove $PKG_NAME
conan create . conan/stable -s build_type=Debug --profile gcc --build missing
CONAN_REVISIONS_ENABLED=1 CONAN_VERBOSE_TRACEBACK=1 CONAN_PRINT_RUN_COMMANDS=1 CONAN_LOGGING_LEVEL=10 conan upload $PKG_NAME --all -r=conan-local -c --retry 3 --retry-wait 10 --force
```

## How to diagnose errors in conanfile (CONAN_PRINT_RUN_COMMANDS)

```bash
# NOTE: about `--keep-source` see https://bincrafters.github.io/2018/02/27/Updated-Conan-Package-Flow-1.1/
CONAN_REVISIONS_ENABLED=1 CONAN_VERBOSE_TRACEBACK=1 CONAN_PRINT_RUN_COMMANDS=1 CONAN_LOGGING_LEVEL=10 conan create . conan/stable -s build_type=Debug --profile gcc --build missing --keep-source
```
