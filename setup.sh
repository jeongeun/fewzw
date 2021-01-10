#!bin/bash

export SCRAM_ARCH=slc6_amd64_gcc630
export VO_CMS_SW_DIR=/cvmfs/cms.cern.ch
source $VO_CMS_SW_DIR/cmsset_default.sh
cd /cvmfs/cms.cern.ch/slc6_amd64_gcc630/cms/cmssw/CMSSW_10_1_9
eval `scramv1 runtime -sh` # -- cmsenv

cd /hcp/data/data02/jelee/FEWZ/FEWZ_3.1.rc 


if [ $FEWZ_PATH ]; then
    echo "KP_ANALYZER_PATH is already defined: use a clean shell!"
    return 1
fi

export FEWZ_PATH=$(pwd)
export PYTHONPATH=${FEWZ_PATH}:${PYTHONPATH}

#export dirLHAPDF=/cvmfs/cms.cern.ch/slc6_amd64_gcc630/external/lhapdf/6.2.1
export dirLHAPDF=/cvmfs/cms.cern.ch/slc6_amd64_gcc630/external/lhapdf/6.2.1-omkpbe3/
 # -- same with $LHAPDF_DATA_PATH/../../lib

export PATH=$dirLHAPDF/bin:$PATH
export LD_LIBRARY_PATH=$dirLHAPDF/lib:$LD_LIBRARY_PATH
export PYTHONPATH=$dirLHAPDF/lib/python2.7/site-packages:$PYTHONPATH
