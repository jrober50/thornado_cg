#!/bin/bash

#set -x

###########################################################################################
###  Common Modules and Enviroment Variables.
###########################################################################################

function set_common(){


   export EXASTAR_HOME=/localdisk/quanshao/ExaStar
   export HDF5_INC=${EXASTAR_HOME}/hdf57/include
   export HDF5_LIB=${EXASTAR_HOME}/hdf57/lib64
   export THORNADO_DIR=${EXASTAR_HOME}/thornado-dev
   export WEAKLIB_DIR=${EXASTAR_HOME}/weaklib
   export WEAKLIB_TABLES_DIR=${EXASTAR_HOME}/weaklib-tables
   export THORNADO_MACHINE=beacon_intel
   export IGC_OverrideOCLMaxParamSize=4096
   export MPIR_CVAR_ENABLE_GPU=0

## for running


   export LTTNG_HOME=$EXASTAR_HOME
   mkdir -p $LTTNG_HOME
   export LD_LIBRARY_PATH=${HDF5_LIB}:$LD_LIBRARY_PATH
   export LIBOMPTARGET_PLUGIN=LEVEL0
   #export ONEAPI_DEVICE_FILTER=level_zero:gpu
   ##export LIBOMPTARGET_PLUGIN=OPENCL
   export LIBOMPTARGET_DEBUG=0
   #export EnableImplicitScaling=1
   export ZE_AFFINITY_MASK=0.0
   #export LIBOMPTARGET_PLUGIN_PROFILE=T
   #export OMP_TARGET_OFFLOAD=DISABLED
   export OMP_TARGET_OFFLOAD=MANDATORY
   #export OMP_TARGET_OFFLOAD=DISABLED
   #unset OMP_TARGET_OFFLOAD
   export OMP_NUM_THREADS=1
   ulimit -s unlimited
   #ulimit -n 20480
   ## The following seems working well for the SineWaveStream app.
   export LIBOMPTARGET_LEVEL0_MEMORY_POOL=device,128,64, 16384
   #export LIBOMPTARGET_LEVEL_ZERO_COMMAND_BATCH=copy,8
   #export OMP_NUM_THREADS=1
}

###########################################################################################
###  Make Script
###########################################################################################

function buildApp(){

   echo $MKLROOT |& tee -a $LOG_FILE 
   module list   |& tee -a $LOG_FILE

   make clean
   ( time make $APP_NAME ${USER_OPTION} USE_OMP_OL=TRUE USE_GPU=TRUE USE_CUDA=FALSE USE_ONEMKL=TRUE ) |& tee -a $LOG_FILE
}

###########################################################################################
###  Run Script
###########################################################################################

function runApp(){

   module load iprof
   module list |& tee -a $LOG_FILE

# For vtune
##   source /sharedjf/mjh/tools/Intel_VTune_Profiler_2022.3.0_nda/env/vars.sh
##   VT_OUTPUT=vtune07June2022
##   rm -rf $VT_OUTPUT

# echo some env variables to $LOG_FILE   

   echo "ZE_AFFINITY_MASK="${ZE_AFFINITY_MASK}                                |& tee -a $LOG_FILE
   echo "EnableImplicitScaling="${EnableImplicitScaling}                      |& tee -a $LOG_FILE
   echo "LIBOMPTARGET_LEVEL0_MEMORY_POOL="${LIBOMPTARGET_LEVEL0_MEMORY_POOL}  |& tee -a $LOG_FILE


   #( time ./${APP_NAME}_${THORNADO_MACHINE} ) |& tee -a $LOG_FILE
   #( time iprof ./${APP_NAME}_${THORNADO_MACHINE} ) |& tee -a $LOG_FILE
   #(time /nfs/pdx/home/mheckel/pti-gpu/tools/bin/onetrace -h -d -v ./${APP_NAME}_${THORNADO_MACHINE} ) |& tee -a $LOG_FILE
   #( time  gdb-oneapi ./${APP_NAME}_${THORNADO_MACHINE}) |& tee $OUTPUT_LOG
   #valgrind --tool=memcheck --leak-check=yes --show-reachable=yes --track-fds=yes ./${APP_NAME}_${THORNADO_MACHINE}|& tee -a $OUTPUT_LOG
   #vtune -collect gpu-hotspots -knob characterization-mode=global-local-accesses -data-limit=0 -r sineWaveMS69vtune ./${APP_NAME}_${THORNADO_MACHINE} |& tee -a $OUTPUT_LOG
   advisor --collect=roofline --data-limit=0 --profile-gpu --project-dir=/localdisk/quanshao/ExaStar/thornado-dev/ -- ./${APP_NAME}_${THORNADO_MACHINE} |& tee -a $OUTPUT_LOG
   #(vtune -collect gpu-hotspots -knob target-gpu=0:154:0.0 -ring-buffer 10 -r $VT_OUTPUT ./${APP_NAME}_${THORNADO_MACHINE}) |& tee -a $OUTPUT_LOG
    #(vtune -collect gpu-hotspots -knob target-gpu=0:154:0.0 -r $VT_OUTPUT ./${APP_NAME}_${THORNADO_MACHINE}) |& tee -a $OUTPUT_LOG
##   vtune-backend --allow-remote-access --enable-server-profiling --reset-passphrase --web-port 8080 --data-directory=${VT_OUTPUT}

   echo "Log file:" $LOG_FILE "writting finished"
}


