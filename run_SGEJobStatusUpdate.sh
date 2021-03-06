#!/bin/bash
#***************************************************************************************
# brief:
#      --check that whether all submitted SGE jobs have been completed
#      --usage:  ./run_SGEJobStatusUpdate.sh  ${SGEJobSubmittedLogFile}
#                                             ${SGEJobsFinishFlagFile}
#
#
#date: 04/26/2015 Created
#***************************************************************************************
 runUsage()
 {
	echo ""
    echo -e "\033[31m usage: usage:  ./run_SGEJobStatusUpdate.sh  \${SGEJobSubmittedLogFile} \033[0m"
    echo -e "\033[31m usage: usage:                               \${SGEJobsFinishFlagFile}  \033[0m"
    echo -e "\033[32m when all SGE test jobs have been completd, \${SGEJobsFinishFlagFile} will be generated! \033[0m"
 	echo ""
 }

runInitial()
{
    declare -a aSubmittedSGEJobIDList
    declare -a aSubmittedSGEJobNameList
    declare -a aSubmittedSGEJobYUVNameList
    declare -a aSubmittedSGEJobSubCasesIndexList


    declare -a aCurrentSGEQueueJobIDList

    declare -a aRunningJobIDList
    declare -a aWaitingJobIDList
    declare -a aCompletedJobIDList

    declare -a aFailedJobIDList
    declare -a aFailedJobNameList
    declare -a aFailedJobUnpassedCasesNumList

    declare -a aSucceedJobIDList
    declare -a aSucceedJobNameList
    declare -a aSucceedJobPassedCasesNumList

    declare -a aUnRunCaseJobIDList
    declare -a aUnRunCaseJobNameList

    declare -a aUnknownReasonFailedJobIDList
    declare -a aUnknownReasonFailedJobNameList

    declare -a aFailedJobTestDirList
    declare -a aSucceedJobTestDirList
    declare -a aUnRunCaseJobTestDirList


    let "SubmittedJobNum = 0"
    let "CurrentSGEQueueJobNum = 0"
    let "NonCompletedJobNum=0"
    let "RunningJobNum=0"
    let "WaitingJobNum=0"
    let "CompletedJobNum=0"
    let "SucceedJobNum=0"
    let "FailedJobNum=0"
    let "UnRunCasesJobNum=0"
    let "UnKnownReasonFailedJobNum=0"

    FaildJobInfoLog="FailedJobInfo.txt"
    if [ -e ${FaildJobInfoLog} ]
    then
        ./Scripts/run_SafeDelete.sh ${FaildJobInfoLog}
    fi

    CurrentDir=`pwd`
    TestSpace="${CurrentDir}/AllTestData"
    SucceedJobsInfo="${CurrentDir}/SucceedJobsDetailInfo.txt"
    FailedJobsInfo="${CurrentDir}/FailedJobsDetailInfo.txt"
    UnRunCasesJobsInfo="${CurrentDir}/UnRunCasesJobsDetailInfo.txt"
    UnknownReasonJobsInfo="${CurrentDir}/UnknownReasonJobsDetailInfo.txt"

    date
    DateInfo=`date`
    echo "${DateInfo}">${SucceedJobsInfo}
    echo "${DateInfo}">${FailedJobsInfo}
    echo "${DateInfo}">${UnRunCasesJobsInfo}
    echo "${DateInfo}">${UnknownReasonJobsInfo}


}

runParseJobsInfo()
{
    aSubmittedSGEJobIDList=(`./Scripts/run_ParseSGEJobIDs.sh     ${SGEJobSubmittedLogFile}`)
    aSubmittedSGEJobNameList=(`./Scripts/run_ParseSGEJobNames.sh ${SGEJobSubmittedLogFile}`)

    #list info include ID and status
    #e.g.:aCurrentSGEQueueJobIDList=(501 r 502 r 503 w 504 qw)
    aCurrentSGEQueueJobIDList=(`./Scripts/run_ParseRunningSGEJobIDsAndStatus.sh IDAndStatus`)

    let "SubmittedJobNum       = ${#aSubmittedSGEJobIDList[@]}"
    let "CurrentSGEQueueJobNum = ${#aCurrentSGEQueueJobIDList[@]}/2"

}

