#!/bin/bash
### Mode 1 for LHC W-, 3 for LHC W+
### Order 0 for LO, 2 for NNLO

TopDir=`pwd`
export SCRAM_ARCH=slc6_amd64_gcc630
export VO_CMS_SW_DIR=/cvmfs/cms.cern.ch
source $VO_CMS_SW_DIR/cmsset_default.sh
cd /cvmfs/cms.cern.ch/slc6_amd64_gcc630/cms/cmssw/CMSSW_10_1_9
eval `scramv1 runtime -sh`
cd -
export dirLHAPDF=/cvmfs/cms.cern.ch/slc6_amd64_gcc630/external/lhapdf/6.2.1
export PATH=$dirLHAPDF/bin:$PATH
export LD_LIBRARY_PATH=$dirLHAPDF/lib:$LD_LIBRARY_PATH
export PYTHONPATH=$dirLHAPDF/lib/python2.7/site-packages:$PYTHONPATH

Index=${1}
Mode=${2}
Order=${3}
if [ "$Mode" == "" ]; then
        echo "usage: $0 massIndex Mode(1-,3+) Order(0,2)"
        exit
fi
if [ "$Order" == "" ]; then
        echo "usage: $0 massIndex Mode(1-,3+) Order(0,2) "
        exit
fi

COM="14000d0"
MASS=`expr ${Index} \* 100 `
Width=`./wpwidth.exe ${MASS} | awk '{print$4}'`
PartialWidth=`./wpwidth.exe ${MASS} | awk '{print$6}'`
MassString=`printf "%d" $MASS`

PDFs=""
OrderString=""
if [ "$Order" == "0" ]; then
        PDFs="NNPDF31_nnlo_as_0118_nf_4"
#        PDFs="cteq6l1"
#        PDFs="NNPDF31_lo_as_0130"
        OrderString="LO"
elif [ "$Order" == "2" ]; then
#        PDFs="MSTW2008nnlo68cl"
        PDFs="NNPDF31_nnlo_as_0118_nf_4"
        OrderString="NNLO"
fi
ModeString=""
if [ "$Mode" == "1" ]; then
        ModeString="Wm"
elif [ "$Mode" == "3" ]; then
        ModeString="Wp"
fi
mainString="M${MassString}_${ModeString}_${Order}"
RunDir="run_${mainString}"

INPUT="${mainString}.txt"
OUTPUT="${mainString}.dat"
LOG="${mainString}.log"

cat << EOF > ${INPUT}
=============================================
'CMS collision energy (GeV)    = ' ${COM}
=============================================
'Factorization scale  (GeV)    = ' ${MASS}d0
'Renormalization scale  (GeV)  = ' ${MASS}d0
=============================================
'W production (1=pp W-, 2=ppbar W-, 3=pp W+, 4=ppbar W+) = ' ${Mode} 
=============================================
'Alpha QED                     = ' 0.0078125d0
'Fermi constant (1/GeV^2)      = ' 0.0000116637d0
=============================================
'W mass (GeV)                  = ' ${MASS}d0
'W width (GeV)                 = ' ${Width}d0
'W->lv partial width           = ' ${PartialWidth}d0
'sin^2(theta)                  = ' 0.22255d0
CKM matrix elements (not squared)
'Vud                           = ' 0.97428d0
'Vus=Vcd                       = ' 0.2253d0
'Vcs                           = ' 0.97345d0
'Vub                           = ' 0.00347d0
'Vcb                           = ' 0.041d0
=============================================
Vegas Parameters
'Relative accuracy (in %)           = ' 0d0
'Absolute accuracy                  = ' 0d0
'Number of calls per iteration      = ' 1000000
'Number of increase calls per iter. = ' 500000
'Maximum number of evaluations      = ' 200000000
'Random number seed for Vegas       = ' 111
=============================================
'QCD Perturb. Order (0=LO, 1=NLO, 2=NNLO) = ' ${Order}
'W pole focus (1=Yes, 0=No)     = ' 1
=============================================
'Lepton-pair invariant mass minimum = ' 0d0
'Lepton-pair invariant mass maximum = ' ${COM}d0
'Transverse mass minimum            = ' 0d0
'Transverse mass maximum            = ' ${COM}d0
'W pT minimum                       = ' 0d0
'W pT maximum                       = ' ${COM}d0
'W rapidity minimum                 = ' -20d0
'W rapidity maximum                 = ' 20d0
'Charged lepton pT minimum          = ' 0d0
'Charged lepton pT maximum          = ' ${COM}d0
'Missing pT minimum                 = ' 0d0
'Missing pT maximum                 = ' ${COM}d0
'pT min for softer lepton           = ' 0d0
'pT max for softer lepton           = ' 7000d0
'pT min for harder lepton           = ' 0d0
'pT max for harder lepton           = ' 7000d0
Taking absolute value of lepton pseudorapidity?
'(yes = 1, no = 0)                  = ' 1
'Ch. lepton pseudorapidity minimum  = ' 0d0
'Ch. lepton pseudorapidity maximum  = ' 100d0
JET DEFINITION-------------------------------
Jet Algorithm & Cone Size ('ktal'=kT algorithm, 'aktal'=anti-kT algorithm, 'cone'=cone)
'ktal, aktal or cone                = ' ktal
'Jet algorithm cone size (deltaR)   = ' 0.4d0
'DeltaR separation for cone algo    = ' 1.3
'Minimum pT for observable jets     = ' 20d0
'Maximum eta for observable jets    = ' 4.5d0
JET CUTS--------------------------------------
'Minimum Number of Jets             = ' 0
'Maximum Number of Jets             = ' 2
'Min. leading jet pT                = ' 0d0
ISOLATION CUTS-------------------------------
'Lep-missing deltaPhi min           = ' 0.0d0
'Lep-missing deltaPhi max           = ' 4.0d0
'Lep-Jet deltaR minimum             = ' 0.0d0
=============================================
(See manual for complete listing)
'PDF set =                        ' '${PDFs}'
'Turn off PDF error (1=Yes, 0=No)    = ' 1
(Active for MSTW2008 only, if PDF error is on:)
(Compute PDF+as errors: 1; just PDF errors: 0)
'Which alphaS                       = ' 0
(Active for MSTW2008 only; 0: 90 CL for PDFs+alphas, 1: 68 CL)
'PDF+alphas confidence level        = ' 1
=============================================
EOF

echo "mkdir ${RunDir}; cd ${RunDir}; ../fewzw -i ../${INPUT} -h ../histograms.txt -o ${RunDir} -p ../.. -s 0 &> screen_${MASS}_${Mode}${Order}.out  &"
echo "cd - " 
echo "########################################-----------------"
echo "./condor_run_je.sh w ${RunDir} ${INPUT} histograms.txt ${OUTPUT} . "
./condor_run_je.sh w ${RunDir} ${INPUT} histograms.txt ${OUTPUT} . 
#echo "./local_run.sh w ${RunDir} ${INPUT} histograms.txt ${OUTPUT} . "
#./local_run.sh w ${RunDir} ${INPUT} histograms.txt ${OUTPUT} . 
echo "./finish.sh ${RunDir} ${OrderString}.${OUTPUT}" > ${RunDir}/finishCMD.txt
cat ${RunDir}/finishCMD.txt

echo "Next: cd ${RunDir}; condor_submit job.jdl; cd - "
if [ "$4" == "-submit" ]; then
        echo "Done: cd ${RunDir}; condor_submit job.jdl; cd - "
#cd $runDir
#condor_submit job.jdl
fi

