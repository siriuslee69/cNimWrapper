import os
import osproc

const
  aesHeader* = "testCRepos/repos/tiny-AES-c/aes.h"
  blakeHeader* = "testCRepos/repos/BLAKE2/ref/blake2.h"
  opensslHeader* = "testCRepos/repos/openssl/include/openssl/sha.h"
  libsodiumHeader* = "testCRepos/repos/libsodium/src/libsodium/include/sodium/crypto_hash_sha256.h"
  liboqsHeader* = "testCRepos/repos/liboqs/src/common/sha2/sha2.h"

let
  buildDirs* = @[
    "testCRepos/builds/tiny-AES-c",
    "testCRepos/builds/BLAKE2",
    "testCRepos/builds/openssl",
    "testCRepos/builds/libsodium",
    "testCRepos/builds/liboqs"
  ]

proc runCmd*(a: string): int =
  ## a: command line string
  ## Executes the command and returns the exit code.
  var
    res: tuple[output: string, exitCode: int] = execCmdEx(a)
  if res.output.len > 0:
    echo res.output
  result = res.exitCode

proc needSubmodules*(): bool =
  ## Returns true when required submodule headers are missing.
  var
    hasAes: bool = fileExists(aesHeader)
    hasBlake: bool = fileExists(blakeHeader)
    hasOpenSsl: bool = fileExists(opensslHeader)
    hasLibsodium: bool = fileExists(libsodiumHeader)
    hasLiboqs: bool = fileExists(liboqsHeader)
  result = not (hasAes and hasBlake and hasOpenSsl and hasLibsodium and hasLiboqs)

proc ensureSubmodules*() =
  ## Ensures submodules are present, fetching when headers are missing.
  var
    code: int = 0
  if not needSubmodules():
    return
  code = runCmd("git submodule update --init --recursive")
  if code != 0:
    quit(code)

proc ensureBuildDirs*() =
  ## Creates build directories for wrapper outputs.
  var
    i: int = 0
    l: int = buildDirs.len
  while i < l:
    createDir(buildDirs[i])
    inc i

proc main*() =
  ## Runs environment setup based on CLI flags.
  var
    args: seq[string] = commandLineParams()
    doSubmodules: bool = false
    doBuildDirs: bool = false
    i: int = 0
    l: int = args.len
    arg: string = ""
  if l == 0:
    doSubmodules = true
    doBuildDirs = true
  else:
    while i < l:
      arg = args[i]
      if arg == "--submodules":
        doSubmodules = true
      elif arg == "--builddirs":
        doBuildDirs = true
      inc i
  if doSubmodules:
    ensureSubmodules()
  if doBuildDirs:
    ensureBuildDirs()

when isMainModule:
  main()
