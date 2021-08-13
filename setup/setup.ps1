param(
	[string]$token="",
	[bool]$writeSetOutput=$true,
	[bool]$writeRelInfoFile=$true,
	[int]$verbose=0
)

if ($verbose -ge 1)
{
	""
	"Action-setup"
	"============"
	"token:          $token"
	"writeSetOutput: $writeSetOutput"
	"verbose:        $verbose"
	"gh_env:		 $env:GITHUB_ENV"
	""
}

$env:GITHUB_TOKEN=$token

#
# inputs to this function from environment block
#
$gh_ref = $env:GITHUB_REF
$gh_env = $env:GITHUB_ENV
$gh_run = $env:GITHUB_RUN_NUMBER

if ($writeRelInfoFile)
{
	$rel_txt = "bin/release.txt"
	if (-not (test-path $rel_txt)) { new-item $rel_txt -force >$null }
	if ($rel_txt)
	{
		set-content $rel_txt @"
Release info
============
TIMESTAMP: $([datetime]::UtcNow.ToString("HH:mm:ss DD/MM/YYYY"))
"@
	}
}
else
{
	$rel_txt = ""
}

function set-value ($name, $value)
{
	Write-Output "$($name): $value"
	Set-Variable -Name $name -Value $value -Scope "script"
	Set-Item -Path "env:$name" -Value $value
	if ($writeSetOutput)
	{
		Write-output "::set-output name=$name::$value"
	}
	if ($gh_env)
	{
		Add-Content $gh_env "$name=$value"
	}
	if ($rel_txt)
	{
		Add-Content $rel_txt "$name=$value"
	}
}

function failed($msg)
{
	throw $msg
}

#
# check git ref source for build and set useful env from that
#
if (-not $gh_ref)
{
	failed "GITHUB_REF missing value"
}
$s_refs = "refs/"
if (-not $gh_ref.StartsWith($s_refs))
{
	failed "GITHUB_REF unexpected value ($ref)"
}
set-value "BUILD_REF" $gh_ref.Substring($s_refs.Length)

$s_heads = "heads/"
$s_tags = "tags/"
if ($build_ref.StartsWith($s_heads))
{
	$build_is_tag = $false
	set-value "BUILD_SOURCE" "branch"
	set-value "BUILD_BRANCH" $build_ref.Substring($s_heads.Length)
}
elseif ($build_ref.StartsWith($s_tags))
{
	$build_is_tag = $true
	set-value "BUILD_SOURCE" "tag"
	set-value "BUILD_TAG" $build_ref.Substring($s_tags.Length)
	#
	# to have invoked this tag should look like a version
	#
	if ($build_tag -notmatch "v\d+(\.\d+(\.\d+(-[\w-]+)?)?)?")
	{
		failed "GITHUB_REF tag expected match to 'v<maj>.<min>.<patch>-<label>' (was $build_tag)"
	}
}
else
{
	failed "GITHUB_REF expecting branch or tag ($env:build_ref)"
}

#
# unique, incrementing, build number
#
if (-not $gh_run)
{
	failed "GITHUB_RUN missing value"
}
[int]$gh_runn = 0
if (-not [int]::TryParse($gh_run, [ref]$gh_runn))
{
	failed "GITHUB_RUN expecting number (was $gh_run)"

}
set-value "BUILD_NUM" $gh_runn

#
# create version string we can use for builds
#
if ($build_is_tag)
{
	# for tagged build version is the tag without the "v"
	$ver = $build_tag
	if ($ver.StartsWith("v"))
	{
		$ver = $ver.Substring(1)
	}
}
else
{
	# for branch builds make up a version
	$ver = "0.1.$gh_run"
}

# double check version
#...shoudl never fail as previously checked anyway
# - and reat this to capture matches
if ($ver -notmatch "(\d+)(?:\.(\d+)(?:\.(\d+)(?:-([\w-]+))?)?)?")
{
	failed("Unexpected version in setup: $ver")
}

#
# decompose
#
$ver_major = $Matches[1]
$ver_minor = $matches[2]
$ver_patch = $Matches[3]
$ver_label = $Matches[4]
if ($verbose -ge 1)
{
	"Version: '$ver_major' '$ver_minor' '$ver_patch' '$ver_label'"
}

$ver_dbg = "$ver-debug"

set-value "BUILD_VERSION" $ver
set-value "BUILD_VERSION_DBG" $ver_dbg

#
# if its a tag then uoload release text 
#
if ($writeRelInfoFile -and $build_is_tag)
{
	gh release upload $build_tag $rel_txt --clobber
}