runParseJobsDetailInfo()
{
    # job name looks like as below:
    # ----MSHD_320x192_12fps.yuv_SubCaseIndex_22
    for((i=0;i<${SubmittedJobNum};i++))
    do
        vTempJobName=${aSubmittedSGEJobNameList[$i]}
        vTempYUVName=`echo ${vTempJobName} | awk 'BEGIN {FS="----"} {print $1}' `
        vTempYUVName=`echo ${vTempYUVName} | awk 'BEGIN {FS=".yuv"} {print $1}' `
        vTempYUVName="${vTempYUVName}.yuv"

        vTempSubCasesIndex=`echo ${vTempJobName} | awk 'BEGIN {FS="SubCaseIndex_"} {print $2}' `
        vTempSubCasesIndex="SubCaseIndex_${vTempSubCasesIndex}"

        aSubmittedSGEJobYUVNameList[$i]=${vTempYUVName}
        aSubmittedSGEJobSubCasesIndexList[$i]=${vTempSubCasesIndex}
    done

}

runOutputParseInfo()
{
    echo  -e "\033[32m Total submitted job num            is ${SubmittedJobNum}              \033[0m"
    echo  -e "\033[32m Current job num in queue(SVC+SCC)  is ${CurrentSGEQueueJobNum}        \033[0m"
    echo  ""
    echo  -e "\033[32m Submitted jobs' ID                 is ${aSubmittedSGEJobIDList[@]}    \033[0m"
    echo  ""
    echo  -e "\033[32m Current queue's job ID             is ${aCurrentSGEQueueJobIDList[@]} \033[0m"
    echo  ""
    echo  -e "\033[32m Submitted jobs' name               is ${aSubmittedSGEJobNameList[@]}  \033[0m"
    echo  ""
}

#comparison between  current runnig SGE job list and the submitted job list
#to check that whether all submitted jobs are not in current running list
runSGEJobStatusCheck()
{


	for((i=0;i<${SubmittedJobNum};i++))
	do	
        SubmitId=${aSubmittedSGEJobIDList[$i]}
		let "JonRunningFlag=0"
		for((j=0;j<${CurrentSGEQueueJobNum};j++))
		do
            #e.g.:aCurrentSGEQueueJobIDList=(501 r 502 r 503 w 504 qw), so need to j*2; r means running, qw means queue wait
            let "QueueIDIndex = j*2"
            let "QueueStatusIndex = QueueIDIndex+1"
		
            CurrentSGEQueueJobID=${aCurrentSGEQueueJobIDList[${QueueIDIndex}]}
            CurrentSGEQueueJobStatus=${aCurrentSGEQueueJobIDList[${QueueStatusIndex}]}

			if [ ${SubmitId} -eq ${CurrentSGEQueueJobID} ]
			then
                if [ "${CurrentSGEQueueJobStatus}" =  "r" ]
                then
                    let "JonRunningFlag=1"
                else # job is under waiting status

                    let "JonRunningFlag=2"
                fi
				break
			fi
		done
		
		#job is still running
		if [ ${JonRunningFlag} -eq 1 ]
		then
			echo  -e "\033[31m  Job ${SubmitId} is still running \033[0m"
			echo  -e "\033[31m        Job info is:----${aSubmittedSGEJobNameList[$i]} \033[0m"
            aRunningJobIDList[${RunningJobNum}]=${SubmitId}
			let "NonCompletedJobNum++"
            let "RunningJobNum ++"
        #job is still waiting
        elif [ ${JonRunningFlag} -eq 2 ]
        then
            echo  -e "\033[31m  Job ${SubmitId} is still waiting \033[0m"
            echo  -e "\033[31m        Job info is:----${aSubmittedSGEJobNameList[$i]} \033[0m"
            aWaitingJobIDList[${WaitingJobNum}]=${SubmitId}
            let "NonCompletedJobNum++"
            let "WaitingJobNum ++"
        else
			echo  -e "\033[32m  Job ${SubmitId} has been finished! \033[0m"
			echo  -e "\033[32m        Job info is:----${aSubmittedSGEJobNameList[$i]} \033[0m"
            aCompletedJobIDList[${CompletedJobNum}]=${SubmitId}
            let "CompletedJobNum++"
		fi
	done

}

