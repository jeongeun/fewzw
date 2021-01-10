#!/bin/bash

scale=1000

for (( mass=6200; mass<=6400; mass+=200 ))
do
#run_M2000_Wp_20/NNLO.sect1.run_M2000_Wp_2.dat
echo " WpMass[index${mass}] = $mass ;"
    
  LOrunFile_Wm=./run_M${mass}_Wm_0/run_M${mass}_Wm_00/LO.M${mass}_Wm_0.dat
  LOrunFile_Wp=./run_M${mass}_Wp_0/run_M${mass}_Wp_00/LO.M${mass}_Wp_0.dat

     if [ -e $LOrunFile_Wm ]; then
        LOxsec_Wm=`grep "Sigma" $LOrunFile_Wm | awk '{print $4}'`
        LOxsecErr_Wm=`grep "Error" $LOrunFile_Wm | awk '{print $4}'`
        echo -n "// Wm= $(printf %.8f $LOxsec_Wm) " ## ( $xsec_Wm +-  $xsecErr_Wm )(pb)"
        echo -n "// err= $(printf %.8f $LOxsecErr_Wm)" ## ( $xsec_Wm +-  $xsecErr_Wm )(pb)"
     fi

     if [ -e $LOrunFile_Wp ]; then
        LOxsec_Wp=`grep "Sigma" $LOrunFile_Wp | awk '{print $4}'`
        LOxsecErr_Wp=`grep "Error" $LOrunFile_Wp | awk '{print $4}'`
        echo -n " Wp = $(printf %.8f $LOxsec_Wp)" ## ( $xsec_Wp +-  $xsecErr_Wp )(pb)"
        echo -n " err= $(printf %.8f $LOxsecErr_Wp)" ## ( $xsec_Wm +-  $xsecErr_Wm )(pb)"
     fi
echo "   "
echo " loxsec[index${mass}] =  $LOxsec_Wm  +  $LOxsec_Wp   ;"
echo "   "


#run_Wp_M6200_Wm_2/run_Wp_M6200_Wm_20/NNLO.sect1.run_Wp_M6200_Wm_2.dat
echo " nnloxsec[index${mass}] = "
     for (( i=0; i<154; i++ ))
     do

     NNLOrunFile_Wm=./run_Wp_M${mass}_Wm_2/run_Wp_M${mass}_Wm_2${i}/NNLO.sect\*.run_Wp_M${mass}_Wm_2.dat
     NNLOrunFile_Wp=./run_Wp_M${mass}_Wp_2/run_Wp_M${mass}_Wp_2${i}/NNLO.sect\*.run_Wp_M${mass}_Wp_2.dat
     if [ -e $NNLOrunFile_Wm ]; then
        NNLOxsec_Wm=`grep "Sigma" $NNLOrunFile_Wm | awk '{print $4}'`
        NNLOxsecErr_Wm=`grep "Error" $NNLOrunFile_Wm | awk '{print $4}'`
        echo -n "$(printf %.8f $NNLOxsec_Wm) + " ## ( $xsec_Wm +-  $xsecErr_Wm )(pb)"
        #echo -n "$($NNLOxsec_Wm) + " ## ( $xsec_Wm +-  $xsecErr_Wm )(pb)"
        else
        #echo "File not exist /run_M${mass}_Wm_2/run_M${mass}_Wm_2${i}/NNLO.sect\*.run_M${mass}_Wm_2.dat"
        echo "File not exist /run_Wp_M${mass}_Wm_2/run_Wp_M${mass}_Wm_2${i}/NNLO.sect\*.run_Wp_M${mass}_Wm_2.dat"

     fi

	#echo " "

    #if [ -e $NNLOrunFile_Wp ]; then
    #   NNLOxsec_Wp=`grep "Sigma" $NNLOrunFile_Wp | awk '{print $4}'`
    #   NNLOxsecErr_Wp=`grep "Error" $NNLOrunFile_Wp | awk '{print $4}'`
    #   echo -n "$(printf %.8f $NNLOxsec_Wp) + " ## ( $xsec_Wp +- $xsecErr_Wp )(pb)"
    #   #echo -n "$($xsec_Wp) + " ## ( $xsec_Wp +- $xsecErr_Wp )(pb)"
    #   else
    #   #echo "File not exist /run_M${mass}_Wp_2/run_M${mass}_Wp_2${i}/NNLO.sect\*.run_M${mass}_Wp_2.dat"
    #   echo "File not exist /run_Wp_M${mass}_Wp_2/run_Wp_M${mass}_Wp_2${i}/NNLO.sect\*.run_Wp_M${mass}_Wp_2.dat"

    #fi
    ##echo "=============================================================="
    done
echo " ; "
done
