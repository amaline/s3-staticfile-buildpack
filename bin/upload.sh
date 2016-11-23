#!/bin/bash
#
# Performing an upload of a zip file using this script is useful since by using s3fs
# it will set the metadata of the files in such a way to be owned by vcap:vcap and thus can be used
# by another process that mounts the same bucket using s3fs.
#
# this is not portable to other s3 file system implementations.  There does not seem to be a standard
# for storing metadata incorporating unix file system permissions
######################################################################################################

if [ "$#" -ne 1 ]; then
    echo "Usage: ./upload zipfile"
    exit 100
fi

AWS_ACCESS_KEY=`echo $VCAP_SERVICES|jq --raw-output .s3[].credentials.access_key_id`
AWS_S3_BUCKET=`echo $VCAP_SERVICES|jq --raw-output  .s3[].credentials.bucket`
AWS_SECRET=`echo $VCAP_SERVICES| jq --raw-output  .s3[].credentials.secret_access_key`

echo "${AWS_ACCESS_KEY}:${AWS_SECRET}" > s3cred

mkdir tmpupload

./s3fs $AWS_S3_BUCKET ./tmpupload -o passwd_file=s3cred

unzip $1 -d tmpupload
ls -lR tmpupload
umount ./tmpupload
rm s3cred