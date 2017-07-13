#!/usr/bin/env python
# -*- coding: utf-8 -*-
#> colored_output.py
"""
Author: Daein
Date: 2016.8
Version: 1.2.0
Description: the font color of the contents is changed to the gradation of colors.
History:
  2016.8 - ver1.0 input file was fixed name.
         - ver1.1 input file was first argument.
         - ver1.2 the target resource was passed by stdin or argument(file)
"""

from __future__ import print_function
import sys, os, logging, fileinput

#> logging setup
logging.basicConfig(level=logging.DEBUG,format='%(asctime)s : %(levelname)s :: %(message)s')
#> if you want to debug this script, comment out the following line.
logging.disable(logging.CRITICAL)
logging.debug(sys.version_info)

#> global variable
prefix = "\033[38;5;"
revertWhite = "\033[0m"
fileLines = []

usageMsg = """Usage: {basename} targetfile
\tcat targetfile | {basename} --stdin
""".format(basename=str(sys.argv[0]))

if len(sys.argv) != 2:
    print(usageMsg, file=sys.stderr)
    exit(1)

elif str(sys.argv[1]) == "--stdin":
    fileLines = sys.stdin.readlines()

elif os.path.isfile(sys.argv[1]):
    with open(sys.argv[1], 'r') as motdFile:
        for line in motdFile.readlines():
            fileLines.append(line)

else:
    print(usageMsg, file=sys.stderr)
    exit(1)

lineCnt = len(fileLines)
colCntPerLine = []

for line in fileLines:
    colCntPerLine.append(len(line))

for line in range(lineCnt):
    for col in range(colCntPerLine[line]):
        tmp = prefix + str(col + (110 - (int(col) % 5) )) + "m" + fileLines[line][col]
        print(tmp, end="")
    print(revertWhite, end="")

print(revertWhite)

##+ for debugging
#
##for n in range(1,144):
##  tmp = prefix + str(n) + "m"
##  print(tmp + str(n),end=" ")
##
##print(revertWhite)
