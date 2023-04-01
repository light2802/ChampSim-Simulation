#!/bin/bash
set -e
replacement_policies=("drrip" "lru" "srrip")

for replacement_policy in ${replacement_policies[@]}
do
    echo "Building Replacement policy $replacement_policy"
    cd ChampSim
    rm -f Makefile
    config_file=champsim_config_${replacement_policy}.json
    jq '.LLC.replacement = $RP' --arg RP "$replacement_policy" champsim_config.json > $config_file
    ./config.sh $config_file
    make -j4
	mv bin/champsim bin/champsim_$replacement_policy
    cd ..
    mkdir -p ./logs/${replacement_policy}
done

while read benchmark_program; do
	echo "Getting program trace $benchmark_program"
	wget https://dpc3.compas.cs.stonybrook.edu/champsim-traces/speccpu/$benchmark_program
	for replacement_policy in ${replacement_policies[@]}
	do
		echo "Running simulation for replacement policy $replacement_policy"
	    ./ChampSim/bin/champsim_$replacement_policy --warmup_instructions 200000000 --simulation_instructions 500000000 ${benchmark_program} | tee ./logs/${replacement_policy}/${benchmark_program%.*}.log
	done
	rm $benchmark_program
done <program_list
