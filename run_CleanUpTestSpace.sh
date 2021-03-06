#!/bin/bash
#***************************************************************************************
# brief:
#      --clean up all files generated by previous test.
#      --usage: run_CleanUpTestSpace.sh
#
#
#date:  6/09/2015  Created
#***************************************************************************************
runUsage()
{
    echo ""
    echo -e "\033[32m usage: run_CleanUpTestSpace.sh                  \033[0m"
    echo ""
    echo -e "\033[32m clean up all files generated by previous test.  \033[0m"
    echo ""


}

runRemovedPreviousTestData()
{
    git clean -fdx

	if [ -d $AllTestDataFolder ]
	then
		./${ScriptFolder}/run_SafeDelete.sh  $AllTestDataFolder
	fi

	if [ -d $SHA1TableFolder ]
	then
		./${ScriptFolder}/run_SafeDelete.sh  $SHA1TableFolder
	fi

	if [ -d $FinalResultDir ]
	then
		./${ScriptFolder}/run_SafeDelete.sh  $FinalResultDir
	fi

    if [ -d $ReportDir ]
    then
        ./${ScriptFolder}/run_SafeDelete.sh  $ReportDir
    fi

	if [ -d $SourceFolder ]
	then
		./${ScriptFolder}/run_SafeDelete.sh  $SourceFolder
	fi

    for file in ${CurrentDir}/*.log
    do
        ./${ScriptFolder}/run_SafeDelete.sh  ${file}
    done

    for file in ${CurrentDir}/*.txt
    do
        ./${ScriptFolder}/run_SafeDelete.sh  ${file}
    done

    for file in ${CurrentDir}/*.flag
    do
        ./${ScriptFolder}/run_SafeDelete.sh  ${file}
    done

}

runMain()
{
	if [ ! $# -eq 0  ]
	then
        runUsage
		return 0
	fi

	TestType=$1
	SourceFolder=Source
	AllTestDataFolder=AllTestData
	CodecFolder=Codec
	ScriptFolder=Scripts

	CurrentDir=`pwd`
	SHA1TableFolder="SHA1Table"
	FinalResultDir="FinalResult"
    ReportDir="FinalTestReport"

	runRemovedPreviousTestData
	
}
runMain