runUpdateSGEJobPassedStatus()
{
    #aOptionList=(FailedJobID FailedJobName FailedJobUnPassedNum SucceedJobID SucceedJobName SucceedJobPassedNum)

    aFailedJobIDList=(`./Scripts/run_ParseSGEJobPassStatus.sh   FailedJobID `)
    aFailedJobNameList=(`./Scripts/run_ParseSGEJobPassStatus.sh FailedJobName `)
    aFailedJobUnpassedCasesNumList=(`./Scripts/run_ParseSGEJobPassStatus.sh FailedJobUnpassedNum `)


    aSucceedJobIDList=(`./Scripts/run_ParseSGEJobPassStatus.sh   SucceedJobID `)
    aSucceedJobNameList=(`./Scripts/run_ParseSGEJobPassStatus.sh SucceedJobName `)
    aSucceedJobPassedCasesNumList=(`./Scripts/run_ParseSGEJobPassStatus.sh SucceedJobPassedNum `)

    aUnRunCaseJobIDList=(`./Scripts/run_ParseSGEJobPassStatus.sh   UnRunCaseJobID `)
    aUnRunCaseJobNameList=(`./Scripts/run_ParseSGEJobPassStatus.sh UnRunCaseJobName `)


    aFailedJobTestDirList=(`./Scripts/run_ParseSGEJobPassStatus.sh FailedJobTestDir `)
    aSucceedJobTestDirList=(`./Scripts/run_ParseSGEJobPassStatus.sh SucceedJobTestDir `)
    aUnRunCaseJobTestDirList=(`./Scripts/run_ParseSGEJobPassStatus.sh UnRunCaseJobTestDir `)


    let "FailedJobNum=${#aFailedJobIDList[@]}"
    let "SucceedJobNum=${#aSucceedJobIDList[@]}"
    let "UnRunCasesJobNum=${#aUnRunCaseJobIDList[@]}"

    let "DetectedJobNum= ${FailedJobNum} + ${SucceedJobNum} + ${UnRunCasesJobNum}"
    let "UnKnownReasonFailedJobNum=${CompletedJobNum} - ${DetectedJobNum}"

    if [ ! ${UnKnownReasonFailedJobNum} -eq 0  ]
    then
        runGetUnknownReasonFailedJobInfo
    fi
}
runGetUnknownReasonFailedJobInfo()
{
    declare -a DetectedJobList
    DetectedJobList=( ${aRunningJobIDList[@]} ${aWaitingJobIDList[@]} ${aFailedJobIDList[@]} ${aSucceedJobIDList[@]} ${aUnRunCaseJobIDList[@]} )
	let "DetectedJobNum =${#DetectedJobList[@]}"
	echo DetectedJobNum is ${DetectedJobNum}
    echo DetectedJobList is ${DetectedJobList[@]}
    echo UnKnownReasonFailedJobNum is ${UnKnownReasonFailedJobNum}

    let "UnKnownJobIndex=0"
    for((i=0;i<${SubmittedJobNum}; i++))
    do
        let "SubmittedJobID = ${aSubmittedSGEJobIDList[$i]}"
        let "DetectedFlag=0"
        for ((j=0;j<${DetectedJobNum};j++))
        do
            let "DetectedJobID = ${DetectedJobList[$j]}"
            if [ "${SubmittedJobID}" = "${DetectedJobID}" ]
            then
                let "DetectedFlag=1"
            fi
        done

        if [ ${DetectedFlag} -eq 0 ]
        then
            aUnknownReasonFailedJobIDList[${UnKnownJobIndex}]=${SubmittedJobID}
            aUnknownReasonFailedJobNameList[${UnKnownJobIndex}]=${aSubmittedSGEJobNameList[$i]}

            let "UnKnownJobIndex ++"
        fi
    done

}

