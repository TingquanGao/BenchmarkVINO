MODEL_DIR=$1
#VERSION=2021
VERSION=2022
#VERSION=2023
IF_CONVERT=true
#IF_CONVERT=false
ONNX_DIR="./tmp/onnx_models/"
VINO_DIR="./tmp/openvino_models/"
CONVERT_LOG_DIR="./tmp/convert_logs/"
BENCHMARK_LOG_DIR="./tmp/benchmark_logs/"
#input_shape=[1,3,224,224]
input_shape=[1,3,48,320]
#input_shape=[1,3,640,640]
MODEL_LIST=`cat "${MODEL_DIR}/model_list.txt"`

# openvino benchmark
NITER=1000
NWARMUP=100
BATCHSIZE_LIST="1"
NTHERADS_LIST="10"


function status_check(){
    last_status=$1   # the exit code
    run_command=$2
    run_log=$3
    if [ $last_status -eq 0 ]; then
        echo -e "\033[33m Run successfully with command - ${run_command}!  \033[0m" | tee -a ${run_log}
    else
        echo -e "\033[33m Run failed with command - ${run_command}!  \033[0m" | tee -a ${run_log}
    fi
}


if $IF_CONVERT; then
    echo "===============convert==============="
    mkdir -p ${CONVERT_LOG_DIR}
    mkdir -p ${ONNX_DIR}
    mkdir -p ${VINO_DIR}

    for model in $MODEL_LIST
    do
        cmd="paddle2onnx --model_dir ./${MODEL_DIR}/${model} --model_filename ./${MODEL_DIR}/${model}/inference.pdmodel --params_filename ./${MODEL_DIR}/${model}/inference.pdiparams --save_file $ONNX_DIR/${model}.onnx --opset_version 11 --enable_onnx_checker True > ${CONVERT_LOG_DIR}/${model}_paddle2onnx.log 2>&1"
        eval $cmd
        status_check $? "${cmd}" "${status_log}"

        cmd="mo --input_model $ONNX_DIR/${model}.onnx --data_type FP32 --output_dir $VINO_DIR/${model}/ --input_shape ${input_shape} > ${CONVERT_LOG_DIR}/${model}_onnx2vino.log 2>&1"
        eval $cmd
        status_check $? "${cmd}" "${status_log}"
    done
fi


echo "===============benchmark==============="
mkdir -p ${BENCHMARK_LOG_DIR}
mkdir -p benchmark_profiling

for nthreads in ${NTHERADS_LIST}
do
    for batchsize in ${BATCHSIZE_LIST}
    do
        for model in $MODEL_LIST
        do
            model_path=${VINO_DIR}/${model}/${model}.xml
            if [ -d $model_path ]
            then
                echo "The model no exists:"${model}
                continue
            fi
            sleep 1s
            if [ "${VERSION}" == "2021" ]; then
                cmd="benchmark_app -m ${model_path} -d CPU -niter ${NITER} -b ${batchsize} -nthreads ${nthreads} -api sync > ${BENCHMARK_LOG_DIR}/${model}_bs_${batchsize}_ntherads_${nthreads}.log 2>&1"
      else
                cmd="benchmark_app --report_type detailed_counters -m ${model_path} -d CPU -niter ${NITER} -b ${batchsize} -nthreads ${nthreads} -api sync -hint none > ${BENCHMARK_LOG_DIR}/${model}_bs_${batchsize}_ntherads_${nthreads}.log 2>&1"
                #cmd="benchmark_app -m ${model_path} -d CPU -niter ${NITER} -b ${batchsize} -nthreads ${nthreads} -api sync -hint none > ${BENCHMARK_LOG_DIR}/${model}_bs_${batchsize}_ntherads_${nthreads}.log 2>&1"
      fi
            eval $cmd
            status_check $? "${cmd}" "${status_log}"
            mv ./benchmark_detailed_counters_report.csv ./benchmark_profiling/${model}.csv
        done
    done
done

echo "===============summary==============="
for log in `ls ${BENCHMARK_LOG_DIR}`
do
    if [ "${VERSION}" == "2021" ]; then
        latency=`cat ${BENCHMARK_LOG_DIR}/${log} | grep "Latency" | awk -F ':' '{print $2}' | awk -F ' ' '{print $1}'`
    else
        latency=`cat ${BENCHMARK_LOG_DIR}/${log} | grep "Average" | awk -F ':' '{print $2}' | awk -F ' ' '{print $1}'`
    fi
    model=`echo ${log} | awk -F '.log' '{print $1}'`
    echo $model $latency
done
