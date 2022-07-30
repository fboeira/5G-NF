#!/bin/bash

# This script is used with slurm for cluster job scheduling

# This script starts the lemma indices given by the --array flag in sbatch
# Run 'bash job_array.sh -h' to print the indices if only a subset of lemmas are to be submitted as jobs to the cluster
# To submit a range of jobs, for example: sbatch --array=0-17 job_array.sh
# For specific indices, for example: sbatch --array=5,8,10 job_array.sh


#SBATCH -J 5G-NR # A single job name for the array
#SBATCH -n 16
#SBATCH -t 8:00:00 # timeout
#SBATCH -o output_NF_normal/5G-%A%a.out # Standard output
#SBATCH -e output_NF_normal/5G-%A%a.err # Standard error

export ID=${SLURM_ARRAY_TASK_ID}

LEMMAS=('rand_autn_src' 'main_sources' 'sqn_src' 'sqn_ue_increase' 'sqn_ue_unique' 'rand_sources_1' 'rand_sources_2' 'autn_sources_1' 'autn_sources_2' 'relay_SMC_sources' 'UE_sec_capabilities_sources' 'SMComplete_sources' '5G_HE_AV_sources' 'Attach_SUPI_sources' 'UE_sec_capabilities_attach_sources' 'RES_star_sources' 'trace_exists_AS_SMComplete' 'secrecy_Ki' 'secrecy_AUSF' 'secrecy_SEAF' 'secrecy_KAMF' 'secrecy_KgNB' 'agreement_UE_KgNB_GNB' 'agreement_GNB_KgNB_UE')

if [ "$1" = "-h" ]; then
	for i in "${!LEMMAS[@]}"; do
		printf '${LEMMAS[%s]}=%s\n' "$i" "${LEMMAS[i]}"
	done
	exit 0
fi

collectl -f output_NF_normal/stats_${LEMMAS[$ID]} -sZ -i:1 --procfilt P$$ -F0 & # collects stats about all children from this script

tamarin-prover 5G_NF_normal.spthy \
--prove=${LEMMAS[$ID]} \
--heuristic=O --oraclename=5G_NF_normal.oracle \
--output=output_NF_normal/output_${LEMMAS[$ID]} +RTS -N16 -RTS 2>/dev/null

#--heuristic=O --oraclename=5G_NR.oracle \
#--heuristic=S \
exit 0