runOutputJobDetailInfoFile()
{

    for((i=0;i<${SubmittedJobNum}; i++))
    do
        let "SubmittedJobID = ${aSubmittedSGEJobIDList[$i]}"
        vSubCasesIndex="${aSubmittedSGEJobSubCasesIndexList[$i]}"
        vTestDir="${TestSpace}/${aSubmittedSGEJobYUVNameList[$i]}"

        ## for unknown reason jobs' info
        for ((j=0;j<${UnKnownReasonFailedJobNum};j++))
        do
            let "DetectedJobID = ${aUnknownReasonFailedJobIDList[$j]}"
            if [ "${SubmittedJobID}" = "${DetectedJobID}" ]
            then
                echo "${SubmittedJobID}  ${vSubCasesIndex}  ${vTestDir} ">>${UnknownReasonJobsInfo}

            fi
        done

        ## for failed  jobs' info
        for ((j=0;j<${FailedJobNum};j++))
        do
            let "DetectedJobID = ${aFailedJobIDList[$j]}"
            if [ "${SubmittedJobID}" = "${DetectedJobID}" ]
            then
                echo "${SubmittedJobID}  ${vSubCasesIndex}  ${vTestDir} ">>${FailedJobsInfo}
                echo "            ----Test dir is: ${aFailedJobTestDirList}">>${FailedJobsInfo}

            fi
        done

        ## for succeed jobs' info
        for ((j=0;j<${SucceedJobNum};j++))
        do
            let "DetectedJobID = ${aSucceedJobIDList[$j]}"
            if [ "${SubmittedJobID}" = "${DetectedJobID}" ]
            then
                echo "${SubmittedJobID}  ${vSubCasesIndex}  ${vTestDir} ">>${SucceedJobsInfo}
                echo "            ----Test dir is: ${aSucceedJobTestDirList}">>${SucceedJobsInfo}

            fi
        done

        ## for un-run-cases jobs' info
        for ((j=0;j<${UnRunCasesJobNum};j++))
        do
            let "DetectedJobID = ${aUnRunCaseJobIDList[$j]}"
            if [ "${SubmittedJobID}" = "${DetectedJobID}" ]
            then
                echo "${SubmittedJobID}  ${vSubCasesIndex}  ${vTestDir} ">>${UnRunCasesJobsInfo}
                echo "            ----Test dir is: ${aUnRunCaseJobTestDirList}">>${UnRunCasesJobsInfo}
            fi
        done

    done

}

