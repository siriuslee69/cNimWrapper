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
  ## Builds repo, build, wrapper, and test paths for BLAKE2 reference code.
  var
    repoDir: string = joinPath(a, "testCRepos", "repos", "BLAKE2", "ref")
    buildDir: string = joinPath(a, "testCRepos", "builds", "BLAKE2")
    wrapperPath: string = joinPath(buildDir, "blake2_wrapper.nim")
    testPath: string = joinPath(a, "tests", "realworld", "blake2_ref_test.nim")
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
  ## Builds BLAKE2 wrappers and runs keyed blake2s tests.
  var
    baseDir: string = findNimAutoWrapperDir()
    paths: tuple[repoDir: string, buildDir: string, wrapperPath: string, testPath: string,
      wrapperMain: string] = buildPaths(baseDir)
    headerPath: string = joinPath(paths.repoDir, "blake2.h")
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
  testCmd = "nim c -r --nimcache:" & quoteShell(testCache) & " --path:" &
    quoteShell(paths.buildDir) & " " & quoteShell(paths.testPath)
  code = runCmd(testCmd)
  if code != 0:
    quit(code)

when isMainModule:
  main()
