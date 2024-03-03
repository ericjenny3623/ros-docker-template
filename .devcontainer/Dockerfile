# ROS distribution to use
ARG ROS_DISTRO=noetic

##############################################################################
# PIP installations to reduce cache misses #
##############################################################################
FROM osrf/ros:${ROS_DISTRO}-desktop-full as pip-install

# Install basic apt packages
RUN apt-get update && apt-get install -y --no-install-recommends \
 git libcanberra-gtk-module libcanberra-gtk3-module fuse3 libfuse2 libqt5svg5-dev \
 python3-pip python3-opencv python3-tk python3-pyqt5.qtwebengine 
RUN apt-get install python3-vcstool

# TODO pip installs should be here and in their respective build stages

# Install additional Python modules
RUN pip3 install --upgrade pip
RUN pip3 install matplotlib transforms3d

# FOR TRACKING: ultralytics is yolov8 and torch is for raft_stero
#  (moved to prevent cache miss and slow reinstall)
RUN pip3 install ultralytics torch 

# For RAFT
RUN pip3 install open3d opt_einsum --ignore-installed PyYaml

# For leafblower
RUN pip3 install Phidget22 

##############################################################################
# CUDA #
##############################################################################

FROM pip-install as cuda-install

ARG DEBIAN_FRONTEND=noninteractive

