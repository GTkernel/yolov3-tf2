#!/bin/bash

TIMESTAMP=$(date +%Y%m%d-%H:%M:%S)
mkdir -p data
NUMINSTANCE=1

function util_get_running_time() {
    local container_name=$1
    local start=$(docker inspect --format='{{.State.StartedAt}}' $container_name | xargs date +%s.%N -d)
    local end=$(docker inspect --format='{{.State.FinishedAt}}' $container_name | xargs date +%s.%N -d)
    local running_time=$(echo $end - $start | tr -d $'\t' | bc)

    echo $running_time
}

function measure_latency_monolithic() {
    local numinstances=$1
    local container_list=()
    local rusage_logging_dir=$(realpath data/${TIMESTAMP}-${numinstances}-latency-monolithic)
    local rusage_logging_file=tmp-service.log

    mkdir -p ${rusage_logging_dir}
    init


    # 512mb, oom
    # 512 + 256 = 768mb, oom
    # 1024mb, ok
    # 1024 + 256 = 1280mb
    # 1024 + 512 = 1536mb
    # 1024 + 1024 = 2048mb
    docker \
        run \
            --name yolo-monolithic-0000 \
            --memory=1024mb \
            --cpus=1.2 \
            --workdir='/root/yolov3-tf2' \
            yolo-monolithic \
            python3.6 detect.py path --image data/street.jpg

    running_time=$(util_get_running_time yolo-monolithic-0000)
    echo $running_time > "${rusage_logging_dir}"/yolo-monolithic-0000.latency

    for i in $(seq 1 $numinstances); do
        local index=$(printf "%04d" $i)
        local container_name=yolo-monolithic-${index}

        docker \
            run \
                -d \
                --name=${container_name} \
                --memory=1gb \
                --cpus=1.2 \
                --workdir='/root/yolov3-tf2' \
                yolo-monolithic \
                python3.6 detect.py path --image data/street.jpg
        sleep 1.5
    done

    for i in $(seq 1 $numinstances); do
        local index=$(printf "%04d" $i)
        local container_name=yolo-monolithic-${index}

        docker wait "${container_name}"
        running_time=$(util_get_running_time "${container_name}")
        echo $running_time > "${rusage_logging_dir}"/"${container_name}".latency
        echo $running_time
    done

    local folder=$(realpath data/${TIMESTAMP}-${numinstances}-graph-monolithic)
    mkdir -p $folder
    for i in $(seq 0 $numinstances); do
        local index=$(printf "%04d" $i)
        local container_name=yolo-monolithic-${index}
        docker logs $container_name 2>&1 | grep "graph_construction_time" > $folder/$container_name.graph
    done

    folder=$(realpath data/${TIMESTAMP}-${numinstances}-inf-monolithic)
    mkdir -p $folder
    for i in $(seq 0 $numinstances); do
        local index=$(printf "%04d" $i)
        local container_name=yolo-monolithic-${index}
        docker logs $container_name 2>&1 | grep "inference_time" > $folder/$container_name.inf
    done

    # For debugging
    docker logs -f yolo-monolithic-$(printf "%04d" $numinstances)
}

[[ $# -ge 1 ]] && NUMINSTANCE=$1
measure_latency_monolithic $NUMINSTANCE