#!/bin/bash
#***************************************************************************************
# brief:
#      --parse all completed SGE jobs' test status----passed all cases or not
#        parse based on test report file under ./FinalRsult/TestReport_*
#      --usage:  ./run_ParseSGEJobPassStatus.sh ${Option}
#
#      --e.g.:  ./run_ParseSGEJobPassStatus.sh FailedJobID
#      --e.g.:  ./run_ParseSGEJobPassStatus.sh FailedJobName
#      --e.g.:  ./run_ParseSGEJobPassStatus.sh FailedJobUnpassedNum
#      --e.g.:  ./run_ParseSGEJobPassStatus.sh SucceedJobID
#      --e.g.:  ./run_ParseSGEJobPassStatus.sh SucceedJobName
#      --e.g.:  ./run_ParseSGEJobPassStatus.sh SucceedJobPassedNum
#      --e.g.:  ./run_ParseSGEJobPassStatus.sh UnRunCaseJobID
#      --e.g.:  ./run_ParseSGEJobPassStatus.sh UnRunCaseJobName
#
#date: 05/012/2014 Created
#***************************************************************************************

runUsage()
{
    echo ""
    echo -e "\033[31m usage:  ./run_ParseSGEJobPassStatus.sh \${Option}              \033[0m"
    echo ""
    echo -e "\033[32m e.g.:  1) get failed jobs' ID list                             \033[0m"
    echo -e "\033[32m          ./run_ParseSGEJobPassStatus.sh FailedJobID            \033[0m"
    echo ""
    echo -e "\033[32m e.g.:  2) get failed jobs' name list                           \033[0m"
    echo -e "\033[32m          ./run_ParseSGEJobPassStatus.sh FailedJobName          \033[0m"
    echo ""
    echo -e "\033[32m e.g.:  3) get failed jobs' un-passed cases num                 \033[0m"
    echo -e "\033[32m          ./run_ParseSGEJobPassStatus.sh FailedJobUnpassedNum   \033[0m"
    echo ""
    echo -e "\033[32m e.g.:  4) get succeed jobs' ID list                            \033[0m"
    echo -e "\033[32m          ./run_ParseSGEJobPassStatus.sh SucceedJobID           \033[0m"
    echo ""
    echo -e "\033[32m e.g.:  5) get succeed jobs' name list                          \033[0m"
    echo -e "\033[32m          ./run_ParseSGEJobPassStatus.sh SucceedJobName         \033[0m"
    echo ""
    echo -e "\033[32m e.g.:  6) get succeed jobs' passed cases num                   \033[0m"
    echo -e "\033[32m          ./run_ParseSGEJobPassStatus.sh SucceedJobPassedNum    \033[0m"
    echo ""
    echo -e "\033[32m e.g.:  7) get un-run case jobs' ID list(e.g.:YUV not found)    \033[0m"
    echo -e "\033[32m          ./run_ParseSGEJobPassStatus.sh UnRunCaseJobID         \033[0m"
    echo ""
    echo -e "\033[32m e.g.:  8) get all jobs' host name list                         \033[0m"
    echo -e "\033[32m          ./run_ParseSGEJobPassStatus.sh AllHostsName           \033[0m"
    echo ""
    echo -e "\033[32m e.g.:  9) get all jobs' ID list                                \033[0m"
    echo -e "\033[32m          ./run_ParseSGEJobPassStatus.sh AllCompletedJobsID     \033[0m"
    echo ""
    echo -e "\033[32m e.g.:  10) get failed jobs' test Dir list                      \033[0m"
    echo -e "\033[32m          ./run_ParseSGEJobPassStatus.sh FailedJobTestDir       \033[0m"
    echo ""
    echo -e "\033[32m e.g.:  11) get succeed jobs' test Dir list                     \033[0m"
    echo -e "\033[32m          ./run_ParseSGEJobPassStatus.sh SucceedJobTestDir      \033[0m"
    echo ""
    echo -e "\033[32m e.g.:  12) get un-runCases jobs' test Dir list                 \033[0m"
    echo -e "\033[32m          ./run_ParseSGEJobPassStatus.sh UnRunCaseJobTestDir    \033[0m"
    echo ""

}

runInitial()
{
    declare -a aFailedJobIDList
    declare -a aFailedJobNameList
    declare -a aFailedJobUnpassedCasesNumList
    declare -a aFailedJobTestDirList

    declare -a aUnRunCaseJobIDList
    declare -a aUnRunCaseJobNameList
    declare -a aUnRunCaseJobTestDirList


    declare -a aSucceedJobIDList
    declare -a aSucceedJobNameList
    declare -a aSucceedJobPassedCasesNumList
    declare -a aSucceedJobTestDirList


    declare -a aAllJobsHostNameList
    declare -a aAllJobIDList

    let "FailedJobNum=0"
    let "SucceedJobNum=0"
    let "UnRunCaseJobNum=0"
    let "AllJobNum=0"

    CurrentDir=`pwd`
    JobReportFolder="FinalResult"

    let "UnpassedCasesNum=0"
    let "PassedCasesNum=0"
    SGEJobID=""
    SGEJobName=""
    SGEJobHost=""

    let "JobCompletedFlag=0"
    let "UnrunCasesFlag=0"

}