# Prerequisites
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget software-properties-common gnupg2 \
    && rm -rf /var/lib/apt/lists/*

# Enable contrib on debian to get required
# https://packages.debian.org/bullseye/glx-alternative-nvidia
# Enable non-free for nvidia-cuda-dev
# https://packages.debian.org/bullseye/nvidia-cuda-dev

ENV CUDA_DOWNLOAD_OSSTRING=ubuntu
ENV CUDA_DOWNLOAD_VERSTRING=2004
ENV CUDA_DOWLOAD_KEY_ID=3bf863cc

RUN \
  wget https://developer.download.nvidia.com/compute/cuda/repos/${CUDA_DOWNLOAD_OSSTRING}${CUDA_DOWNLOAD_VERSTRING}/x86_64/cuda-${CUDA_DOWNLOAD_OSSTRING}${CUDA_DOWNLOAD_VERSTRING}.pin \
  && mv cuda-${CUDA_DOWNLOAD_OSSTRING}${CUDA_DOWNLOAD_VERSTRING}.pin /etc/apt/preferences.d/cuda-repository-pin-600 && \
  add-apt-repository restricted && \
  apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/${CUDA_DOWNLOAD_OSSTRING}${CUDA_DOWNLOAD_VERSTRING}/x86_64/${CUDA_DOWLOAD_KEY_ID}.pub \
  && add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/${CUDA_DOWNLOAD_OSSTRING}${CUDA_DOWNLOAD_VERSTRING}/x86_64/ /" \
  && apt-get update \
  && apt-get -y install cuda \
  && rm -rf /var/lib/apt/lists/*

# File conflict problem with libnvidia-ml.so.1 and libcuda.so.1
# https://github.com/NVIDIA/nvidia-docker/issues/1551
RUN rm -rf /usr/lib/x86_64-linux-gnu/libnv*
RUN rm -rf /usr/lib/x86_64-linux-gnu/libcuda*

# TODO(tfoote) Add documentation of why these are required
ENV PATH=/usr/local/cuda/bin${PATH:+:${PATH}}
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64/stubs:/usr/local/cuda/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

##############################################################################
# Base Image for Any Project #
##############################################################################

FROM cuda-install as base

ENV ROS_DISTRO=${ROS_DISTRO}
ENV BASE_WS=base_ws
ENV OVERLAY_WS=overlay_ws
ENV BUILD_BASE="source /opt/ros/${ROS_DISTRO}/setup.bash && apt-get update -y && rosdep install --from-paths src --ignore-src --rosdistro ${ROS_DISTRO} -y && catkin_make"
ENV BUILD_OVERLAY="source /${BASE_WS}/devel/setup.bash && rosdep install --from-paths src --ignore-src --rosdistro ${ROS_DISTRO} -y && catkin_make"
SHELL ["/bin/bash", "-c"]

# Create Colcon workspace with external dependencies
RUN mkdir -p /${BASE_WS}/src
WORKDIR /${BASE_WS}/src
COPY packages/ros_pack_deps.repos .
RUN vcs import < ros_pack_deps.repos 

# Build the base Colcon workspace, installing dependencies first.
WORKDIR /${BASE_WS}
RUN eval ${BUILD_BASE}

# Remove display warnings
RUN mkdir /tmp/runtime-root
ENV XDG_RUNTIME_DIR "/tmp/runtime-root"
RUN chmod -R 0700 /tmp/runtime-root
ENV NO_AT_BRIDGE 1

# Set up the entrypoint
WORKDIR /${BASE_WS}
COPY .devcontainer/entrypoint.sh /
RUN chmod +x /entrypoint.sh 
ENTRYPOINT [ "/entrypoint.sh" ]

##############################################################################
# Overlay Images!
##############################################################################
# TODO (4.1) Add a new overlay
FROM base AS overlay-leafblower

# Create an overlay Colcon workspace
RUN mkdir -p /${OVERLAY_WS}/src
WORKDIR /${OVERLAY_WS}
# TODO (4.2) copy the source code from your repo into the overlay
COPY packages/apple_harvesting_leafblower/  src/apple_harvesting_leafblower/

## TODO (4.5) add any dependencies to the overlay you CANNOT get from rosdeps or vcstool
## Need to install phidget22 because its not in the main rosdep list
RUN apt-get update && apt-get install -y wget
RUN wget -qO- http://www.phidgets.com/gpgkey/pubring.gpg | apt-key add - && \
    echo 'deb http://www.phidgets.com/debian focal main' > /etc/apt/sources.list.d/phidgets.list && \
    apt-get update && apt-get install -y libphidget22

# ## TODO (4.6) run the ros setup script, install dependencies, and build the package. 
# RUN ${BUILD_OVERLAY}

##############################################################################
#  TRACKING
##############################################################################

FROM overlay-leafblower as overlay-tracking

RUN mkdir -p /${OVERLAY_WS}/src
WORKDIR /${OVERLAY_WS}/src

COPY /packages/yolo_v8_seg ./yolo_v8_seg

COPY /packages/raft_stereo_wrapper ./raft_stereo_wrapper
RUN pip3 install ./raft_stereo_wrapper/src/raft_stereo_core/sampler -t /${OVERLAY_WS}/devel/lib/python3/dist-packages

COPY /packages/tracking_pipeline ./tracking_pipeline

WORKDIR /${OVERLAY_WS}
# RUN ${BUILD_OVERLAY}

##############################################################################
#  Spinnaker camera
##############################################################################
FROM overlay-tracking as overlay-camera

# Install Spinnaker SDK
RUN mkdir -p /setup/spinnaker_lib
WORKDIR /setup
# The spinnaker library for container (ubuntu 20.04) must be in .devcontainer
#  Copy and extract
COPY .devcontainer/spinnaker-3.2.0.57-amd64-pkg-20.04.tar.gz .
RUN tar -xvf spinnaker-* --strip=1 -C spinnaker_lib
RUN apt-get update && apt-get install -y libusb-1.0-0 libavcodec58 libavformat58 libswscale5 \
    libswresample3 libavutil56 libusb-1.0-0 qt5-default
# Run custom install script with no prompts
WORKDIR /setup/spinnaker_lib
COPY packages/firefly_camera_driver/install_lib_spinnaker.sh .
RUN chmod +x install_lib_spinnaker.sh
RUN ./install_lib_spinnaker.sh --auto

# RUN mkdir -p /${BASE_WS}/src # You might need to make dir if it hasnt already been by another layer   
WORKDIR /${BASE_WS}/src
COPY packages/firefly_camera_driver/dependencies.repos .firefly_camera_driver_deps.repos
RUN vcs import < .firefly_camera_driver_deps.repos
WORKDIR /${BASE_WS}
RUN eval ${BUILD_BASE}

# Add flirimaging so we can access the camera without privileged
RUN groupadd -g 1002 flirimaging && newgrp flirimaging # TODO this needs to match host group id

# Copy our source and build
WORKDIR /${OVERLAY_WS}
COPY packages/firefly_camera_driver/ src/firefly_camera_driver
RUN eval ${BUILD_OVERLAY}

##############################################################################
# Development Image #
##############################################################################\
## TODO (4.8) update the dev image to use your overlay
FROM overlay-camera as dev

# Dev container arguments
ARG USERNAME=devuser
ARG UID=1000
ARG GID=${UID}

# Install extra tools for development
RUN apt-get update && apt-get install -y --no-install-recommends \
 gdb gdbserver nano screen

# Create new user and home directory
RUN groupadd --gid $GID $USERNAME \
 && useradd --uid ${UID} --gid ${GID} --create-home ${USERNAME} \
 && echo ${USERNAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USERNAME} \
 && chmod 0440 /etc/sudoers.d/${USERNAME} \
 && mkdir -p /home/${USERNAME} \
 && chown -R ${UID}:${GID} /home/${USERNAME}

# Set the ownership of the overlay workspace to the new user
RUN chown -R ${UID}:${GID} /${OVERLAY_WS}/

# Install USB tools (lsusb) as a nice have for physical device debugging
RUN apt-get update && apt-get install -y usbutils udev

# Set the user and source entrypoint in the user's .bashrc file
USER ${USERNAME}
RUN echo "source /entrypoint.sh" >> /home/${USERNAME}/.bashrc