version       = "0.1.0"
author        = "n1ght"
description   = "Modular C header wrapper generator for Nim."
license       = "UNLICENSED"

task build_aes, "Generate wrapper for tiny-AES-c":
  exec "nim r tools/ensure_env.nim -- --submodules --builddirs"
  exec "nim c -r cNimWrapper.nim testCRepos/repos/tiny-AES-c/aes.h testCRepos/builds/tiny-AES-c/aes_wrapper.nim"

task build_blake2, "Generate wrapper for BLAKE2 reference code":
  exec "nim r tools/ensure_env.nim -- --submodules --builddirs"
  exec "nim c -r cNimWrapper.nim testCRepos/repos/BLAKE2/ref/blake2.h testCRepos/builds/BLAKE2/blake2_wrapper.nim"

task build_openssl, "Build OpenSSL 3 and generate wrapper":
  exec "nim r tools/ensure_env.nim -- --submodules --builddirs"
  exec "nim r tools/build_openssl.nim"
  exec "nim c -r cNimWrapper.nim testCRepos/repos/openssl/include/openssl/sha.h testCRepos/builds/openssl/openssl_sha_wrapper.nim"

task build_libsodium, "Build libsodium and generate wrapper":
  exec "nim r tools/ensure_env.nim -- --submodules --builddirs"
  exec "nim r tools/build_libsodium.nim"
  exec "nim r tools/prepare_libsodium_header.nim"
  exec "nim c -r cNimWrapper.nim testCRepos/builds/libsodium/sodium_combined.h testCRepos/builds/libsodium/libsodium_wrapper.nim"

task build_liboqs, "Build liboqs and generate wrapper":
  exec "nim r tools/ensure_env.nim -- --submodules --builddirs"
  exec "nim r tools/build_liboqs.nim"
  exec "nim r tools/prepare_liboqs_header.nim"
  exec "nim c -r cNimWrapper.nim testCRepos/builds/liboqs/oqs_full_combined.h testCRepos/builds/liboqs/liboqs_wrapper.nim"

task build_c_repos_basic, "Build C test repos without OpenSSL":
  exec "nim r tools/ensure_env.nim -- --submodules --builddirs"
  exec "nim r tools/build_libsodium.nim"
  exec "nim r tools/build_liboqs.nim"

task build_c_repos_all, "Build all C test repos":
  exec "nim r tools/ensure_env.nim -- --submodules --builddirs"
  exec "nim r tools/build_openssl.nim"
  exec "nim r tools/build_libsodium.nim"
  exec "nim r tools/build_liboqs.nim"

task build_repos, "Generate wrappers for all test repos":
  exec "nimble build_repos_basic"

task build_repos_basic, "Generate wrappers for test repos without OpenSSL":
  exec "nimble build_aes"
  exec "nimble build_blake2"
  exec "nimble build_libsodium"
  exec "nimble build_liboqs"

task build_repos_all, "Generate wrappers for all test repos":
  exec "nimble build_repos_basic"
  exec "nimble build_openssl"

task setup, "Fetch submodules for test repos":
  exec "nim r tools/ensure_env.nim -- --submodules"

task start, "Fetch submodules and build test wrappers":
  exec "nim r tools/ensure_env.nim -- --submodules --builddirs"
  exec "nimble build_c_repos_basic"
  exec "nimble build_repos_basic"

task test_functionality, "Run tokenizer and utils tests":
  exec "nim r tools/ensure_env.nim -- --submodules --builddirs"
  exec "nim c -r --path:. tests/functionality/test_tokenizer.nim"
  exec "nim c -r --path:. tests/functionality/test_utils.nim"

task test_realworld, "Run real-world wrapper tests":
  exec "nim r tools/ensure_env.nim -- --submodules --builddirs"
  exec "nimble build_c_repos_basic"
  exec "nimble build_repos_basic"
  exec "nim c -r tests/realworld/tiny_aes_c_runner.nim"
  exec "nim c -r tests/realworld/blake2_ref_runner.nim"
  exec "nim c -r tests/realworld/libsodium_runner.nim"
  exec "nim c -r tests/realworld/liboqs_runner.nim"

task test_realworld_all, "Run all real-world wrapper tests":
  exec "nim r tools/ensure_env.nim -- --submodules --builddirs"
  exec "nimble build_c_repos_all"
  exec "nimble build_repos_all"
  exec "nim c -r tests/realworld/tiny_aes_c_runner.nim"
  exec "nim c -r tests/realworld/blake2_ref_runner.nim"
  exec "nim c -r tests/realworld/openssl3_runner.nim"
  exec "nim c -r tests/realworld/libsodium_runner.nim"
  exec "nim c -r tests/realworld/liboqs_runner.nim"

task test_all, "Run all tests":
  exec "nim r tools/ensure_env.nim -- --submodules --builddirs"
  exec "nimble build_c_repos_basic"
  exec "nimble build_repos_basic"
  exec "nim c -r --path:. tests/functionality/test_tokenizer.nim"
  exec "nim c -r --path:. tests/functionality/test_utils.nim"
  exec "nim c -r tests/realworld/tiny_aes_c_runner.nim"
  exec "nim c -r tests/realworld/blake2_ref_runner.nim"
  exec "nim c -r tests/realworld/libsodium_runner.nim"
  exec "nim c -r tests/realworld/liboqs_runner.nim"

task test_all_full, "Run all tests including OpenSSL":
  exec "nim r tools/ensure_env.nim -- --submodules --builddirs"
  exec "nimble build_c_repos_all"
  exec "nimble build_repos_all"
  exec "nim c -r --path:. tests/functionality/test_tokenizer.nim"
  exec "nim c -r --path:. tests/functionality/test_utils.nim"
  exec "nim c -r tests/realworld/tiny_aes_c_runner.nim"
  exec "nim c -r tests/realworld/blake2_ref_runner.nim"
  exec "nim c -r tests/realworld/openssl3_runner.nim"
  exec "nim c -r tests/realworld/libsodium_runner.nim"
  exec "nim c -r tests/realworld/liboqs_runner.nim"

