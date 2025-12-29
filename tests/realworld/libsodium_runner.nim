import os
import osproc

proc findNimAutoWrapperDir*(): string =
  ## Returns the nimAutoWrapper base directory from the current working directory.
  ## Falls back to the current directory when the folder is not found.
  var
    cwd: string = getCurrentDir()
    head: string = ""
    tail: string = ""
    candidate: string = ""
    baseDir: string = ""
  (head, tail) = splitPath(cwd)
  if tail == "nimAutoWrapper":
    baseDir = cwd
  else:
    candidate = joinPath(cwd, "nimAutoWrapper")
    if dirExists(candidate):
      baseDir = candidate
    else:
      baseDir = cwd
  result = baseDir

proc buildPaths*(a: string): tuple[repoDir: string, buildDir: string, wrapperPath: string,
    testPath: string, wrapperMain: string, installDir: string, libDir: string, binDir: string] =
  ## a: nimAutoWrapper base directory
  ## Builds repo, build, wrapper, and test paths for libsodium headers.
  var
    repoDir: string = joinPath(a, "testCRepos", "repos", "libsodium")
    buildDir: string = joinPath(a, "testCRepos", "builds", "libsodium")
    wrapperPath: string = joinPath(buildDir, "libsodium_wrapper.nim")
    testPath: string = joinPath(a, "tests", "realworld", "libsodium_test.nim")
    wrapperMain: string = joinPath(a, "nimAutoWrapper.nim")
    installDir: string = joinPath(buildDir, "install")
    libDir: string = joinPath(installDir, "lib")
    binDir: string = joinPath(installDir, "bin")
  result = (repoDir: repoDir, buildDir: buildDir, wrapperPath: wrapperPath, testPath: testPath,
    wrapperMain: wrapperMain, installDir: installDir, libDir: libDir, binDir: binDir)

proc runCmd*(a: string): int =
  ## a: command line string
  ## Executes the command and returns the exit code.
  var
    res: tuple[output: string, exitCode: int] = execCmdEx(a)
  if res.output.len > 0:
    echo res.output
  result = res.exitCode

proc sharedLibEnvKey*(): string =
  ## Returns the environment key for shared library lookup on the platform.
  var
    key: string = ""
  when defined(windows):
    key = "PATH"
  elif defined(macosx):
    key = "DYLD_LIBRARY_PATH"
  else:
    key = "LD_LIBRARY_PATH"
  result = key

proc prependEnvPath*(a: string, b: string) =
  ## a: environment variable name
  ## b: path to prepend
  ## Prepends a path to an environment variable.
  var
    current: string = getEnv(a)
    combined: string = ""
  if current.len == 0:
    combined = b
  else:
    combined = b & $PathSep & current
  putEnv(a, combined)

proc buildLinkFlags*(a: string): string =
  ## a: library directory
  ## Builds linker flags for libsodium.
  var
    flags: string = "--passL:-lsodium"
  when defined(windows):
    flags = flags & " --passL:-lws2_32 --passL:-liphlpapi --passL:-ladvapi32"
  elif defined(linux):
    flags = flags & " --passL:-ldl --passL:-pthread"
  result = flags

proc main*() =
  ## Builds libsodium wrappers and runs SHA256 tests against known vectors.
  var
    baseDir: string = findNimAutoWrapperDir()
    paths: tuple[repoDir: string, buildDir: string, wrapperPath: string, testPath: string,
      wrapperMain: string, installDir: string, libDir: string, binDir: string] = buildPaths(baseDir)
    headerPath: string = joinPath(paths.buildDir, "sodium_combined.h")
    buildCache: string = joinPath(paths.buildDir, "nimcache_wrapper")
    testCache: string = joinPath(paths.buildDir, "nimcache_test")
    wrapperCmd: string = ""
    testCmd: string = ""
    buildCmd: string = ""
    prepareCmd: string = ""
    envKey: string = ""
    envPath: string = ""
    libEnvKey: string = ""
    linkFlags: string = ""
    code: int = 0
  if not dirExists(paths.repoDir):
    echo "Repo not found: " & paths.repoDir
    quit(1)
  createDir(paths.buildDir)
  buildCmd = "nim r tools/build_libsodium.nim"
  code = runCmd(buildCmd)
  if code != 0:
    quit(code)
  prepareCmd = "nim r tools/prepare_libsodium_header.nim"
  code = runCmd(prepareCmd)
  if code != 0:
    quit(code)
  wrapperCmd = "nim c -r --nimcache:" & quoteShell(buildCache) & " " &
    quoteShell(paths.wrapperMain) & " " & quoteShell(headerPath) & " " &
    quoteShell(paths.wrapperPath)
  code = runCmd(wrapperCmd)
  if code != 0:
    quit(code)
  envKey = sharedLibEnvKey()
  when defined(windows):
    envPath = paths.binDir
  else:
    envPath = paths.libDir
  prependEnvPath(envKey, envPath)
  libEnvKey = "LIBRARY_PATH"
  prependEnvPath(libEnvKey, paths.libDir)
  linkFlags = buildLinkFlags(paths.libDir)
  testCmd = "nim c -r --nimcache:" & quoteShell(testCache) & " " & linkFlags &
    " " & quoteShell(paths.testPath)
  code = runCmd(testCmd)
  if code != 0:
    quit(code)

when isMainModule:
  main()
