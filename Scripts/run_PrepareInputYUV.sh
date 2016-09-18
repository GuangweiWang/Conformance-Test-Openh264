#!/bin/bash

#*********************************************************************************************
#brief:
#  --for input YUV preparation
#        1). calculate input layer size based on encoded frame num(size in byte);
#        2). change YUV's resolution and crop it to be multiple of 16 if Multiple16Flag==1
#
#  usage: ./run_PrepareInputYUV.sh  ${OutputDir}      ${InputYUV}      ${LogFileName}
#                                             ${Multiple16Flag} ${EncodedFrmNum}
#  --eg:
#    input:  run_PrepareInputYUV.sh  /opt/GuanYUn ../../ABC_1080X720_30fps.yuv  prepare.log
#                                              1  30
#             Multiple16Flag=1; EncodedFrmNum=30
#    output: there will be tow down sample YUV generated under /opt/GuanYu/
#            1). layer0_Size=1080*720 *12bit/pixel * 30Frms /8 (byte)
#                layer1_Size=540*360  *12bit/pixel * 30Frms /8 (byte)
#                layer2_Size=270*180  *12bit/pixel * 30Frms /8 (byte)
#
#             2) as all layer is multiple of 16, no need to crop and change layer resolution
#
#  --note: YUV name must be named as XXX_PicWxPicH_FPSxxxx.yuv
#
#date:  5/08/2014 Created
#*********************************************************************************************
#usage: runGlobalVariableInitial ${OriginYUV}
runGlobalVariableInitial()
{
	OriginYUVName=""
	OriginWidth=""
	OriginHeight=""

	DownSampleExe="DownConvertStatic"

	declare -a aYUVInfo
	declare -a aLayerWidth
	declare -a aLayerHeight
	declare -a aYUVSize

    NumberLayer=1
    aLayerWidth=(0 0 0 0)
    aLayerHeight=(0 0 0 0)
    aYUVSize=(0 0 0 0)
}
runCheckEncodedFrameNum()
{

    OriginYUVSize=`ls -l ${OriginYUV} | awk '{print $5}'`
    #size in bytes
    let "FrameSize = $OriginWidth * ${OriginHeight} * 12 / 8"
    let "MaxFrameNum=${OriginYUVSize}/ $FrameSize"

    if [ ${EncodedFrmNum} -gt ${MaxFrameNum} ]
    then
        echo "EncodedFrmNum(${EncodedFrmNum}) in test is larger than MaxFrameNum(${MaxFrameNum})"
        echo "now change actual encoded frame num to MaxFrameNum(${MaxFrameNum})"
        let "EncodedFrmNum = ${MaxFrameNum}"
    fi
}

#usage: runSetLayerInfo
runSetLayerInfo()
{
	OriginYUVName=`echo ${OriginYUV} | awk 'BEGIN  {FS="/"} {print $NF}'`
	aYUVInfo=(`./run_ParseYUVInfo.sh  ${OriginYUVName}`)

    OriginWidth=${aYUVInfo[0]}
	OriginHeight=${aYUVInfo[1]}
	if [  ${OriginWidth} -eq 0  -o ${OriginHeight} -eq 0 ]
	then
		echo "origin YUV info is not right, PicW or PicH equal to 0 "
		exit 1
	fi

    NumberLayer=`./run_GetSpatialLayerNum.sh ${OriginWidth} ${OriginHeight}`

    #layer resolution for laye0,layer1,layer2,layer3 is the same with case setting,
    #please refer to run_GenerateCase.sh
    #eg. OriginWidth=1280  then aLayerWidth=(1280 640 320 160)
    let "factor = 1"
    for((i=0;i<${NumberLayer};i++))
    do
        let "aLayerWidth[$i]  = OriginWidth  / factor"
        let "aLayerHeight[$i] = OriginHeight / factor"
        let "factor *= 2"

        if [ ${Multiple16Flag} -eq 1  ]
        then
            let  "aLayerWidth[$i]  = ${aLayerWidth[$i]}  - ${aLayerWidth[$i]}  % 16"
            let  "aLayerHeight[$i] = ${aLayerHeight[$i]} - ${aLayerHeight[$i]} % 16"
        fi

		let "PicWRemainder= ${aLayerWidth[$i]}%2"
		let "PicHRemainder= ${aLayerHeight[$i]}%2"
		if [ ${PicWRemainder} -eq 1 -o ${PicHRemainder} -eq 1 ]
		then
			echo ""
			echo -e "\033[31m  resolution--${aLayerWidth[$i]}x${aLayerHeight[$i]} is not multiple of 2 \033[0m"
			echo -e "\033[31m  Prepare failed! Please used another test sequence!\033[0m"
			echo ""
			exit 1
		fi

        #get layer size, this info is need for RecYUV layersize comparison
        # to check wheather layer encoded YUV size is equal to rec YUV size
        # eg. resolution=1080*720,encoded_frm_num=30
        # then, encoded_layer_size=1080*720*12bit/piexl*30Frms / 8 (Bytes)
        let "aYUVSize[i] = ${aLayerWidth[$i]} * ${aLayerHeight[$i]} * ${EncodedFrmNum} * 12 / 8"
        #echo "i=$i: aLayerWidth    ${aLayerWidth[$i]}"
        #echo "i=$i: aLayerHeight   ${aLayerHeight[$i]}"
        #echo "i=$i: aYUVSize       ${aYUVSize[$i]}"
        #echo "i=$i: EncodedFrmNum  ${EncodedFrmNum}"


	done
}