runCheck()
{
    if [ -d ${JobReportFolder} ]
    then
        cd ${JobReportFolder}
        JobReportFolder=`pwd`
        cd ${CurrentDir}
    else
        echo ""
        echo -e "\033[31m Final result folder for report does not exist,please double check   \033[0m"
        echo ""
        exit 1
    fi

    return 0
}

#report file template list as below:
#  **********************************************************************
#  Test report for YUV MSHD_320x192_12fps.yuv
#
#  Succeed!
#  All Cases passed the test!
#  ..................Test summary for MSHD_320x192_12fps.yuv....................
#  TestStartTime is Sun May 10 23:47:01 EDT 2015
#  TestEndTime   is Mon May 11 01:53:41 EDT 2015
#  total case  Num     is : 2000
#  EncoderPassedNum    is : 2000
#  EncoderUnPassedNum  is : 0
#  DecoderPassedNum    is : 2000
#  DecoderUpPassedNum  is : 0
#  DecoderUnCheckNum   is : 0
#
#  --issue bitstream can be found in  /home/ZhaoYun/SGEJobID_849/issue
#  --detail result  can be found in   /home/ZhaoYun/SGEJobID_849/result
#  report file: /opt/sge62u2_1/SGE_room2/OpenH264ConformanceTest/NewSGE-SVC-Test/FinalResult/
#  **********************************************************************

