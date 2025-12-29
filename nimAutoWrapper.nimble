version       = "0.1.0"
author        = "n1ght"
description   = "Modular C header wrapper generator for Nim."
license       = "UNLICENSED"

task build_aes, "Generate wrapper for tiny-AES-c":
  exec "nim r tools/ensure_env.nim -- --submodules --builddirs"
  exec "nim c -r nimAutoWrapper.nim testCRepos/repos/tiny-AES-c/aes.h testCRepos/builds/tiny-AES-c/aes_wrapper.nim"

task build_blake2, "Generate wrapper for BLAKE2 reference code":
  exec "nim r tools/ensure_env.nim -- --submodules --builddirs"
  exec "nim c -r nimAutoWrapper.nim testCRepos/repos/BLAKE2/ref/blake2.h testCRepos/builds/BLAKE2/blake2_wrapper.nim"

task build_repos, "Generate wrappers for all test repos":
  exec "nim r tools/ensure_env.nim -- --submodules --builddirs"
  exec "nim c -r nimAutoWrapper.nim testCRepos/repos/tiny-AES-c/aes.h testCRepos/builds/tiny-AES-c/aes_wrapper.nim"
  exec "nim c -r nimAutoWrapper.nim testCRepos/repos/BLAKE2/ref/blake2.h testCRepos/builds/BLAKE2/blake2_wrapper.nim"

task setup, "Fetch submodules for test repos":
  exec "nim r tools/ensure_env.nim -- --submodules"

task start, "Fetch submodules and build test wrappers":
  exec "nim r tools/ensure_env.nim -- --submodules --builddirs"
  exec "nimble build_repos"

task test_functionality, "Run tokenizer and utils tests":
  exec "nim r tools/ensure_env.nim -- --submodules --builddirs"
  exec "nim c -r --path:. tests/functionality/test_tokenizer.nim"
  exec "nim c -r --path:. tests/functionality/test_utils.nim"

task test_realworld, "Run real-world wrapper tests":
  exec "nim r tools/ensure_env.nim -- --submodules --builddirs"
  exec "nimble build_repos"
  exec "nim c -r tests/realworld/tiny_aes_c_runner.nim"
  exec "nim c -r tests/realworld/blake2_ref_runner.nim"

task test_all, "Run all tests":
  exec "nim r tools/ensure_env.nim -- --submodules --builddirs"
  exec "nimble build_repos"
  exec "nim c -r --path:. tests/functionality/test_tokenizer.nim"
  exec "nim c -r --path:. tests/functionality/test_utils.nim"
  exec "nim c -r tests/realworld/tiny_aes_c_runner.nim"
  exec "nim c -r tests/realworld/blake2_ref_runner.nim"
