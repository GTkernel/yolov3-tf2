FROM tensorflow/tensorflow:2.1.0-py3

ARG DOCKERVERSION=19.03.12
RUN apt-get update -y --fix-missing && \
    apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common && \
    apt install -y git wget time && \
    apt-get install -y libgl1-mesa-dev && \
    apt install -y libsm6 libxrender1 libfontconfig1  && \
    pip3 install opencv-python==4.1.0.25 && \
    python3 -m pip install opencv-contrib-python && \
    python3 -m pip install --upgrade pip && \
    python3 -m pip install absl-py && \
    git clone https://github.com/whalepark/yolov3-tf2.git /root/yolov3-tf2 && \
    wget https://pjreddie.com/media/files/yolov3.weights -P /root/yolov3-tf2/data && \
    cd /root/yolov3-tf2/ && \
    python3.6 convert.py