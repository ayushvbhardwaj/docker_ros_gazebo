# docker_ros_gazebo
---A Dockerized development environment for **ROS Noetic**, **ArduPilot**, **MAVROS**, and **IQ_Sim** — ideal for autonomous drone simulation, testing, and research using **SITL** and **Gazebo**.

## 🚀 Features

- ROS Noetic (Ubuntu 20.04)
- ArduPilot SITL (Copter v4.0.4)
- MAVROS and MAVLink
- IQ_Sim Gazebo integration
- Pre-configured Catkin workspace

## 🔧 Quick Start

```bash
git clone https://github.com/your-username/docker_ros_gazebo.git
cd docker_ros_gazebo
docker build -t ros-ardupilot .
docker run -it --privileged --net=host ros-ardupilot
