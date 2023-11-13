# Kantorlab Docker/Devcontainer Template
The goal of this project is to provide a standard template for setting up your development environment for use with ROS.
There are many advantages of using Docker with ROS ([see talk here](https://discourse.ros.org/t/ros-docker-pro-tips-and-20-20-hindsights/17274 "ROS + Docker: Pro Tips and 20/20 Hindsights")). The key benefits for our lab our:
* Faster onboarding: See below.
* Ability to share machines without worrying about interference: Sally can run her container on the lab computer and then Bob who needs the computer later can shutdown Sally's container and run his.
* Cross platform development: Yes, there are gotcha's with actually using Docker cross platform, especially with using physical devices. But - for the most part - we write *software* and that software will run fine in a Docker container on any platform.
* Research replicability: I definitely should not be talking about this, but it was mentioned in the talk linked above.

One of the main reasons I see to using Docker is that it helps anyone who has to run your code in the future. By setting up your Dockerfile to get your project to work from the start, you have: 1) documented your setup process implicitly and 2) already done the setup work for anyone in the future trying to run your project. With access to your Dockerfile, they can simply build the image and everything is set up the way it is for you. 

## Understanding the Environment:
The environment is structed to use multi-stage docker builds as explained by [1]. We start with a base image which is running Ubuntu 20.04 with ROS noetic (and related desktop tools installed). This provides the *base* for all work to be run. For each project, we then create an *overlay* image. This overlay should contain all of the specifics for our project. Since we are building on the base ROS image, the overlay only needs to worry about containing our source code and installing any project specific prerequisites. Finally, for development, we create a "hat" on top of our overlay which includes convenience tools and supports a *devcontainer* that allows integration with an IDE. 

### Devcontainers, the dev image, and the dev service
Devcontainer's provide a convenient and well supported way of working on our project. 

### Docker user settings
One trick of this docker image is to match the user ID to the local user (mostly). This gives the Docker image the same permissions as the local user who is running the Docker image, and therefore gets rid of annoying permission issues that would exist if otherwise (editing source code)

## How To Use:
You can follow along these steps inside this template repo by searching for *TODO (4.1)* (for example).
1. Install Docker on your system: https://docs.docker.com/get-docker/. Make sure to add your user to the Docker group with *sudo groupadd docker ; sudo usermod -aG docker $USER ; newgrp docker*
2. Clone this template as a starting point.
3. Create/Clone the various projects you will be working on into the src directory in this template
<!-- TODO use submodules? -->
4. Add overlay(s) for your project. **There is an example of this in the Dockerfile.** Steps 1, 2, & 5-7 are all done in *.devcontainer/Dockerfile*. 
    > Generally, it is advised to make a seperate overlay for anything that could be shared between projects. If everything you are developing is project unique, just make one overlay.
    1. Create a new overlay in the Dockerfile using FROM base as overlay-*name*
    2. Copy the source code from ./src/*project-name* to overlay_ws/src/*project-name*
    3. Add any repository based dependencies into *src/dependencies.repos*. This is a little more complicated. See https://github.com/dirk-thomas/vcstool and https://wiki.ros.org/vcstool. A turtlebot example is here: https://medium.com/@thehummingbird/ros-2-mobile-robotics-series-part-1-8b9d1b74216.
    4. Install package based dependencies using rosdeps in the project source itself: TODO
    5. (Optional) Install any dependencies that need to be installed through the Dockerfile. This is not preferred.
    6. Source setup.sh in the project and build the project
    7. Now, update dev to build off of your overlay by editing the dev definition to be: FROM overlay-*name* as dev. (If you want to switch projects, change this line).
    8. Then update *docker-compose.yaml* to mount ./src/*project-name* to overlay_ws/src/*project-name*. The copy in step 2 is not persistent. The mount means that changes you make in the dev container will be reflected on your machine as well.
 5. Launch the docker image. I'd recommend:
    1. First, try building the docker compose using *docker compose build* (then *docker compose run dev* if it builds succesfully). It is slightly easier to debug your Docker file/compose since it is easier to see the error message vs. when running the build through the devcontainer extension. 
    2. Once you have debugged the docker build, then feel free to run using Ctrl+Shift+P (opens the VScode command palette)->Devcontainers: rebuild and relaunch in container (you might need to install the devcontainer extension in VScode). The devcontainer is set to launch the (compose) service *dev*. If you want to run a different service, change this in the *.devcontainer/devcontainer.json* spec file. 
    3. Now you should be in a VScode window "inside" of the Docker container where you can create terminals (run *bash* first) and run ros like normal.  

### Adding requirements
For installing requirements, it is preferred to use rosdeps, vcstool, or finally (if not avaible through the first 2 sources) by editing the overlay Dockerfile/image. 

#### Rosdeps
TODO. For now, see  https://github.com/Kantor-Lab/apple_harvest/tree/ros1-actions for an example.

#### vcstool
TODO

### Communicating to serial devices
The current solution (on linux) for Docker to access serial devices is to ensure that the devices have proper udev rules set up so that the true user can access them without root, and then run the docker image with that user's ID. The provided template mounts the /dev directory so that the Docker image can access devices that the local user could.

#### Arduino
For arduino, this means adding the Docker image to the dialout group using the compose argument. This is already done in the compose file.

#### Phidgets
This is handled through udev rules (see various links in resources). **You need to run setup_udev_phidgets.sh with root on the host machine**.

### Other

## Resources
1. https://roboticseabass.com/2023/07/09/updated-guide-docker-and-ros2/
2. https://docs.ros.org/en/rolling/How-To-Guides/Setup-ROS-2-with-VSCode-and-Docker-Container.html
3. https://docs.docker.com/build/building/multi-stage/
4. https://www.losant.com/blog/how-to-access-serial-devices-in-docker
5. https://gist.github.com/vfdev-5/b7685371071036cb739f23b3794b5b83
6. https://containers.dev/implementors/spec/
7. https://containers.dev/implementors/json_reference/
8. https://medium.com/@mccode/understanding-how-uid-and-gid-work-in-docker-containers-c37a01d01cf   
9. https://docs.docker.com/compose/compose-file/compose-file-v2/
10. https://medium.com/@mccode/understanding-how-uid-and-gid-work-in-docker-containers-c37a01d01cf