runOutputStatusSummary()
{

    if [ ${NonCompletedJobNum} -eq 0  ]
    then
        echo  -e "\033[32m  ****************************************************** \033[0m"
        echo  -e "\033[32m       All submitted SGE jobs have completed all test \033[0m"
        echo  -e "\033[32m  ****************************************************** \033[0m"
        echo  ""
        echo ""
        echo  -e "\033[32m  ********************************************************************  \033[0m"
        echo  -e "\033[32m      Completed jobs test cases status info                             \033[0m"
        echo  -e "\033[32m  ********************************************************************  \033[0m"
        echo  ""
        echo  -e "\033[32m Succeed job num  is ${SucceedJobNum}                                   \033[0m"
        echo  ""
        echo  -e "\033[32m Succeed job ID   is ${aSucceedJobIDList[@]}                            \033[0m"
        echo  ""
        echo  -e "\033[31m Failed job num   is ${FailedJobNum}                                    \033[0m"
        echo  ""
        echo  -e "\033[31m Failed job ID    is ${aFailedJobIDList[@]}                             \033[0m"
        echo  ""
        echo  -e "\033[31m Failed job un-passed num list is  ${aFailedJobUnpassedCasesNumList[@]} \033[0m"
        echo  ""
        echo  -e "\033[34m no case run job num(e.g. YUV not found)  is ${UnRunCasesJobNum}        \033[0m"
        echo  ""
        echo  -e "\033[34m no case run job ID is ${aUnRunCaseJobIDList[@]}                        \033[0m"
        echo  ""
        echo  -e "\033[35m Unknown reason failed job num is ${UnKnownReasonFailedJobNum}          \033[0m"
        echo  ""
        echo  -e "\033[35m Unknown reason failed job ID  is ${aUnknownReasonFailedJobIDList[@]}   \033[0m"
        echo  ""
        echo  -e "\033[32m  ********************************************************************* \033[0m"
        echo  ""
        return 0
    else
        echo  -e "\033[31m  ****************************************************** \033[0m"
        echo  -e "\033[31m       Not all submitted SGE jobs have completed yet \033[0m"
        echo  -e "\033[31m  ****************************************************** \033[0m"
        echo  ""
        echo  -e "\033[32m Total submitted job num   is ${SubmittedJobNum}         \033[0m"
        echo  -e "\033[32m Completed job num         is ${CompletedJobNum}         \033[0m"
        echo  -e "\033[31m Non completed job num     is ${NonCompletedJobNum}      \033[0m"
        echo  -e "\033[31m     --Running job num     is ${RunningJobNum}           \033[0m"
        echo  -e "\033[33m     --Waiting job num     is ${WaitingJobNum}           \033[0m"
        echo  ""
        echo  -e "\033[31m  ****************************************************** \033[0m"
        echo  -e "\033[31m  ****************************************************** \033[0m"
        echo  ""
        echo  -e "\033[32m Completed job ID  is ${aCompletedJobIDList[@]}          \033[0m"
        echo  ""
        echo  -e "\033[31m Running job ID    is ${aRunningJobIDList[@]}            \033[0m"
        echo  ""
        echo  -e "\033[33m Waiting job ID    is ${aWaitingJobIDList[@]}            \033[0m"
        echo  ""
        echo  -e "\033[31m  ****************************************************** \033[0m"
        echo  ""
        echo  -e "\033[32m  ********************************************************************  \033[0m"
        echo  -e "\033[32m      Completed jobs passed status info                                 \033[0m"
        echo  -e "\033[32m  ********************************************************************  \033[0m"
        echo  ""
        echo  -e "\033[32m Succeed job num  is ${#aSucceedJobIDList[@]}                           \033[0m"
        echo  ""
        echo  -e "\033[32m Succeed job ID   is ${aSucceedJobIDList[@]}                            \033[0m"
        echo  ""
        echo  -e "\033[31m Failed job num   is ${#aFailedJobIDList[@]}                            \033[0m"
        echo  ""
        echo  -e "\033[31m Failed job ID    is ${aFailedJobIDList[@]}                             \033[0m"
        echo  ""
        echo  -e "\033[31m Failed job un-passed num list is  ${aFailedJobUnpassedCasesNumList[@]} \033[0m"
        echo  ""
        echo  -e "\033[34m no case run job num(e.g. YUV not found)  is ${UnRunCasesJobNum}        \033[0m"
        echo  ""
        echo  -e "\033[34m no case run job ID is ${aUnRunCaseJobIDList[@]}                        \033[0m"
        echo  ""
        echo  -e "\033[35m Unknown reason failed job num is ${UnKnownReasonFailedJobNum}          \033[0m"
        echo  ""
        echo  -e "\033[35m Unknown reason failed job ID  is ${aUnknownReasonFailedJobIDList[@]}   \033[0m"
        echo  ""
        echo  -e "\033[33m  ********************************************************************* \033[0m"
        echo  ""

        return 1
    fi
}
runVaildateCheck()
{

    if [ ! -e ${SGEJobSubmittedLogFile} ]
    then
        echo ""
        echo  -e "\033[31m  SGEJobSubmittedLogFile ${SGEJobSubmittedLogFile} does not exist! \033[0m"
        echo  -e "\033[31m  Please double check!\033[0m"
        echo  -e "\033[32m  --Submit SGE jobs before you detect the SGE jobs status!  \033[0m"
        echo  -e "\033[32m  --or check the the SGE submitted log file!\033[0m"
        echo ""
        touch ${SGEJobSubmittedLogFile}
        return 1
    fi

    if [ ! -s ${SGEJobSubmittedLogFile} ]
    then
        echo ""
        echo  -e "\033[31m  SGEJobSubmittedLogFile ${SGEJobSubmittedLogFile} does not exist! \033[0m"
        echo  -e "\033[31m  Please double check!\033[0m"
        echo  -e "\033[32m  --Submit SGE jobs before you detect the SGE jobs status!  \033[0m"
        echo  -e "\033[32m  --or check the the SGE submitted log file!\033[0m"
        echo ""
        touch ${SGEJobSubmittedLogFile}
        return 1
    fi


    if [ -e ${SGEJobsFinishFlagFile} ]
    then
        ./Scripts/run_SafeDelete.sh  ${SGEJobsFinishFlagFile}
    fi
}

runMain()
{

    runVaildateCheck
    if [ ! $? -eq 0 ]
    then
        return 0
    fi

    runInitial

    runParseJobsInfo
    runParseJobsDetailInfo

    runOutputParseInfo

    runSGEJobStatusCheck
    runUpdateSGEJobPassedStatus
    runOutputJobDetailInfoFile
    runOutputStatusSummary
    if [ $? -eq 0 ]
    then
        touch ${SGEJobsFinishFlagFile}
    fi

    [ ! ${FailedJobNum} -eq 0 ] || [ ! ${UnKnownReasonFailedJobNum} -eq 0 ] && touch ${FaildJobInfoLog}

    return 0

}
SGEJobSubmittedLogFile=$1
SGEJobsFinishFlagFile=$2
if [ ! $# -eq 2  ]
then
    runUsage
exit 1
fi

echo ""
echo "*********************************************************"
echo "     call bash file is $0"
echo "     input parameters is:"
echo "        $0 $@"
echo "*********************************************************"
echo ""


runMain  ${SGEJobSubmittedLogFile} ${SGEJobsFinishFlagFile}


