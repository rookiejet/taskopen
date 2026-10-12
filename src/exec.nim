#
# Copyright (C) 2021-2022 Johannes Schlatow
#
# This file is part of taskopen, which is distributed under the terms of the
# GNU General Public License version 2.
#

import osproc
import strtabs

when defined(windows):
  import os

  proc translateVars(cmd: string): string =
    ## Translate `$VAR` references into `%VAR%` references.
    ##
    ## Commands are evaluated by cmd.exe on Windows, which expands `%VAR%`
    ## from the environment rather than `$VAR`. Translating the references
    ## keeps commands written for POSIX shells working on Windows. Anything
    ## that is already written as `%VAR%` is passed through unchanged.
    result = newStringOfCap(cmd.len)
    var i = 0
    while i < cmd.len:
      if cmd[i] == '$' and i+1 < cmd.len and
         (cmd[i+1] in {'A'..'Z', 'a'..'z', '_'}):
        var j = i+1
        while j < cmd.len and (cmd[j] in {'A'..'Z', 'a'..'z', '0'..'9', '_'}):
          inc j
        result.add('%')
        result.add(cmd.substr(i+1, j-1))
        result.add('%')
        i = j
      else:
        result.add(cmd[i])
        inc i

  proc shellCommand*(cmd: string): string =
    ## Evaluate `cmd` with cmd.exe, the native Windows shell.
    ##
    ## As `poEvalCommand` passes the string as a raw command line to
    ## CreateProcess (there is no shell involved on Windows), cmd.exe is
    ## invoked explicitly. `/s /c` makes cmd.exe strip exactly the outermost
    ## pair of quotes and evaluate the remainder verbatim.
    var comspec = getEnv("COMSPEC")
    if comspec.len == 0:
      comspec = "cmd.exe"
    result = "\"" & comspec & "\" /s /c \"" & translateVars(cmd) & "\""
else:
  proc shellCommand*(cmd: string): string =
    ## Evaluate `cmd` with /bin/sh (see `poEvalCommand`).
    cmd

proc exec_filter*(cmd: string, env: StringTableRef = nil): bool {.inline.} =
  return execCmdEx(shellCommand(cmd), env=env).exitCode == 0

iterator exec_inline*(cmd: string, env: StringTableRef = nil): string =
  var p = startProcess(shellCommand(cmd), env=env, options={poEvalCommand})
  for line in p.lines:
    yield line
  p.close()

proc exec_cmd*(cmd: string, env: StringTableRef = nil): int {.inline.} =
  let p = startProcess(shellCommand(cmd), env=env, options={poEvalCommand, poParentStreams})
  result= p.waitForExit()
  p.close()

proc exec_all*(cmds: openArray[tuple[cmd: string, env: StringTableRef]]): tuple[num: int, exitCode: int] =
  ## execute all commands and return the number of successfully executed commands

  result.num = 0
  for cmd in cmds:
    let p = startProcess(shellCommand(cmd.cmd), env=cmd.env, options={poEvalCommand, poParentStreams})
    let code = p.waitForExit()
    p.close()
    if code != 0:
      result.exitCode = code
      return result
    inc(result.num)

when isMainModule:
  assert(exec_filter("ls -l"))
  assert(not exec_filter("lasdfasdf -l -a -z"))
  for i in exec_inline("ls -l"):
    echo i
