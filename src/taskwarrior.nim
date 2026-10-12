#
# Copyright (C) 2021-2022 Johannes Schlatow
#
# This file is part of taskopen, which is distributed under the terms of the
# GNU General Public License version 2.
#

import osproc
import strutils
import regex
import json
import streams
import ./output

const default_args = ["rc.verbose=blank,label,edit", "rc.json.array=on", "rc.gc=off"]

proc concat[I1, I2: static[int]; T](a: array[I1, T], b: array[I2, T]): array[I1 + I2, T] =
  result[0..a.high] = a
  result[a.len..result.high] = b

template exec(taskbin: string, args: openArray[string], res: untyped) =
  debug.log("Executing: ", taskbin, " ", args.join(" "))
  res = execProcess(taskbin, args=args, options = {poUsePath})
  res.stripLineEnd()

proc version*(taskbin: string): string =
  let args = concat(default_args, ["_version"])
  exec(taskbin, args, result)

proc current_context*(taskbin: string, taskargs: openArray[string]): string =
  let args = @default_args & @taskargs & @["context", "show"]
  exec(taskbin, args, result)
  for line in splitLines(result):
    var m = RegexMatch2()
    if line.match(re2".*with filter '(.*)' is currently applied\.$", m):
      return "\\(" & line[m.group(0)] & "\\)"
    elif line.match(re2".*read filter: '(.*)'$", m):
      return "\\(" & line[m.group(0)] & "\\)"
  return ""

proc json*(taskbin: string, taskargs: openArray[string], filter: openArray[string]): JsonNode =
  let args = @default_args & @taskargs & @filter & @["export"]

  debug.log("Executing: ", taskbin, " ", args.join(" "))
  var p = startProcess(taskbin, args=args, options = {poUsePath})
  # note: parseJson(stream) closes the stream, hence read the output first
  #       to keep p.close() from closing an already closed handle.
  #       readAll() stops on a short read and truncates the output when the
  #       pipe drains faster than the child writes (seen on Windows), so
  #       drain the pipe in a loop until end of file instead.
  var output = ""
  var buf: array[4096, char]
  while true:
    let n = outputStream(p).readData(buf[0].addr, buf.len)
    if n <= 0:
      break
    var s = newString(n)
    copyMem(addr s[0], addr buf[0], n)
    output.add s
  result = parseJson(output)
  p.close()