runParseStatus()
{

    if [ ! $# -eq 1 ]
    then
        echo ""
        echo -e "\033[31m usage:  runParseStatus \${ReportFile}   \033[0m"
        echo ""
        return 1
    fi

    ReportFile=$1

    if [ ! -e ${ReportFile} ]
    then
        echo ""
        echo -e "\033[31m Report file ${ReportFile} does not exist!  \033[0m"
        echo ""
        return 1
    fi


    let "UnpassedCasesNum=0"
    let "PassedCasesNum=0"
    let "JobCompletedFlag=0"
    let "UnrunCasesFlag=0"

    SGEJobID=""
    SGEJobName=""
    SGEJobHost=""
    TestDir=""

    while read line
    do
        if [[ "$line" =~ "EncoderUnPassedNum" ]]
        then
            TempString=`echo $line | awk 'BEGIN {FS=":"} {print $2}'`
            TempString=`echo $TempString | awk  ' {print $1}'`
            TempString=`echo $TempString | awk  'BEGIN {FS="\033"} {print $1}'`
            #echo "TempString is ${TempString}"
            let "UnpassedCasesNum = ${TempString}"
            let "JobCompletedFlag=1"

        elif [[ "$line" =~ "EncoderPassedNum" ]]
        then
            TempString=`echo $line | awk 'BEGIN {FS=":"} {print $2}'`
            TempString=`echo $TempString | awk '{print $1}'`
            TempString=`echo $TempString | awk  ' BEGIN {FS="\033"} {print $1}'`
            let "PassedCasesNum = ${TempString}"

        elif [[ "$line" =~ "SGE job ID" ]]
        then
            # SGE job ID   is: 533
            TempString=`echo $line | awk 'BEGIN {FS=":"} {print $2}'`
            TempString=`echo $TempString | awk '{print $1}'`
            SGEJobID=${TempString}
        elif [[ "$line" =~ "SGE job name" ]]
        then
            # SGE job name is: MSHD_320x192_12fps.yuv_SubCasedIndex_1
            TempString=`echo $line | awk 'BEGIN {FS=":"} {print $2}'`
            TempString=`echo $TempString | awk '{print $1}'`
            SGEJobName=${TempString}
        elif [[ "$line" =~ "issue bitstream" ]]
        then
            # --issue bitstream can be found in  /home/ZhaoYun/SGEJobID_849/issue
            TempString=`echo $line | awk 'BEGIN {FS="/"} {print $4}'`
            TempString=`echo $TempString | awk 'BEGIN {FS="_"} {print $2}'`
            SGEJobID=${TempString}
            SGEJobHost=`echo $line | awk 'BEGIN {FS="/"} {print $3}'`
        elif [[ "$line" =~ "Test report" ]]
        then
            # Test report for YUV MSHD_320x192_12fps.yuv
            TempString=`echo $line | awk '{print $6}'`
            SGEJobName=${TempString}
        elif [[ "$line" =~ "Test YUV file check failed!" ]]
        then
            # can not find test yuv
            let "JobCompletedFlag=1"
            let "UnrunCasesFlag=1"
        elif [[ "$line" =~ "Host name" ]]
        then
            # Host name    is: ZhaoYun
            TempString=`echo $line | awk 'BEGIN {FS="/"} {print $2}'`
            TempString=`echo $TempString | awk '{print $1}'`
            SGEJobHost=${TempString}
        fi

    done <${ReportFile}

    TempDataDir="/home"
    TestDir="${TempDataDir}/${SGEJobHost}/SGEJobID_${SGEJobID}"

}

runUpdateJobPassedStatus()
{

    if [  "${UnrunCasesFlag}" -eq 1 ]
    then
        aUnRunCaseJobIDList[${UnRunCaseJobNum}]=${SGEJobID}
        aUnRunCaseJobNameList[${UnRunCaseJobNum}]=${SGEJobName}
        aUnRunCaseJobTestDirList[${UnRunCaseJobNum}]=${TestDir}
        let "UnRunCaseJobNum ++"

    elif [ ! "${UnpassedCasesNum}" -eq 0 ]
    then
        aFailedJobIDList[${FailedJobNum}]=${SGEJobID}
        aFailedJobNameList[${FailedJobNum}]=${SGEJobName}
        aFailedJobUnpassedCasesNumList[${FailedJobNum}]=${UnpassedCasesNum}

        aFailedJobTestDirList[${FailedJobNum}]=${TestDir}
        let "FailedJobNum ++"
    else
        aSucceedJobIDList[${SucceedJobNum}]=${SGEJobID}
        aSucceedJobNameList[${SucceedJobNum}]=${SGEJobName}
        aSucceedJobPassedCasesNumList[${SucceedJobNum}]=${PassedCasesNum}

        aSucceedJobTestDirList[${SucceedJobNum}]=${TestDir}
        let "SucceedJobNum ++"
    fi

    aAllJobsHostNameList[${AllJobNum}]=${SGEJobHost}
    aAllJobIDList[${AllJobNum}]=${SGEJobID}
    let "AllJobNum ++"

}

runParseAllReportFile()
{

    for file in ${JobReportFolder}/TestReport_*
    do
        if [ -e "${file}" ]
        then
            #echo "file is ${file}"
            runParseStatus ${file}

            if [ ${JobCompletedFlag} -eq 1 ]
            then
                runUpdateJobPassedStatus
            fi
        fi
    done

}

runOutputParseResult()
{
    if [ "${Option}" = "FailedJobID"  ]
    then
        echo ${aFailedJobIDList[@]}
    elif [ "${Option}" = "FailedJobName" ]
    then
        echo ${aFailedJobNameList[@]}
    elif [ "${Option}" = "FailedJobUnPassedNum" ]
    then
        echo ${aFailedJobUnpassedCasesNumList[@]}
    elif [ "${Option}" = "SucceedJobID" ]
    then
        echo ${aSucceedJobIDList[@]}
    elif [ "${Option}" = "SucceedJobName" ]
    then
        echo ${aSucceedJobNameList[@]}
    elif [ "${Option}" = "SucceedJobPassedNum" ]
    then
        echo ${aSucceedJobPassedCasesNumList[@]}
    elif [ "${Option}" = "UnRunCaseJobID" ]
    then
        echo ${aUnRunCaseJobIDList[@]}
    elif [ "${Option}" = "UnRunCaseJobName" ]
    then
        echo ${aUnRunCaseJobNameList[@]}
    elif [ "${Option}" = "AllHostsName" ]
    then
        echo ${aAllJobsHostNameList[@]}
    elif [ "${Option}" = "AllCompletedJobsID" ]
    then
        echo ${aAllJobIDList[@]}
    elif [ "${Option}" = "FailedJobTestDir" ]
    then
        echo ${aFailedJobTestDirList[@]}

    elif [ "${Option}" = "SucceedJobTestDir" ]
    then
        echo ${aSucceedJobTestDirList[@]}

    elif [ "${Option}" = "UnRunCaseJobTestDir" ]
    then
        echo ${aUnRunCaseJobTestDirList[@]}
    fi
}

runOptionValidateCheck()
{
    declare -a aOptionList
    aOptionList=(FailedJobID FailedJobName FailedJobUnpassedNum FailedJobTestDir \
                 SucceedJobID SucceedJobName SucceedJobPassedNum   SucceedJobTestDir \
                 UnRunCaseJobID UnRunCaseJobName   UnRunCaseJobTestDir \
                 AllHostsName AllCompletedJobsID  )
    let "Flag=1"

    for InputOption in ${aOptionList[@]}
    do
        if [ "${Option}" = "${InputOption}"  ]
        then
            let "Flag=0"
        fi
    done

    if [ ! ${Flag} -eq 0 ]
    then
        runUsage
        exit 1
    fi

}
runMain()
{
    runOptionValidateCheck
    runInitial
    runCheck

    runParseAllReportFile
    runOutputParseResult
}

Option=$1
runMain


