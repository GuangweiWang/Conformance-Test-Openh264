
Conformance-Test-Openh264
==========================================
about
-----
-   This model is part of Cisco openh264 project for encoder binary comparison test.
	In this test, all cases of all test sequences will be tested and check that whether 
	the reconstructed YUV is the same with JM decoder's YUV. if yes, the test case 
	will be marked as passed and SHA1 string will be generated, otherwise, marked as unpassed 
	and no SHA1 string for this test case in SHA1 table file(XXX.yuv_AllCases_SHA1_Table.csv)

-   The output of the test are those files in ./FinalResult, espectially the summary files named as XXX.Summary.
	and cases passed status in files named as XXX_AllCasesOutput.csv.And SHA1 table files can be found in 
        folder  ./SHA1Table.
	For those temp data generated during test, can be found ./AllTestData/xxx.yuv/

-   For Cisco openh264 project,please refer to https://github.com/cisco/openh264. 
 
how to use
----------
-   step 1. update your test codec in folder ./Codec, for how to update, please refer to section 
	  "how to update you test codec";
-   step 2. configure your test case if you do not use default test case.
          for how to generate your personal test case, please refer to section "how to configure test case"	
-   step 3. run shell script file: ./run_Main.sh ./CaseConfigure/case.csf,ignore the warning info during the test.
	   test time  depends on how many cases you are running and 
	   how many test sequences you used in the test
-   step 4. go to folder ./FinalResult t for the final test result.
          SHA1 table files are under folder ./SHA1Table	

        eg.
        1. ./run_UpdateCodec.sh  $YourOpenh264Dir
        2. change your test configure by editing file CaseConfigure/case.cfg
        3. ./run_Main.sh CaseConfigure/case.cfg
        4. wait for the final test result.
        5. you can check you test result in ./AllTestData/XXX.yuv/result/XXX.Testlog or XXX_AllCasesOutput.csv file
          during you test, those files will update case by case.
      	


supported features
------------------
-  SCC 
-  SVC single spatial layer
-  SVC  multiple spatial layers
-  for how to run above test, please got to section "how to configure test case"
	  
structure
---------

-   AllTestData
 
	Test space for each test sequence, this folder will be generated in the early test stage.
	Test space for each sequence looks like ./AllTestData/xxx.yuv, and each of test space 
	contain the test codec , case configure file and shell script file which copied from
	./Codec, ./CaseConfigure, ./Scripts respectively.For temp data generated during test, can be found under 
	folder   ./AllTestData/XXX.yuv/TempData(or issue, result)
	
	 
-   CaseConfigure
  
	You can configure your test case by editing configure file ./CaseConfigure/case.cfg.
	For more detail about how to generate test cases using case.cfg, please refer to script
	file ./Scripts/run_GenerateCase.sh 

-   Codec
   
        1. openh264 codec: encoder, decoder and configure file layerXX.cfg welsenc.cfg; 
        2. JM decoder,JSVM decoder and bit stream extractor  for multilayer test;
        3. downsample and cropper for those resolution are non multiple of 16  
        4. for how toupdate your test codec,please go to section  "how to update you test codec"

-   FinalResult
  
        All test sequences' test result will be copied to folder ./FinalResult.
        XXX_AllCasesOutput.csv       contain the passe status of all cases(passed or unpassed etc.)
        XXX_AllCases_SHA1_Table.csv  contain the SHA1 string of those  passed cases
        XXX_.TestLog    test log of each test bit stream
        XXX_.Summary    test summary of each test bit stream

-   Script
   
    the script files 
	
-   SHA1Table
   
    all SHA1 table of each test sequence.


how to update you test codec
----------------------------
        no matter you choose 1 or 2, the macro "WELS_TESTBED" must be enable,so that the reconstrution YUV file 
        will be dumped during the encoding proccess. if you choose 1, you need to open the macro by 
        adding "#define WELS_TESTBED" in file codec/encoder/core/inc/as264_common.h;if you choose 2, auto script
        will do it automatically.

-	1.update your test codec manually
        build your private openh264, and copied  h264enc, h264dec, layer2.cfg, welsenc.cfg to folder ./Codec manually.

-	2.update automatically
        just given your openh264 repository's directory, and run script file 

        ./run_UpdateCodec.sh  ${YourOpenH264Dir}
        and the script file will complete below tasks:
        ----enable macro for dump reconstructed YUV in codec/encoder/core/inc/as264_common.h
        ----build codec
        ----copy h264enc h264dec layer2.cfg welsenc.cfg to ./Codec
        ----copy test bit stream from openh264/res  to ./BitStreamForTest
		

how to configure test case
--------------------------

-1. Edit configure file ./CaseConfigure/case.cfg

        using white space to separate the value of test parameter
        eg: IntraPeriod:  -1   30 
-2. 	
   using white space to separate the value of test parameter
        eg: IntraPeriod:  -1   30  

-	2. if you want to change the combination order of test parameter or anything else,
          please refer to script file ./Scripts/run_GenerateCase.sh and change the script if you want.

-	3. SVC single sptatial layer
          chane setting in case.cfg as below:
            MultiLayer:    0            # 0 single layer  1 multi layer
            UsageType:     0            #0: camera video 1:screen content

-	4. SVC multiple spatial layers
          chane setting in case.cfg as below:
           MultiLayer:    0            # 0 single layer  1 multi layer
           UsageType:     0            #0: camera video 1:screen content

-	5. SCC (openh264 codec will support SCC in the futhure)
          chane setting in case.cfg as below:
            MultiLayer:    0            # 0 single layer  1 multi layer
            UsageType:     1            #0: camera video 1:screen content


how to verify  the test case
---------------------------
-   please refer to script file ./Scripts/run_BitStreamValidateCheck.sh
