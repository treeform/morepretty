# morepretty - More pretty than nimpretty.

`nimble install morepretty`

![Github Actions](https://github.com/treeform/morepretty/workflows/Github%20Actions/badge.svg)

[API reference](https://nimdocs.com/treeform/morepretty)

This library has no dependencies other than the Nim standard library.

## nimpretty does not ...

* organize imports
* remove blank lines
* convert windows to unix line endings
* insert a single line at the end of files for git
* pretty the whole dir tree at once

**so morepretty does all of that!**

morepretty runs nimpretty too so you only ever need to run one command to format your code.
