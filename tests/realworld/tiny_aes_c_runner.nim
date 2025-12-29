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
    testPath: string, wrapperMain: string] =
  ## a: nimAutoWrapper base directory
  ## Builds repo, build, wrapper, and test paths for tiny-AES-c.
  var
    repoDir: string = joinPath(a, "testCRepos", "repos", "tiny-AES-c")
    buildDir: string = joinPath(a, "testCRepos", "builds", "tiny-AES-c")
    wrapperPath: string = joinPath(buildDir, "aes_wrapper.nim")
    testPath: string = joinPath(a, "tests", "realworld", "tiny_aes_c_test.nim")
    wrapperMain: string = joinPath(a, "nimAutoWrapper.nim")
  result = (repoDir: repoDir, buildDir: buildDir, wrapperPath: wrapperPath, testPath: testPath,
    wrapperMain: wrapperMain)

proc runCmd*(a: string): int =
  ## a: command line string
  ## Executes the command and returns the exit code.
  var
    res: tuple[output: string, exitCode: int] = execCmdEx(a)
  if res.output.len > 0:
    echo res.output
  result = res.exitCode

proc main*() =
  ## Builds tiny-AES-c wrappers and runs ECB tests against known vectors.
  var
    baseDir: string = findNimAutoWrapperDir()
    paths: tuple[repoDir: string, buildDir: string, wrapperPath: string, testPath: string,
      wrapperMain: string] = buildPaths(baseDir)
    headerPath: string = joinPath(paths.repoDir, "aes.h")
    buildCache: string = joinPath(paths.buildDir, "nimcache_wrapper")
    testCache: string = joinPath(paths.buildDir, "nimcache_test")
    wrapperCmd: string = ""
    testCmd: string = ""
    code: int = 0
  if not dirExists(paths.repoDir):
    echo "Repo not found: " & paths.repoDir
    quit(1)
  createDir(paths.buildDir)
  wrapperCmd = "nim c -r --nimcache:" & quoteShell(buildCache) & " " &
    quoteShell(paths.wrapperMain) & " " & quoteShell(headerPath) & " " &
    quoteShell(paths.wrapperPath)
  code = runCmd(wrapperCmd)
  if code != 0:
    quit(code)
  testCmd = "nim c -r --nimcache:" & quoteShell(testCache) & " " &
    quoteShell(paths.testPath)
  code = runCmd(testCmd)
  if code != 0:
    quit(code)

when isMainModule:
  main()
