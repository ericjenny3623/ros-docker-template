#!/bin/bash
# Additional setup after mounts

# WORKPATH=/${OVERLAY_WS}/src
# CUR_PATH=$(pwd)
# cd $WORKPATH
# echo "Cloning private repositories"
# vcs import < private.repos 
# cd ..
# echo "Rebuilding overlay ROS workspace"
# source /opt/ros/${ROS_DISTRO}/setup.bash \
#  && apt-get update -y \
#  && rosdep install --from-paths src --ignore-src --rosdistro ${ROS_DISTRO} -y \
#  && catkin_make
# cd $CUR_PATH

# # Source the base workspace, if built
# if [ -f /${BASE_WS}/devel/setup.bash ]
# then
#   source /${BASE_WS}/devel/setup.bash
#   # export GAZEBO_MODEL_PATH=$GAZEBO_MODEL_PATH:$(ros2 pkg prefix turtlebot3_gazebo)/share/turtlebot3_gazebo/models
#   echo "Sourced Kantor Lab base workspace"
# fi

./bash_setup.sh

# Execute the command passed into this entrypoint
exec "$@"
