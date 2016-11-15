#Cloud Foundry Static Buildpack with S3 support
[![CF Slack](https://s3.amazonaws.com/buildpacks-assets/buildpacks-slack.svg)](http://slack.cloudfoundry.org)

A Cloud Foundry [buildpack](http://docs.cloudfoundry.org/buildpacks/) for static stites (HTML/JS/CSS) with the static assets stored in Amazon Simple Storage Service (S3).
This buildpack was originally forked from the default staticfile buildpack, but since it was modified to support a cloud service provider specific service (S3) it provides capabilities that should not be merged back into a generic buildpack that can run on any CSP.

This buildpack is dependent upon a custom build of nginx that incorporates the ngx_aws_auth module from https://github.com/anomalizer/ngx_aws_auth, currently forked and patched at https://github.com/amaline/ngx_aws_auth

## Detection
The buildpack will use a file called S3-Staticfile instead of the original Staticfile for detection and additional configuration metadata

## Compile
The buildpack examines the contents of the S3-Staticfile and looks for the following entries
```
ssi: enabled
cached_dirs: {directoryName};{expireTime},{directoryName};{expireTime},...
migrationproxy: {url}
errorpage: {customErrorPage.html}
allowonly: {IP Address/CIDR}
```

* The 'ssi: enabled' will enable server side includes.  Since SSI calls enabled within the same server as the AWS signing were not being signed, a separate server listening only on localhost:8080 is established in order to perform the signing, while the SSI is defined in the initial server listening on the Cloud Foundry defined port.
* 'cached_dirs:' defines a set of directories that will be cached onto the local ephemeral disk and have the expires header set for the cooresponding period of time.
* 'migrationproxy:' defines a secondary proxy_pass to send requests if the original call to S3 returns a 404 error.  This enables a legacy web server to be used as a pass through during a migration process.
* 'errorpage:' is mutually exclusive with 'migrationproxy:' and will be ignored if 'migrationproxy:' is set.  It defines a custom web page in case of a 404 error.
* 'allowonly:' will enable trusting of the 'x-forwarded-for' header from the Cloud Foundry router and limit calls to a IP address in CIDR format.

### Acknowledgements

This buildpack is based heavily upon Jordon Bedwell's Heroku buildpack and the modifications by David Laing for Cloud Foundry [nginx-buildpack](https://github.com/cloudfoundry-community/nginx-buildpack). It has been tuned for usability (configurable with `Staticfile`) and to be included as a default buildpack (detects `Staticfile` rather than the presence of an `index.html`). Thanks for the buildpack Jordon!