###########################################################################################
###  Main 
###########################################################################################

module purge

#export A21_SDK_MKLROOT_OVERRIDE=/exaperf/nightly/mkl-cev/2022.11.02 ## Latest nightly, i.e. 10.06, uses this mkl

export IGC_EnableZEBinary=0

export COMPILER_DATE="2023.03.10"
#export COMPILER_DATE="2022.12.30.002"
export AADEBUG=""

#export ONEAPI_MODULE_OVERRIDE=oneapi/eng-compiler/2022.12.30.003
module load nightly-compiler/${COMPILER_DATE}
#module load oneapi/eng-compiler/${COMPILER_DATE}
#module switch -f intel_compute_runtime/release/agama-devel-551 neo/agama-devel-sp3/573-23.05.25593.9-i572
#module switch -f intel_compute_runtime/release/pvc-prq-66 neo/agama-devel-sp3/552-22.49.25018.21-i550
module switch -f mpi/aurora_mpich/icc-sockets/51.2 mpi/aurora_mpich/icc-sockets/49.1

module use /nfs/pdx/home/mheckel/modules/modulefiles_nightly
module load nightly-advisor/23.1.0.613762

opLevels=(O3)

appNames=(ApplicationDriver)
logFiles=(sineWave)
userOptions=("")

#appNames=(ApplicationDriver_Neutrinos)
#logFiles=(relax)
#userOptions=("MICROPHYSICS=WEAKLIB")

#opLevels=(O0 O1 O2 O3)
#appNames=(ApplicationDriver ApplicationDriver_Neutrinos)
#logFiles=(sineWave relax)
#userOptions=("" "MICROPHYSICS=WEAKLIB")

set_common

for ((jj=0; jj<${#appNames[@]}; jj++));
do
   for op in "${opLevels[@]}"
   do 
      export OP_LEVEL=$op
      export APP_NAME=${appNames[jj]}
      export LOG_FILE=${logFiles[jj]}.${OP_LEVEL}.${COMPILER_DATE}.ms69Roofline
      export USER_OPTION=${userOptions[jj]}
      echo "Building and running" ${logFiles[jj]} "using Op-level "${OP_LEVEL} 
      echo $USER_OPTION
      rm $LOG_FILE
#      rm ${APP_NAME}_${THORNADO_MACHINE}

      if [[ "$1" == -[rR]* ]]; then
         if [ -f "${APP_NAME}_${THORNADO_MACHINE}" ];then
            runApp
         else
            echo "The executable does not exist", ${APP_NAME}_${THORNADO_MACHINE}
         fi
      elif [[ "$1" == -[bB]* ]]; then
         buildApp
      else
         buildApp
         if [ -f "${APP_NAME}_${THORNADO_MACHINE}" ];then
            runApp
         else
            echo "The executable does not exist", ${APP_NAME}_${THORNADO_MACHINE}
         fi
      fi      

   done
done
