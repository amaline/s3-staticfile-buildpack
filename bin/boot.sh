# ------------------------------------------------------------------------------------------------
# Copyright 2013 Jordon Bedwell.
# Apache License.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
# except  in compliance with the License. You may obtain a copy of the License at:
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the
# License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
# either express or implied. See the License for the specific language governing permissions
# and  limitations under the License.
# ------------------------------------------------------------------------------------------------

export APP_ROOT=$HOME
export LD_LIBRARY_PATH=$APP_ROOT/nginx/lib:$LD_LIBRARY_PATH

conf_file=$APP_ROOT/nginx/conf/nginx.conf
if [ -f $APP_ROOT/public/nginx.conf ]
then
  conf_file=$APP_ROOT/public/nginx.conf
fi

if [ -f $APP_ROOT/nginx/conf/.enable_s3 ]
then
   echo "Enabling s3"
   export AWS_ACCESS_KEY=`echo $VCAP_SERVICES|jq .s3[].credentials.access_key_id`
   export AWS_S3_BUCKET=`echo $VCAP_SERVICES|jq .s3[].credentials.bucket`
   CURRENT_DATE=`date +%Y%m%d`
   if [ "${AWS_REGION}X" == "X" ]
   then
      AWS_REGION="us-east-1"
   fi
   export AWS_SIGNING_KEY_SCOPE="${CURRENT_DATE}/${AWS_REGION}/s3/aws4_request"
   AWS_SECRET=`echo $VCAP_SERVICES|jq .s3[].credentials.secret_access_key`
   export AWS_SIGNING_KEY=`$APP_ROOT/generate_signing_key -k $AWS_SECRET -r $AWS_REGION -s s3 -d $CURRENT_DATE`
   echo "AWS_SIGNING_KEY_SCOPE=${AWS_SIGNING_KEY_SCOPE}"
   echo "AWS_SIGNING_KEY=${AWS_SIGNING_KEY}"
fi

mv $conf_file $APP_ROOT/nginx/conf/orig.conf
erb $APP_ROOT/nginx/conf/orig.conf > $APP_ROOT/nginx/conf/nginx.conf

# ------------------------------------------------------------------------------------------------

mkfifo $APP_ROOT/nginx/logs/access.log
mkfifo $APP_ROOT/nginx/logs/error.log

cat < $APP_ROOT/nginx/logs/access.log &
(>&2 cat) < $APP_ROOT/nginx/logs/error.log &

exec $APP_ROOT/nginx/sbin/nginx -p $APP_ROOT/nginx -c $APP_ROOT/nginx/conf/nginx.conf

# ------------------------------------------------------------------------------------------------
