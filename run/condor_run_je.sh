#!/bin/bash -e

# Sets up and starts a run using the Condor system
# Usage: condor_run.sh w/z <run_dir> <input_file> <histo_file> <output_file_extension> <pdf_dir> [ <which_sect> ]
#    or  condor_run.sh w/z <run_dir> <input_file> <histo_file> <output_file_extension> <pdf_dir> [ <init_sect> <last_sect> <sectloop_step> ]
#  Note: <which_sect> is optional and for advanced user only
#        <which_sect> specifies the one sector that user want to submit to condor system
#        <init_sect> <last_sect> <sectloop_step> specifies the sectors desired to run through the loop:
#                                                FOR <sect_num> FROM <init_sect> TO <last_sect> STEP <sectloop_step>

condorusage(){
echo "Usage: `basename $0` w/z <run_dir> <input_file> <histo_file> <output_file_extension> <pdf_dir>"
exit 1
}
#[ $# -lt 6 ] && condorusage \
#             || printf "Running Directory: $2\nInput Setting: $INFILE\nHistogram File: $4\nOutput File: $5\nPDF Directory $6\n"
[ $# -lt 6 ] && condorusage

BOSON=$1
INFILE=$3
OUTFILE=$5
HISTFILE=$4
RUNDIR=${2%/}
PDFDIR=${6%/}

### Turn the directory into relative directory just in case
RUNDIR=`python scripts/get_relpath.py $RUNDIR ./`
PDFDIR=`python scripts/get_relpath.py $PDFDIR ./`

### Check first argument, to make sure supported, and set executable
if [ $BOSON = "z" ] || [ $BOSON = "w" ]; then
   #EXEC=condor_fewz$BOSON
   EXEC=fewz$BOSON
else
   echo "Unrecognized argument; defaulting to neutral current."
   #EXEC=condor_fewzz
   EXEC=fewzz
fi

### Prepare the output directory structure and condor_submit file
python scripts/create_parallel.py $BOSON $INFILE $RUNDIR
if ! [ -e $RUNDIR/$EXEC ] ; then
   cp $EXEC $RUNDIR/
fi
#if ! [ -e $RUNDIR/$INFILE ] ; then ### always copy input file, in case changed
cp $INFILE $RUNDIR/
#fi
if ! [ -e $RUNDIR/$HISTFILE ] ; then
    python scripts/get_bin_files.py $HISTFILE $RUNDIR
#   if [ -d "$RUNDIR/${RUNDIR}0/pscale" ] || [ -d "$RUNDIR/${RUNDIR}0/mscale" ] ; then
#        cat $RUNDIR/$HISTFILE | sed -e "s/'\.\.\//'..\/..\//g" > $RUNDIR/pm_$HISTFILE
#    fi
fi
python scripts/create_condor_jobs.py $BOSON ${RUNDIR##*/} $INFILE $HISTFILE $OUTFILE $PDFDIR
cd $RUNDIR
mkdir condorLog
### Now ready to submit condor job
### Provide option to hack the condor_submit file if the user only want to submit for a few sectors
if [ $# -le 6 ] ; then
   ### submit all sectors at once
   #echo "condor_submit job_desc"


cat << EOF > condorRun.sh
#!/bin/bash

export SCRAM_ARCH=slc6_amd64_gcc630
export VO_CMS_SW_DIR=/cvmfs/cms.cern.ch
source \$VO_CMS_SW_DIR/cmsset_default.sh
cd /cvmfs/cms.cern.ch/slc6_amd64_gcc630/cms/cmssw/CMSSW_10_1_9
eval \`scramv1 runtime -sh\`
cd -
export dirLHAPDF=/cvmfs/cms.cern.ch/slc6_amd64_gcc630/external/lhapdf/6.2.1
export PATH=\$dirLHAPDF/bin:\$PATH
export LD_LIBRARY_PATH=\$dirLHAPDF/lib:\$LD_LIBRARY_PATH
export PYTHONPATH=\$dirLHAPDF/lib/python2.7/site-packages:\$PYTHONPATH

#date > time
#ldd ../fewzw
EOF

numSection=`grep "Queue" job_desc  | awk '{print $2}'`      
### LO case
if [ ${numSection} == "1" ]; then 
cat << EOF >> condorRun.sh
RunIdx=\$1

cd /hcp/data/data02/jelee/FEWZ/FEWZ_3.1.rc/run/${RUNDIR} ## NB. <- set your rundirectory 
echo "./fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR} -p ../.. -s 0 &> screen.out &"
./fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR} -p ../.. -s 0 &> screen.out
#echo "STARTTIME `date`" ; time ../fewzw  -i  ../${INFILE} -h ../${HISTFILE} -p ../.. -o ${RUNDIR} -s \${1} &> screen.out; echo "ENDTIME `date`";
#date >> time
exit
EOF
echo "$numSection"; fi

### NNLO case
if [ ${numSection} == "154" ]; then
cat << EOF >> condorRun.sh
RunIdx=\$1

cd /hcp/data/data02/jelee/FEWZ/FEWZ_3.1.rc/run/${RUNDIR}  ## NB. <- set your rundirectory 
if [ "\$RunIdx" == "0" ]; then cd ${RUNDIR}0; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 0 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "1" ]; then cd ${RUNDIR}1; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 1 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "2" ]; then cd ${RUNDIR}2; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 2 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "3" ]; then cd ${RUNDIR}3; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 3 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "4" ]; then cd ${RUNDIR}4; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 4 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "5" ]; then cd ${RUNDIR}5; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 5 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "6" ]; then cd ${RUNDIR}6; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 6 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "7" ]; then cd ${RUNDIR}7; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 7 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "8" ]; then cd ${RUNDIR}8; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 8 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "9" ]; then cd ${RUNDIR}9; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 9 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "10" ]; then cd ${RUNDIR}10; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 10 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "11" ]; then cd ${RUNDIR}11; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 11 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "12" ]; then cd ${RUNDIR}12; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 12 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "13" ]; then cd ${RUNDIR}13; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 13 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "14" ]; then cd ${RUNDIR}14; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 14 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "15" ]; then cd ${RUNDIR}15; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 15 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "16" ]; then cd ${RUNDIR}16; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 16 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "17" ]; then cd ${RUNDIR}17; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 17 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "18" ]; then cd ${RUNDIR}18; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 18 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "19" ]; then cd ${RUNDIR}19; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 19 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "20" ]; then cd ${RUNDIR}20; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 20 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "21" ]; then cd ${RUNDIR}21; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 21 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "22" ]; then cd ${RUNDIR}22; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 22 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "23" ]; then cd ${RUNDIR}23; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 23 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "24" ]; then cd ${RUNDIR}24; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 24 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "25" ]; then cd ${RUNDIR}25; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 25 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "26" ]; then cd ${RUNDIR}26; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 26 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "27" ]; then cd ${RUNDIR}27; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 27 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "28" ]; then cd ${RUNDIR}28; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 28 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "29" ]; then cd ${RUNDIR}29; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 29 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "30" ]; then cd ${RUNDIR}30; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 30 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "31" ]; then cd ${RUNDIR}31; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 31 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "32" ]; then cd ${RUNDIR}32; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 32 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "33" ]; then cd ${RUNDIR}33; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 33 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "34" ]; then cd ${RUNDIR}34; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 34 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "35" ]; then cd ${RUNDIR}35; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 35 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "36" ]; then cd ${RUNDIR}36; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 36 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "37" ]; then cd ${RUNDIR}37; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 37 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "38" ]; then cd ${RUNDIR}38; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 38 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "39" ]; then cd ${RUNDIR}39; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 39 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "40" ]; then cd ${RUNDIR}40; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 40 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "41" ]; then cd ${RUNDIR}41; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 41 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "42" ]; then cd ${RUNDIR}42; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 42 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "43" ]; then cd ${RUNDIR}43; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 43 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "44" ]; then cd ${RUNDIR}44; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 44 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "45" ]; then cd ${RUNDIR}45; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 45 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "46" ]; then cd ${RUNDIR}46; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 46 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "47" ]; then cd ${RUNDIR}47; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 47 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "48" ]; then cd ${RUNDIR}48; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 48 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "49" ]; then cd ${RUNDIR}49; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 49 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "50" ]; then cd ${RUNDIR}50; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 50 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "51" ]; then cd ${RUNDIR}51; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 51 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "52" ]; then cd ${RUNDIR}52; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 52 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "53" ]; then cd ${RUNDIR}53; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 53 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "54" ]; then cd ${RUNDIR}54; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 54 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "55" ]; then cd ${RUNDIR}55; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 55 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "56" ]; then cd ${RUNDIR}56; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 56 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "57" ]; then cd ${RUNDIR}57; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 57 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "58" ]; then cd ${RUNDIR}58; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 58 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "59" ]; then cd ${RUNDIR}59; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 59 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "60" ]; then cd ${RUNDIR}60; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 60 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "61" ]; then cd ${RUNDIR}61; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 61 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "62" ]; then cd ${RUNDIR}62; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 62 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "63" ]; then cd ${RUNDIR}63; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 63 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "64" ]; then cd ${RUNDIR}64; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 64 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "65" ]; then cd ${RUNDIR}65; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 65 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "66" ]; then cd ${RUNDIR}66; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 66 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "67" ]; then cd ${RUNDIR}67; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 67 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "68" ]; then cd ${RUNDIR}68; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 68 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "69" ]; then cd ${RUNDIR}69; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 69 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "70" ]; then cd ${RUNDIR}70; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 70 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "71" ]; then cd ${RUNDIR}71; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 71 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "72" ]; then cd ${RUNDIR}72; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 72 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "73" ]; then cd ${RUNDIR}73; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 73 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "74" ]; then cd ${RUNDIR}74; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 74 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "75" ]; then cd ${RUNDIR}75; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 75 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "76" ]; then cd ${RUNDIR}76; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 76 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "77" ]; then cd ${RUNDIR}77; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 77 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "78" ]; then cd ${RUNDIR}78; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 78 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "79" ]; then cd ${RUNDIR}79; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 79 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "80" ]; then cd ${RUNDIR}80; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 80 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "81" ]; then cd ${RUNDIR}81; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 81 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "82" ]; then cd ${RUNDIR}82; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 82 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "83" ]; then cd ${RUNDIR}83; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 83 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "84" ]; then cd ${RUNDIR}84; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 84 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "85" ]; then cd ${RUNDIR}85; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 85 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "86" ]; then cd ${RUNDIR}86; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 86 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "87" ]; then cd ${RUNDIR}87; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 87 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "88" ]; then cd ${RUNDIR}88; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 88 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "89" ]; then cd ${RUNDIR}89; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 89 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "90" ]; then cd ${RUNDIR}90; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 90 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "91" ]; then cd ${RUNDIR}91; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 91 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "92" ]; then cd ${RUNDIR}92; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 92 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "93" ]; then cd ${RUNDIR}93; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 93 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "94" ]; then cd ${RUNDIR}94; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 94 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "95" ]; then cd ${RUNDIR}95; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 95 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "96" ]; then cd ${RUNDIR}96; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 96 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "97" ]; then cd ${RUNDIR}97; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 97 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "98" ]; then cd ${RUNDIR}98; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 98 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "99" ]; then cd ${RUNDIR}99; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 99 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "100" ]; then cd ${RUNDIR}100; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 100 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "101" ]; then cd ${RUNDIR}101; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 101 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "102" ]; then cd ${RUNDIR}102; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 102 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "103" ]; then cd ${RUNDIR}103; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 103 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "104" ]; then cd ${RUNDIR}104; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 104 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "105" ]; then cd ${RUNDIR}105; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 105 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "106" ]; then cd ${RUNDIR}106; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 106 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "107" ]; then cd ${RUNDIR}107; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 107 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "108" ]; then cd ${RUNDIR}108; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 108 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "109" ]; then cd ${RUNDIR}109; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 109 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "110" ]; then cd ${RUNDIR}110; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 110 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "111" ]; then cd ${RUNDIR}111; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 111 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "112" ]; then cd ${RUNDIR}112; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 112 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "113" ]; then cd ${RUNDIR}113; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 113 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "114" ]; then cd ${RUNDIR}114; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 114 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "115" ]; then cd ${RUNDIR}115; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 115 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "116" ]; then cd ${RUNDIR}116; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 116 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "117" ]; then cd ${RUNDIR}117; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 117 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "118" ]; then cd ${RUNDIR}118; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 118 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "119" ]; then cd ${RUNDIR}119; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 119 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "120" ]; then cd ${RUNDIR}120; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 120 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "121" ]; then cd ${RUNDIR}121; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 121 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "122" ]; then cd ${RUNDIR}122; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 122 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "123" ]; then cd ${RUNDIR}123; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 123 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "124" ]; then cd ${RUNDIR}124; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 124 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "125" ]; then cd ${RUNDIR}125; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 125 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "126" ]; then cd ${RUNDIR}126; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 126 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "127" ]; then cd ${RUNDIR}127; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 127 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "128" ]; then cd ${RUNDIR}128; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 128 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "129" ]; then cd ${RUNDIR}129; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 129 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "130" ]; then cd ${RUNDIR}130; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 130 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "131" ]; then cd ${RUNDIR}131; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 131 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "132" ]; then cd ${RUNDIR}132; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 132 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "133" ]; then cd ${RUNDIR}133; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 133 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "134" ]; then cd ${RUNDIR}134; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 134 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "135" ]; then cd ${RUNDIR}135; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 135 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "136" ]; then cd ${RUNDIR}136; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 136 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "137" ]; then cd ${RUNDIR}137; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 137 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "138" ]; then cd ${RUNDIR}138; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 138 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "139" ]; then cd ${RUNDIR}139; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 139 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "140" ]; then cd ${RUNDIR}140; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 140 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "141" ]; then cd ${RUNDIR}141; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 141 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "142" ]; then cd ${RUNDIR}142; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 142 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "143" ]; then cd ${RUNDIR}143; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 143 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "144" ]; then cd ${RUNDIR}144; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 144 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "145" ]; then cd ${RUNDIR}145; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 145 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "146" ]; then cd ${RUNDIR}146; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 146 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "147" ]; then cd ${RUNDIR}147; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 147 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "148" ]; then cd ${RUNDIR}148; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 148 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "149" ]; then cd ${RUNDIR}149; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 149 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "150" ]; then cd ${RUNDIR}150; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 150 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "151" ]; then cd ${RUNDIR}151; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 151 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "152" ]; then cd ${RUNDIR}152; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 152 &> screen.out; echo "ENDTIME `date`"; fi
if [ "\$RunIdx" == "153" ]; then cd ${RUNDIR}153; echo "STARTTIME `date`" ; time ../fewzw -i ../${INFILE} -h ../${HISTFILE} -o ${RUNDIR}.dat -p ../.. -s 153 &> screen.out; echo "ENDTIME `date`"; fi
EOF
echo "$numSection"; fi

chmod   +x condorRun.sh  
find . -maxdepth 1 -type d -exec chmod 777 {} \;  
find . -maxdepth 1 -name "*.txt" -exec chmod 744 {} \; 


cat << EOF > job.jdl     
executable = condorRun.sh 
universe = vanilla  
arguments = \$(Process) 
output   = condorLog/condor_\$(Cluster).\$(Process).log  
error    = condorLog/condor_\$(Cluster).\$(Process).log
log      = /dev/null
should_transfer_files = yes
when_to_transfer_output = ON_EXIT
getenv = true
queue ${numSection}
EOF

     echo "condor_submit job.jdl 2>&1 | tee jobID.log"
else
   ### submit only job for one sector or sectors given by the loop "from `init_sect' to `last_sect' by `sectloop_step'"
   # default values of optional arguments if not given
   INIT_SECT=0
   LAST_SECT=0
   SECT_STEP=1
   # read in optional arguments if given
   # skip checking arguments to let condor handle it (condor wil quit if the sector doesn't exist)
   [ $# -ge 7 ] && INIT_SECT=$7
   [ $# -eq 7 ] && LAST_SECT=$INIT_SECT
   [ $# -ge 8 ] && LAST_SECT=$8
   [ $# -ge 9 ] && SECT_STEP=$9
   JOBFILE=job_part_1
   i=1
   while [ -f $JOBFILE ]; do i=$(($i+1)); JOBFILE=job_part_$i; done # don't overwrite existing job files
   cd ..
   python scripts/create_condor_jobs.py $BOSON ${RUNDIR##*/} $INFILE $HISTFILE $OUTFILE $PDFDIR $JOBFILE $INIT_SECT $LAST_SECT $SECT_STEP
   cd $RUNDIR
   #condor_submit $JOBFILE
fi

echo "Run the following to post-process output files: ./finish.sh $RUNDIR <order>.$OUTFILE" > "`basename $RUNDIR`.finish"
orderType=`cat $3 | grep Order | cut -f 3 -d"'" | awk '{print $1}'`
finishFile="../`basename $RUNDIR`.finish" 
if [ "$orderType" == "0" ]; then echo "./finish.sh $RUNDIR LO.$OUTFILE"   >> $finishFile ; fi
if [ "$orderType" == "1" ]; then echo "./finish.sh $RUNDIR NLO.$OUTFILE"  >> $finishFile ; fi
if [ "$orderType" == "2" ]; then echo "./finish.sh $RUNDIR NNLO.$OUTFILE" >> $finishFile ; fi
cat $finishFile
