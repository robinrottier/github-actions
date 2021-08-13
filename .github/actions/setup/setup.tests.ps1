#
# setuo.ps1 cmdlet unit tests
# using "pester" -> requires "install-module pester -force" to make sure we get latest (version 5)
#
""
"Test setup.ps1"
"CD:            $($pwd)"
"PSCommandPath: $PSCommandPath"
"ScriptName:    $($MyInvocation.ScriptName)"
"MyCommandPath: $($MyInvocation.MyCommand.Path)"
""
$setuptarget = $PSCommandPath.Replace(".Tests", "")

#
# run setup target script with supplied github ref env var and return results
# - catenated to single string for easier compare
function invoke-setup($github_ref, $github_run="101", $writeSetOutput=$false, $verbose=0, $resmatch="")
{
    $env:GITHUB_REF = $github_ref
    $env:GITHUB_RUN_NUMBER = $github_run
    $res = . $setuptarget -verbose:$verbose -writeSetOutput:$writeSetOutput -writeRelInfoFile:$false
    if ($resmatch)
    {
        $res = $res | Where-Object { $_ -match $resmatch }
    }
    return $res -join "`r`n"
}

describe "tests" {

    it "test_branch" { invoke-setup "refs/heads/fred" | should -be @"
BUILD_REF: heads/fred
BUILD_SOURCE: branch
BUILD_BRANCH: fred
BUILD_NUM: 101
BUILD_VERSION: 0.1.101
BUILD_VERSION_DBG: 0.1.101-debug
"@
    }

    it "test_branch_full" { invoke-setup "refs/heads/fred" -writeSetOutput:$true | should -be @"
BUILD_REF: heads/fred
::set-output name=BUILD_REF::heads/fred
BUILD_SOURCE: branch
::set-output name=BUILD_SOURCE::branch
BUILD_BRANCH: fred
::set-output name=BUILD_BRANCH::fred
BUILD_NUM: 101
::set-output name=BUILD_NUM::101
BUILD_VERSION: 0.1.101
::set-output name=BUILD_VERSION::0.1.101
BUILD_VERSION_DBG: 0.1.101-debug
::set-output name=BUILD_VERSION_DBG::0.1.101-debug
"@
    }

    it "test_tag" { invoke-setup "refs/tags/v1.2.3" | should -be @"
BUILD_REF: tags/v1.2.3
BUILD_SOURCE: tag
BUILD_TAG: v1.2.3
BUILD_NUM: 101
BUILD_VERSION: 1.2.3
BUILD_VERSION_DBG: 1.2.3-debug
"@
    }

    it "test_tag" { invoke-setup "refs/tags/v1.2.3-prerelease" | should -be @"
BUILD_REF: tags/v1.2.3-prerelease
BUILD_SOURCE: tag
BUILD_TAG: v1.2.3-prerelease
BUILD_NUM: 101
BUILD_VERSION: 1.2.3-prerelease
BUILD_VERSION_DBG: 1.2.3-prerelease-debug
"@
    }

    it "test_ref missing" { { invoke-setup "" } | should -throw "GITHUB_REF missing value" }

    #
    # example data driven tests= cases .. tierate the array and need to pass a testcase to the "It" statement with one-one
    # mappign of variables being used in the statement block
    # - the iteration happens at discovery stage whilst the execution is later
    #
    $versionTests = @(
        ,@("1", "1", "", "", "")
        ,@("1.2", "1", "2", "", "")
        ,@("1.2.3", "1", "2", "3", "")
        ,@("11.22.33", "11", "22", "33", "")
        ,@("1.2.3-x", "1", "2", "3", "x")
        ,@("1.2.3-x-x-x-x-x", "1", "2", "3","x-x-x-x-x")
    )
    foreach ($vt in $versionTests)
    {
        $vt.length | should -be 5
        $v = $vt[0]
        $r = "Version: '"+$vt[1]+"' '"+$vt[2]+"' '"+$vt[3]+"' '"+$vt[4]+"'"
        it "version test $v" -testcases @{"r"=$r; "v"=$v } `
        {
            invoke-setup "refs/tags/v$v" -verbose:1 -resmatch:"^Version:" | should -be $r
        }
    }
}