param(
	[string]$upload_tag="",
	[string]$files="",
	[string]$token="",
	[int]$verbose=0
)

if ($verbose -ge 1)
{
	""
	"Actions-upload"
	"============"
	"upload_tag:     $upload_tag"
	"files:          $files"
	"token:          $token"
	""
}

if ($token)
{
	$env:GITHUB_TOKEN=$token
}

function failed($msg)
{
	throw $msg
}

if (-not $files)
{
	failed("No files spepcified")
}

$filecount=0

# get source of build and its tag -- set by setup.ps1 ina previous step
if (-not $upload_tag)
{
	$build_source = $env:BUILD_SOURCE
	$build_tag = $env:BUILD_TAG
	if ($build_source -eq "tag")
	{
		if (-not $build_tag)
		{
			failed("Expecting build tag to be set for release string")
		}
		$upload_tag = $build_tag
	}
	elseif ($build_source -eq "branch")
	{
		# branch build...no tag to upload to
	}
	else
	{
		failed("Expecting build_source set from setup action to either branch or tag")	
	}
}

if ($upload_tag)
{
	gh release upload $upload_tag $files --clobber
	$filecount++
	write-output "uploaded: $files"
}

write-output "::set-output name=filecount::$filecount"
