# ROS distribution to use
ARG ROS_DISTRO=noetic

##############################################################################
# Base Image for Any Project #
##############################################################################
FROM osrf/ros:${ROS_DISTRO}-desktop-full as base
ENV ROS_DISTRO=${ROS_DISTRO}
SHELL ["/bin/bash", "-c"]

# Install basic apt packages
RUN apt-get update && apt-get install -y --no-install-recommends \
 git libcanberra-gtk-module libcanberra-gtk3-module fuse3 libfuse2 libqt5svg5-dev \
 python3-pip python3-opencv python3-tk python3-pyqt5.qtwebengine 
RUN apt-get install python3-vcstool

# Install additional Python modules
RUN pip3 install matplotlib transforms3d

# Create Colcon workspace with external dependencies
RUN mkdir -p /klab_ws/src
WORKDIR /klab_ws/src
# TODO we might want to move this into overlay
COPY src/dependencies.repos .
RUN vcs import < dependencies.repos 

# Build the base Colcon workspace, installing dependencies first.
WORKDIR /klab_ws
RUN source /opt/ros/${ROS_DISTRO}/setup.bash \
 && apt-get update -y \
 && rosdep install --from-paths src --ignore-src --rosdistro ${ROS_DISTRO} -y \
 && catkin_make
## TODO add any environment variables

# Remove display warnings
RUN mkdir /tmp/runtime-root
ENV XDG_RUNTIME_DIR "/tmp/runtime-root"
RUN chmod -R 0700 /tmp/runtime-root
ENV NO_AT_BRIDGE 1

# Set up the entrypoint
WORKDIR /klab_ws
COPY .devcontainer/entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]

##############################################################################
# Overlay Images!
##############################################################################
# TODO (4.1) Add a new overlay
FROM base AS overlay-leafblower

# Create an overlay Colcon workspace
RUN mkdir -p /overlay_ws/src
WORKDIR /overlay_ws
# TODO (4.2) copy the source code from your repo into the overlay
COPY src/apple_harvesting_leafblower/ ./src/apple_harvesting_leafblower/

## TODO (4.5) add any dependencies to the overlay you CANNOT get from rosdeps or vcstool
## Need to install phidget22 because its not in the main rosdep list
RUN apt-get update && apt-get install -y wget
RUN wget -qO- http://www.phidgets.com/gpgkey/pubring.gpg | apt-key add - && \
    echo 'deb http://www.phidgets.com/debian focal main' > /etc/apt/sources.list.d/phidgets.list && \
    apt-get update && apt-get install -y libphidget22
RUN pip3 install Phidget22

## TODO (4.6) run the ros setup script, install dependencies, and build the package. 
RUN source /klab_ws/devel/setup.bash \
 && rosdep install --from-paths src --ignore-src --rosdistro ${ROS_DISTRO} -y \
 && catkin_make

##############################################################################
# Development Image #
##############################################################################\
## TODO (4.8) update the dev image to use your overlay
FROM overlay-leafblower as dev

# Dev container arguments
ARG USERNAME=devuser
ARG UID=1000
ARG GID=${UID}

# Install extra tools for development
RUN apt-get update && apt-get install -y --no-install-recommends \
 gdb gdbserver nano

# Create new user and home directory
RUN groupadd --gid $GID $USERNAME \
 && useradd --uid ${GID} --gid ${UID} --create-home ${USERNAME} \
 && echo ${USERNAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USERNAME} \
 && chmod 0440 /etc/sudoers.d/${USERNAME} \
 && mkdir -p /home/${USERNAME} \
 && chown -R ${UID}:${GID} /home/${USERNAME}

# Set the ownership of the overlay workspace to the new user
RUN chown -R ${UID}:${GID} /overlay_ws/

# Install USB tools (lsusb) as a nice have for physical device debugging
RUN apt-get update && apt-get install -y usbutils udev

# Set the user and source entrypoint in the user's .bashrc file
USER ${USERNAME}
RUN echo "source /entrypoint.sh" >> /home/${USERNAME}/.bashrc