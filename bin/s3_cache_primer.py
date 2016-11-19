import boto
import os
import urllib2
import sys

argCount=len(sys.argv)
if argCount < 3:
   print "Usage: python " + sys.argv[0] + " url cached_dirs [instances]"
   sys.exit(100)

url=sys.argv[1]
if not url.endswith('/'):
  url=url + '/'

cached_dirs=sys.argv[2].split(',')

if argCount == 4:
    instances=int(sys.argv[3])
else:
    instances=1

print "URL: " + url
print "Cached Directories: " + str(cached_dirs)

conn = boto.connect_s3()
bucket = conn.get_bucket(os.environ['BUCKET'])
errorCount=0
for dir in cached_dirs:
    #filter="prefix='" + dir.split(';')[0] + "/'"
    filter=dir.split(';')[0]
    print "Pattern: " + filter
    for key in bucket.list(prefix=filter):
        uri= url + key.name.encode('utf-8')
        uri= urllib2.quote(uri,':/')
        
        try:
           for i in range(1,instances+1):
              print "{0}) {1}".format(i,uri)
              urllib2.urlopen(uri).read()
        except urllib2.HTTPError as e:
           print "		HTTP Error: " + uri
           print "               ",e
           errorCount+=1
           if erroCount == 4:
              sys.exit(100)