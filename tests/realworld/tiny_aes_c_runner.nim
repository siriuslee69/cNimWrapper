import os
import osproc

proc findcNimWrapperDir*(): string =
  ## Returns the cNimWrapper base directory based on this file's location.
  var
    sourceFile: string = currentSourcePath()
    sourceDir: string = ""
    baseDir: string = ""
  sourceDir = splitFile(sourceFile).dir
  baseDir = parentDir(parentDir(sourceDir))
  result = baseDir

proc buildPaths*(a: string): tuple[repoDir: string, buildDir: string, wrapperPath: string,
    testPath: string, wrapperMain: string] =
  ## a: cNimWrapper base directory
  ## Builds repo, build, wrapper, and test paths for tiny-AES-c.
  var
    repoDir: string = joinPath(a, "testCRepos", "repos", "tiny-AES-c")
    buildDir: string = joinPath(a, "testCRepos", "builds", "tiny-AES-c")
    wrapperPath: string = joinPath(buildDir, "aes_wrapper.nim")
    testPath: string = joinPath(a, "tests", "realworld", "tiny_aes_c_test.nim")
    wrapperMain: string = joinPath(a, "cNimWrapper.nim")
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
    baseDir: string = findcNimWrapperDir()
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

