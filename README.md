This is the README associated with the submission of the paper entitled "Provable Non-Frameability for 5G Lawful Interception"

The main file is 5G.m4 and it is used as the base to generate all Tamarin files. To generate the model variants, we use the script 'generate_tamarin_files.sh', which sets the m4 macros, changes channels to read-only if necessary, etc.

We use a computing cluster with the slurm task scheduler, hence the 'job*.sh' files are used to run the prover in the cluster environment. For convenience, we have provided the computed proofs for our results in the directories '5G_NF_all_DY' and '5G_NF_all_RO'. These directories contain Tamarin files with the proofs for the results shown in Table II.
