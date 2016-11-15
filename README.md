#Cloud Foundry Static Buildpack with S3 support
[![CF Slack](https://s3.amazonaws.com/buildpacks-assets/buildpacks-slack.svg)](http://slack.cloudfoundry.org)

A Cloud Foundry [buildpack](http://docs.cloudfoundry.org/buildpacks/) for static stites (HTML/JS/CSS) with the static assets stored in Amazon Simple Storage Service (S3).
This buildpack was originally forked from the default staticfile buildpack, but since it was modified to support a cloud service provider specific service (S3) it provides capabilities that should not be merged back into a generic buildpack that can run on any CSP.

## Detection
The buildpack will use a file called S3-Staticfile instead of the original Staticfile for detection and additional configuration metadata

## Compile
The buildpack examines the contents of the S3-Staticfile and looks for the following entries
```
ssi: enabled
cached_dirs: {directoryName};{expireTime},{directoryName};{expireTime},...
migrationproxy: {url}
allowonly: {IP Address/CIDR}
```

### Acknowledgements

This buildpack is based heavily upon Jordon Bedwell's Heroku buildpack and the modifications by David Laing for Cloud Foundry [nginx-buildpack](https://github.com/cloudfoundry-community/nginx-buildpack). It has been tuned for usability (configurable with `Staticfile`) and to be included as a default buildpack (detects `Staticfile` rather than the presence of an `index.html`). Thanks for the buildpack Jordon!