runPrepareInputYUV()
{
    let "CropYUVFlag = 0"
    [ ! ${OriginWidth}  -eq ${aLayerWidth[0]}  ] &&  let "CropYUVFlag = 1"
    [ ! ${OriginHeight} -eq ${aLayerHeight[0]} ] &&  let "CropYUVFlag = 1"

    #echo " OriginHeight ${OriginWidth} aLayerWidth ${aLayerWidth[0]} "
    #echo " OriginHeight ${OriginHeight} aLayerHeight ${aLayerHeight[0]} "
    #echo " CropYUVFlag is $CropYUVFlag"
    #echo " NumberLayer is ${NumberLayer}"
    if [ ${CropYUVFlag} -eq 1 ]
    then
        #rename new input yuv file due to resolution change
        NewInputYUVName=`../Tools/run_RenameYUVfileWithNewResolution.sh ${OriginYUVName} ${aLayerWidth[0]} ${aLayerHeight[0]}`
        #echo "NewInputYUVName is ${NewInputYUVName}"
        #echo "OriginYUVName   is ${OriginYUVName}"
        #echo "OutPutDir       is ${OutPutDir}"
        if [ -e ${OutPutDir}/${NewInputYUVName} ]
        then
            ./run_SafeDelete.sh  ${OutPutDir}/${NewInputYUVName}
        fi

        if [ ! -e ${DownSampleExe} ]
        then
            echo "${DownSampleExe} does not exist! please double check! "
            let  "PrepareFlag=1"
            exit 1
        fi

        ./${DownSampleExe}  ${OriginWidth} ${OriginHeight} ${OriginYUV}  ${aLayerWidth[0]}  ${aLayerHeight[0]}  ${OutPutDir}/${NewInputYUVName}
        if [ ! $? -eq 0 ]
        then
            let "PrepareFlag=1"
        fi
    else
        NewInputYUVName=${OriginYUVName}
        cp -f ${OriginYUV} ${OutPutDir}/${NewInputYUVName}
    fi

}

#usage:runOutputPrepareLog
runOutputPrepareLog()
{
	echo "">${PrepareLog}
    echo "InputYUV:      ${NewInputYUVName}">>${PrepareLog}
    echo "NumberLayer:   ${NumberLayer}">>${PrepareLog}
    echo "EncodedFrmNum: ${EncodedFrmNum}">>${PrepareLog}
    for ((i=0; i<${NumberLayer}; i++ ))
	do
        echo "LayerPicW_${i}:   ${aLayerWidth[$i]}">>${PrepareLog}
        echo "LayerPicH_H_${i}: ${aLayerHeight[$i]}">>${PrepareLog}
        echo "LayerSize_${i}:   ${aYUVSize[$i]}">>${PrepareLog}
	done
}

runCheckParm()
{
    if [ ! -f ${OriginYUV}  ]
    then
        echo "origin yuv does not exist! please double check!--${OriginYUV}"
        exit 1
    fi

    if [ ! -d  ${OutPutDir} ]
    then
        echo "output directory does not exist! please double check!--${OriginYUV}"
        exit 1
    fi

}
#usage: run_PrepareInputYUV.sh ${OriginYUV} ${PrepareLog} ${Multiple16Flag}
runMain()
{
	let "PrepareFlag=0"
	runGlobalVariableInitial
    runCheckParm

    runCheckEncodedFrameNum
	runSetLayerInfo
    runPrepareInputYUV
	if [ ! ${PrepareFlag} -eq 0 ]
	then
		echo ""
		echo -e "\033[31m  input YUV preparation failed! \033[0m"
		echo ""
		exit 1
	fi

	runOutputPrepareLog
	echo ""
	echo -e "\033[32m  input YUV preparation succeed! \033[0m"
	echo ""

	return 0
}
#******************************************************************
echo ""
echo "*********************************************************"
echo "     call bash file is $0"
echo "     input parameters are:"
echo "        $0 $@"
echo "*********************************************************"
echo ""

if [ ! $# -eq 5 ]
then
    echo -e "\033[32m usage: run_PrepareInputYUV.sh \${OutPutDir} \${OriginYUV} \${PrepareLog} \${Multiple16Flag} \${EncodedFrmNum} \n\033[0m"
    exit 1
fi

OutPutDir=$1
OriginYUV=$2
PrepareLog=$3
Multiple16Flag=$4
EncodedFrmNum=$5
runMain
