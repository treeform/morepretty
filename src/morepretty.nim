import algorithm, os, osproc, sequtils, sets, strutils

proc formatBlankLines(input: seq[string]): seq[string] =
  ## Remove \r and excess blank lines.
  var
    blankLines = 0

  for i, line in input:
    let line = line.replace("\r", "")
    if line.strip() == "":
      if blankLines > 0 or i == 0:
        continue
      inc blankLines
    else:
      blankLines = 0

    result.add(line)

proc processFile(filePath: string) =
  ## More-pretty a file.
  var
    importNextLineToo = false ## Should import next line?
    imports: seq[string]      ## List of imports in the block.
    input: seq[string]        ## Initial lines for a step.
    next: seq[string]         ## Set of modified lines passed to next step.
    output: seq[string]       ## Building output lines in this file.

  proc importsLine(line: string) =
    for lib in line.split(","):
      let lib = lib.strip()
      if lib.len > 0:
        imports.add(lib)

  input = readFile(filePath).split("\n")

  # Find all imports at the top of the file (possibly across multiple lines)
  # Add all not-import lines to next
  for line in input:
    if importNextLineToo:
      importsLine(line)
      importNextLineToo = false
      if line.endsWith(","):
        importNextLineToo = true
    elif line.startsWith("import"):
      importsLine(line[6..^1])
      if line.endsWith(","):
        importNextLineToo = true
    else:
      next.add(line)

  # Holds the entire file with "import " lines stripped out
  next = formatBlankLines(next)

  for line in next:
    # File comments before imports
    if line.startsWith("#"):
      output.add(line)
      continue

    # Add imports back after file comments
    if imports.len > 0:
      imports = toSeq(toHashSet(imports)) # Remove duplicate imports
      imports.sort()
      # Add excess blank lines that are removed later
      output.add("")
      output.add("import " & imports.join(", "))
      output.add("")
      imports.setLen(0)

    output.add(line)

  output = formatBlankLines(output)

  writeFile(filePath, output.join("\n").strip(leading = false) & "\n")
  discard execCmdEx("nimpretty " & filePath)

# Walk thorugh all .nim files in this and sub dirs.
for f in walkDirRec(getCurrentDir()):
  if f.endsWith(".nim"):
    echo f
    processFile(f)
