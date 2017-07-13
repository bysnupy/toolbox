#!/usr/bin/python3.4
"""
 #> File:    faces_table.py
 #- Author:  Daein
 #- Version: 1.1
 #- Usage:   faces_table.py
 #+ History:
  #- 2016/08/04: v1.0 release
  #- 2016/08/05: v1.1 release, adding feature which resizes face images.
"""

import sys,csv,os,datetime
from PIL import Image

#> global variables
"""
CSV format is following:

name,kana,department,id_number,gender,hired_date(YYYY/mm/dd),years_of_work,phote(empty)
"""
csvFilePath = '/path/to/face_data.csv'

# The face image files are converted fixed size and located a right-most column in face table.
imgOrigDirPath  = '/path/to/original/imagefiles/orig'
imgConvDirPath  = '/path/to/converted/imagefiles/conv'

resultHtmlPath = '/path/to/faces_table/with/permited/from/webserver/index.html'


##+ for debugging
#
#if len(sys.argv) != 2:
#    print("Usage: " + str(os.path.basename(sys.argv[0])) + " csvFile ",file=sys.stderr)
#    exit(1)

#> the absolute path of the target csv file.
#csvFilePath = os.path.abspath(sys.argv[1])
if not os.path.isfile(csvFilePath):
    print("error: not existing the csvfile.", file=sys.stderr)
    exit(1)

#> resizing face images.
for imgFile in os.listdir(imgOrigDirPath):
    tmpImgFile = Image.open(os.path.join(imgOrigDirPath, imgFile))
    tmpWidth, tmpHeight = tmpImgFile.size
    #> ratio
    #tmpResizeImg = tmpImgFile.resize((int(tmpWidth / 14),int(tmpHeight / 14)))
    #> fixed size
    tmpResizeImg = tmpImgFile.resize((370, 277))
    tmpResizeImg.save(os.path.join(imgConvDirPath,imgFile))

#> reading csv file.
csvFile = open(csvFilePath,'r')

csvReader = csv.reader(csvFile)

htmlContent = '''
<html>
<head>
<title>Face image table</title>
<link rel="stylesheet" href="/bluetable.css" type="text/css" />
<script type="text/javascript" src="/jquery-3.1.0.min.js"></script>
<script type="text/javascript" src="/jquery.tablesorter.min.js"></script>
</head>
<body>
<script>
$(document).ready(function()
    {
        $("#faceTable").tablesorter();
    }
);

</script>
<table id="faceTable" class="tablesorter">
'''
htmlTheader = ['<thead>']
htmlTbody = ['<tbody>']

for row in csvReader:
    if csvReader.line_num == 1:
        tmpList = [ "<th>" + str(x) + "</th>" for x in row ]
        htmlTheader.extend(['<tr>'])
        htmlTheader.extend(tmpList)
        htmlTheader.extend(['</tr>'])
        continue
    tmpList = [ '<td>' + str(y) + "</td>" for y in row ]
    tmpList[-1] = '<td><img src="/img/after/' + str(row[3]) + '.jpg" /></td>'

    htmlTbody.extend([ "<tr>" ])
    htmlTbody.extend(tmpList)
    htmlTbody.extend([ "</tr>" ])

htmlTheader.extend([ "</thead>" ])
htmlTbody.extend([ "</tbody>" ])

htmlContent = htmlContent + ''.join(htmlTheader) + '\n'.join(htmlTbody) + '''
</table>
<p align="right">Updated: %s</p>
</body>
</html>''' % str(datetime.datetime.now())

resultFile = open(resultHtmlPath,'w')
resultFile.write(htmlContent)
resultFile.close()
