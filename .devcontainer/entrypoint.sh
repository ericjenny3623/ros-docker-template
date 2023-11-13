#!/bin/bash
# Basic entrypoint for ROS / Colcon Docker containers

# Source ROS 2
echo "Running entrypoint script"
source /opt/ros/${ROS_DISTRO}/setup.bash
echo "Sourced ROS ${ROS_DISTRO}"

# Source the base workspace, if built
if [ -f /klab_ws/devel/setup.bash ]
then
  source /klab_ws/devel/setup.bash
  # export GAZEBO_MODEL_PATH=$GAZEBO_MODEL_PATH:$(ros2 pkg prefix turtlebot3_gazebo)/share/turtlebot3_gazebo/models
  echo "Sourced Kantor Lab base workspace"
fi

# Source the overlay workspace, if built
if [ -f /overlay_ws/devel/setup.bash ]
then
  source /overlay_ws/devel/setup.bash
  # export GAZEBO_MODEL_PATH=$GAZEBO_MODEL_PATH:$(ros2 pkg prefix tb3_worlds)/share/tb3_worlds/models
  echo "Sourced autonomy overlay workspace"
fi

# Execute the command passed into this entrypoint
exec "$@"