import algorithm, os, osproc, strutils

proc processFile(filePath: string) =
  ## More-pretty a file.
  var
    importNextLineToo = false ## Should import next line?
    imports: seq[string]      ## List of imports in the block.
    blankLines = 0            ## How many blank lines above?
    output: seq[string]       ## Building output lines in this file.

  proc addLine(line: string) =
    for lib in line.split(","):
      let lib = lib.strip()
      if lib.len > 0:
        imports.add(lib)

  for line in readFile(filePath).split("\n"):
    let line = line.replace("\r", "")
    if importNextLineToo:
      addLine(line)
      importNextLineToo = false
      if line.endsWith(","):
        importNextLineToo = true
    elif line.startsWith("import"):
      addLine(line[6..^1])
      if line.endsWith(","):
        importNextLineToo = true
    else:
      if imports.len > 0:
        ## End of import block.
        imports.sort()
        output.add "import " & imports.join(", ")
        imports.setLen(0)

      if line.strip() == "":
        if blankLines > 0:
          continue
        inc blankLines
      else:
        blankLines = 0

      output.add(line)

  writeFile(filePath, output.join("\n").strip(leading = false) & "\n")
  discard execCmdEx("nimpretty " & filePath)

# Walk thorugh all .nim files in this and sub dirs.
for f in walkDirRec(getCurrentDir()):
  if f.endsWith(".nim"):
    echo f
    processFile(f)
