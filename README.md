
# GITHUB actions for a simple ci workflow

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
- these actions are simple yml defintions defering to powershell script to do the actual work
- GITHUB uploading acheived simply using the "gh" tool preinstalled on the github runner image, again seems to "just work" so long as github token is set
- Logic within the powershell scripts is tested using pester...to execute those test you'll need "import-module pester -f" to force upgrade to v5. Have not yet included those tests in this repo workflow, to do.

Usage:
include these actions in your workflows like this:
```yaml
  steps:
      - name: action-setup
        uses: robinrottier/github-actions/setup
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
      - name: build it
        run: dotnet whatever and zip up the release
      - name: upload
        uses: robinrottier/github-actions/upload
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          files: bin.zip        
```
