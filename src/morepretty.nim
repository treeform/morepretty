import algorithm, os, osproc, sequtils, sets, strutils

proc formatLines(input: seq[string]): seq[string] =
  ## Remove \r and excess blank lines.
  var
    blankLines = 0

  for i, line in input:
    var line = line.replace("\r", "")
    if line.strip() == "":
      if blankLines > 0 or i == 0:
        continue
      inc blankLines
    else:
      blankLines = 0

      if line[^1] == ';':
        line = line[0..^2]

    result.add(line)

proc importsExports(s: var seq[string], line: string) =
  for lib in line.split(","):
    let lib = lib.strip()
    if lib.len > 0:
      s.add(lib)

proc processFile(filePath: string) =
  ## More-pretty a file.
  var
    imports, exports: seq[string]      ## List of imports in the block.
    next: seq[string]         ## Set of modified lines passed to next step.
    output: seq[string]       ## Building output lines in this file.
    input = readFile(filePath).split("\n")
    firstImportLine = len(input)
    firstExportLine = len(input)
    importNextLineToo = false ## Should import next line?
    exportNextLineToo = false

  # Find all imports at the top of the file (possibly across multiple lines)
  # Add all not import and export lines to next
  for i, line in input:
    if importNextLineToo:
      importsExports(imports, line)
      importNextLineToo = false
      if line.endsWith(","):
        importNextLineToo = true
    elif exportNextLineToo:
      importsExports(exports, line)
      exportNextLineToo = false
      if line.endsWith(","):
        exportNextLineToo = true
    elif line.startsWith("import") and "except" notin line:
      firstImportLine = min(i, firstImportLine)
      importsExports(imports, line[6..^1])
      if line.endsWith(","):
        importNextLineToo = true
    elif line.startsWith("export") and "except" notin line:
      firstExportLine = min(i, firstExportLine)
      importsExports(exports, line[6..^1])
      if line.endsWith(","):
        exportNextLineToo = true
    else:
      next.add(line)

  # Holds the entire file with "import " lines stripped out
  next = formatLines(next)

  proc writeSorted(label: string, items: seq[string]): string =
    var items = toSeq(toHashSet(items)) # Remove duplicates
    items.sort()
    label & items.join(", ")

  proc writeImports() =
    # Add excess blank lines that are removed later
    output.add("")
    output.add(writeSorted("import ", imports))
    output.add("")
    imports.setLen(0)

  proc writeExports() =
    # Add excess blank lines that are removed later
    output.add("")
    output.add(writeSorted("export ", exports))
    output.add("")
    exports.setLen(0)

  for i, line in next:
    # File comments before imports (must have come before first import line)
    if (line.startsWith("#") or line == "") and i < firstImportLine:
      output.add(line)
      continue

    # Add imports back after file comments
    if imports.len > 0:
      writeImports()

    # Any comments before exports (must have come before first export line)
    if (line.startsWith("#") or line == "") and i < firstExportLine:
      output.add(line)
      continue

    # Add exports back
    if exports.len > 0:
      writeExports()

    output.add(line)

  # In the case we've removed enough lines that these never have chance to get
  # written. This isn't likely but can happen.
  if len(imports) > 0:
    writeImports()
  if len(exports) > 0:
    writeExports()

  output = formatLines(output)

  writeFile(filePath, output.join("\n").strip(leading = false) & "\n")
  discard execCmdEx("nimpretty --indent:2 " & filePath)

# Walk thorugh all .nim files in this and sub dirs.
for f in walkDirRec(getCurrentDir()):
  if f.endsWith(".nim"):
    echo f
    processFile(f)
