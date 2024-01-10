#!/bin/bash
#
#PBS -q home
#PBS -N m2050_tbaseline_pregionalces_rbaseline_linear
#PBS -l nodes=1:ppn=16
#PBS -l walltime=26:00:00
#PBS -o m2050_tbaseline_pregionalces_rbaseline_linear.stdout
#PBS -V
#PBS -M fkucuksayacigil@ucsd.edu
#PBS -m abe
#PBS -j oe

# set -x # Setting the -x tells Bash to print out the statements as they are being executed. (https://code-maven.com/bash-set-x)

# bashname=$0 # Get the name of the bash file
# runname="${bashname%.sh}" # Remove .sh from the bash name, and it becomes the run name
# If you use () in variable setting,, it means you create a list
# runname=m2050_tbaseline_pstate_rbaseline_nosensitivity

runname="$PBS_JOBNAME"

echo "I am running $runname"

# echo $runname
# echo ${runname} # There is no difference from echo $runname

cat $PBS_NODEFILE
echo 'The list above shows the nodes this job has exclusive access to.'

cd $PBS_O_WORKDIR

# mkdir Results_m2050_tbaseline_pstate_rbaseline_nosensitivity
# mkdir Results_m2050_tbaseline_pstate_rbaseline_nosensitivity/Dispatch

mkdir Results_$runname
mkdir Results_$runname/Dispatch

source /etc/profile.d/modules.sh

module load julia

# julia ../Run/$runname.jl $runname
julia ../Run.jl $runname

# mv Results_$runname /home/fkucuksayacigil/Results_$runname
mv Results_$runname /home/fkucuksayacigil/Results/Results_$runname

# mv $runname.stdout /home/fkucuksayacigil/Results_$runname/${runname}.stdout

exit 0
