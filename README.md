
# GITHUB actions for ci workflow

Some utility actions for GITHUB workflows aiming to standardize a simple approach to the ci process, version strings and uploading files to the release on GITHUB. Primarilly written in powershell.

Summary of the process we want to achieve:
- commits to non-master branch ignored for now
- push to master starts a build with version based on "0.1.x" where x is ever incrementing run number from github
- push of a tag with string like "v1.2.3" starts a build with version based on the tag
- the "tag push" acheived by GITHUB "create release" button ... unclear to me what happens if you pushed a tag form some local repo and then created a release from it on GITHUB but ultimately that should work too

We have:
- "setup" action to invoke at start of the workflow - checks git ref and constructs a version string from that, set as an environemtn variable (and workflow outputs) for usein some build stage
- build stage currently as per standard .net build workflows
- "upload" action to upload binaries or any other artifact to the release in GH

Notes:
- "powershell" seems to "just work" on GH runner instances (..that weve used i.e. ubuntu)
- GITHUB uploading acheived simply using the "gh" tool preinstalled on the github runner image
- Logic within the powershell scripts tested using pester...to execute those test you'll need "import-module pester -f" to firce upgrade to v5

Usage:
include these actions in your workflows like this:
```yaml
  steps:
      - name: action-setup
        uses: robinrottier/setup
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
```
