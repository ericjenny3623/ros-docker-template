#!/bin/bash
# Basic entrypoint for ROS / Colcon Docker containers

# Source ROS 2
echo "Running entrypoint script"
source /opt/ros/${ROS_DISTRO}/setup.bash
echo "Sourced ROS ${ROS_DISTRO}"

# Source the base workspace, if built
if [ -f /${BASE_WS}/devel/setup.bash ]
then
  source /${BASE_WS}/devel/setup.bash
  # export GAZEBO_MODEL_PATH=$GAZEBO_MODEL_PATH:$(ros2 pkg prefix turtlebot3_gazebo)/share/turtlebot3_gazebo/models
  echo "Sourced base workspace"
fi

# Source the overlay workspace, if built
if [ -f /${OVERLAY_WS}/devel/setup.bash ]
then
  source /${OVERLAY_WS}/devel/setup.bash
  # export GAZEBO_MODEL_PATH=$GAZEBO_MODEL_PATH:$(ros2 pkg prefix tb3_worlds)/share/tb3_worlds/models
  echo "Sourced overlay workspace"
fi

# Execute the command passed into this entrypoint
exec "$@"