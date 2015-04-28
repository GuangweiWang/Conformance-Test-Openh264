#!/bin/bash
#***************************************************************************************
# brief:
#      --combine subcase files into single files for all test cases
#      --usage:  run_SubCasesToAllCasesSummary.sh ${YUVName} ${SummaryFile}
#
#date: 04/28/2015 Created
#***************************************************************************************
 runUsage()
 {
	echo ""
    echo -e "\033[31m usage:  ./run_SubCasesToAllCasesSummary.sh \${YUVName}     033[0m"
    echo -e "\033[31m                                            \${SummaryFile} 033[0m"
    echo ""
 }

runSummarizeAllTestResult()
{
    let "TempNum = 0"
    TempString=""

    while read line
    do
        TempString=`echo $line | awk'BEGIN {FS=":"} {print $2}'`
        TempString=`echo $TempString | awk'BEGIN {FS="["} {print $1}'`
        let "TempNum = ${TempString}"

        if [[ ${line} =~ "total case  Num" ]]
        then
            let "TotalNum += ${TempNum}"
        elif [[ ${line} =~ "EncoderPassedNum" ]]
        then
            let "EncoderPassedNum += ${TempNum}"
        elif [[ ${line} =~ "EncoderUnPassedNum" ]]
        then
            let "EncoderUnPassedNum += ${TempNum}"
        elif [[ ${line} =~ "DecoderPassedNum" ]]
        then
            let "DecoderPassedNum += ${TempNum}"
        elif[[ ${line} =~ "DecoderUpPassedNum" ]]
        then
            let "DecoderUpPassedNum += ${TempNum}"
        elif[[ ${line} =~ "DecoderUnCheckNum" ]]
        then
            let "DecoderUnCheckNum += ${TempNum}"
        fi
    done < ${SummaryFile}

}

runGetTestSummary()
{

    if [ ! ${EncoderUnPassedNum} -eq 0 ]
    then
        SummaryString="\033[31m   Not all Cases passed the test! [0m"
        FinalResult="\033[32m     Succed! [0m"
    else
        SummaryString="\033[32m   All Cases passed the test! [0m"
        FinalResult="\033[31m     Failed! [0m"
    fi


    echo -e "\033[32m ********************************************************************** [0m"
    echo -e "\033[32m *        Test report of all cases for YUV ${YUVName}  [0m"
    echo -e "\033[32m ********************************************************************** [0m"
    echo -e ${FinalResult}
    echo -e ${SummaryString}
    echo -e "\033[32m total case  Num     is : ${TotalNum} [0m"
    echo -e "\033[32m EncoderPassedNum    is : ${EncoderPassedNum} [0m"
    echo -e "\033[31m EncoderUnPassedNum  is : ${EncoderUnPassedNum} [0m"
    echo -e "\033[32m DecoderPassedNum    is : ${DecoderPassedNum} [0m"
    echo -e "\033[31m DecoderUpPassedNum  is : ${DecoderUpPassedNum} [0m"
    echo -e "\033[31m DecoderUnCheckNum   is : ${DecoderUnCheckNum} [0m"
    echo -e "\033[32m ********************************************************************** [0m"
    echo -e "\033[32m ********************************************************************** [0m"
    echo -e "\033[32m ********************************************************************** [0m"
    echo ""
    echo ""
    echo -e "\033[32m ********************************************************************** [0m"
    echo -e "\033[32m *     Test report below for sub-cases set of YUV ${SummaryFile}[0m"
    echo -e "\033[32m ********************************************************************** [0m"
    cat  ${SummaryFile}
    echo -e "\033[32m ********************************************************************** [0m"
    echo -e "\033[32m ********************************************************************** [0m"
    echo -e "\033[32m ********************************************************************** [0m"

}

runCheck()
{
    if [ ! -e ${SummaryFile} ]
    then
        echo -e "\033[31m File ${SummaryFile} does not exist,please double check! \033[0m"
        exit 1
    fi
}

runMain()
{
    if [ ! $# -eq 2 ]
	then
		runUsage
		exit 1
	fi

    YUVName=$1
    SummaryFile=$2

    let "TotalNum = 0"
    let "EncoderPassedNum =0"
    let "EncoderUnPassedNum = 0"
    let "DecoderPassedNum =0"
    let "DecoderUpPassedNum = 0"
    let "DecoderUnCheckNum =0"
    TempFile=${SummaryFile}.temp

    runCheck

    runSummarizeAllTestResult
    runGetTestSummary >${TempFile}

    #deleted temp file
    ./Script/run_SafeDelete.sh ${SummaryFile}
    mv ${TempFile}  ${SummaryFile}

    return 0


}
YUVName=$1
SummaryFile=$2
runMain  ${YUVName} ${SummaryFile}

