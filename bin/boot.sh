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
   export AWS_ACCESS_KEY=`echo $VCAP_SERVICES|jq --raw-output .s3[].credentials.access_key_id`
   export AWS_S3_BUCKET=`echo $VCAP_SERVICES|jq --raw-output  .s3[].credentials.bucket`
   AWS_SECRET=`echo $VCAP_SERVICES| jq --raw-output  .s3[].credentials.secret_access_key`
   
   CURRENT_DATE=`date +%Y%m%d`
   
   if [ "${AWS_REGION}X" = "X" ]
   then
      AWS_REGION="us-east-1"
   fi
   export AWS_SIGNING_KEY_SCOPE=${CURRENT_DATE}/${AWS_REGION}/s3/aws4_request
   
   echo "CURRENT_DATE=${CURRENT_DATE}."
   echo "AWS_REGION=${AWS_REGION}."
   echo "AWS_ACCESS_KEY=${AWS_ACCESS_KEY}"
   echo "AWS_S3_BUCKET=${AWS_S3_BUCKET}"
   echo "AWS_SIGNING_KEY_SCOPE=${AWS_SIGNING_KEY_SCOPE}"
   #echo "AWS_SECRET=${AWS_SECRET}"
   
   export AWS_SIGNING_KEY=`$APP_ROOT/generate_signing_key -k $AWS_SECRET -r $AWS_REGION -s s3 -d $CURRENT_DATE|head -1`
   #echo "AWS_SIGNING_KEY=${AWS_SIGNING_KEY}"
   export AWS_SIGNING_PORT=8000
fi

if [ -f $APP_ROOT/nginx/conf/.enable_cached_dirs ]
then
   echo "Enabling cache directories"
   export NGINX_CACHED_DIRS=`cat $APP_ROOT/nginx/conf/.enable_cached_dirs`
fi

if [ -f $APP_ROOT/nginx/conf/.enable_custom_errorpage ]
then
  echo "Enabling custom error page"
  export HTML_ERROR_PAGE=`cat $APP_ROOT/nginx/conf/.enable_custom_errorpage`
else
  export HTML_ERROR_PAGE=/error.html
fi

mv $conf_file $APP_ROOT/nginx/conf/orig.conf
erb $APP_ROOT/nginx/conf/orig.conf > $APP_ROOT/nginx/conf/nginx.conf
echo "------------------------------- nginx.conf ---------------------------"
cat $APP_ROOT/nginx/conf/nginx.conf
echo "----------------------------------------------------------------------"

mkfifo $APP_ROOT/nginx/logs/access.log
mkfifo $APP_ROOT/nginx/logs/error.log
mkfifo $APP_ROOT/nginx/logs/rebuildconf.log

cat < $APP_ROOT/nginx/logs/access.log &
(>&2 cat) < $APP_ROOT/nginx/logs/error.log &
(>&2 cat) < $APP_ROOT/nginx/logs/rebuildconf.log &

(while sleep 60
    do 
        echo "Rebuild nginx.conf"
        NGINX_PID=`cat $APP_ROOT/nginx/logs/nginx.pid`
        echo "NGINX_PID=$NGINX_PID"
        erb $APP_ROOT/nginx/conf/orig.conf > $APP_ROOT/nginx/conf/nginx.conf #2>> $APP_ROOT/nginx/logs/rebuildconf.log
        echo "[`date`] nginx.conf rebuilt" #>> $APP_ROOT/nginx/logs/rebuildconf.log
        ps -deaf 
        kill -1 $NGINX_PID
    done) &
    
exec $APP_ROOT/nginx/sbin/nginx -p $APP_ROOT/nginx -c $APP_ROOT/nginx/conf/nginx.conf

# ------------------------------------------------------------------------------------------------
