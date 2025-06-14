# Base image: plain Ubuntu
FROM ubuntu:20.04

# Set environment variables to avoid user interaction during install
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# Set up locale
RUN apt-get update && apt-get install -y locales \
    && locale-gen en_US en_US.UTF-8 \
    && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
    && apt-get clean

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Install basic tools and dependencies
RUN apt-get update && apt-get install -y \
    curl \
    gnupg2 \
    lsb-release \
    build-essential \
    cmake \
    git \
    wget \
    sudo \
    && apt-get clean

# Add ROS repository
RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'

# Add ROS keys
RUN curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add -

# Install ROS Noetic
RUN apt-get update && apt-get install -y \
    ros-noetic-desktop-full \
    python3-rosdep \
    python3-rosinstall \
    python3-rosinstall-generator \
    python3-wstool \
    python3-pip \
    python3-catkin-tools \
    && apt-get clean

# Initialize rosdep
RUN rosdep init && rosdep update

# Source ROS setup file on shell startup
RUN echo "source /opt/ros/noetic/setup.bash" >> /root/.bashrc

# Set up Git to avoid using git://
RUN git config --global url.https://.insteadOf git://

# Install ArduPilot and prerequisites
RUN git clone https://github.com/ArduPilot/ardupilot.git /root/ardupilot && \
    cd /root/ardupilot && \
    git checkout Copter-4.0.4 && \
    git submodule update --init --recursive

# Run prerequisites in a separate layer
RUN cd /root/ardupilot && \
    sed -i 's/sudo usermod -a -G dialout/sudo usermod -a -G dialout root/' Tools/environment_install/install-prereqs-ubuntu.sh && \
    sed -i 's/pip2/pip3/' Tools/environment_install/install-prereqs-ubuntu.sh && \
    sed -i 's/python-pip/python3-pip/' Tools/environment_install/install-prereqs-ubuntu.sh && \
    sed -i 's/python-matplotlib/python3-matplotlib/' Tools/environment_install/install-prereqs-ubuntu.sh && \
    sed -i 's/python-serial/python3-serial/' Tools/environment_install/install-prereqs-ubuntu.sh && \
    sed -i 's/python-scipy/python3-scipy/' Tools/environment_install/install-prereqs-ubuntu.sh && \
    sed -i 's/python-opencv/python3-opencv/' Tools/environment_install/install-prereqs-ubuntu.sh && \
    sed -i 's/python-empy/python3-empy/' Tools/environment_install/install-prereqs-ubuntu.sh && \
    sed -i 's/python-numpy/python3-numpy/' Tools/environment_install/install-prereqs-ubuntu.sh && \
    sed -i 's/python-pyparsing/python3-pyparsing/' Tools/environment_install/install-prereqs-ubuntu.sh && \
    sed -i 's/python-dev/python3-dev/' Tools/environment_install/install-prereqs-ubuntu.sh && \
    sed -i 's/python-setuptools/python3-setuptools/' Tools/environment_install/install-prereqs-ubuntu.sh && \
    Tools/environment_install/install-prereqs-ubuntu.sh -y

RUN cd /root/ardupilot && \
    usermod -a -G dialout root && \
    apt-get clean


RUN sudo apt-get install -y python3-wstool python3-rosinstall-generator python3-catkin-lint python3-pip python3-catkin-tools

RUN mkdir -p ~/catkin_ws/src &&\
    cd ~/catkin_ws &&\
    catkin init

RUN cd ~/catkin_ws &&\
    wstool init ~/catkin_ws/src
RUN apt update && apt install -y python3-catkin-tools

# Generate rosinstall
RUN rosinstall_generator --upstream mavros | tee /tmp/mavros.rosinstall && \
    rosinstall_generator mavlink | tee -a /tmp/mavros.rosinstall

# Fetch the packages
RUN cd ~/catkin_ws && \
    wstool merge -t src /tmp/mavros.rosinstall && \
    wstool update -t src

# Clone catkin if not extending


# Install additional dependencies required by iq_sim
RUN apt-get update && apt-get install -y \
    ros-noetic-roscpp \
    ros-noetic-std-msgs \
    ros-noetic-geometry-msgs \
    ros-noetic-sensor-msgs \
    ros-noetic-nav-msgs \
    ros-noetic-tf \
    ros-noetic-tf2 \
    ros-noetic-tf2-ros \
    ros-noetic-message-generation \
    ros-noetic-message-runtime \
    && apt-get clean

RUN apt update  && \
    apt install -y ros-noetic-mavros ros-noetic-mavros-extras

RUN cd ~/catkin_ws/src && \
    git clone https://github.com/Intelligent-Quads/iq_sim.git

RUN echo "export GAZEBO_MODEL_PATH=\$GAZEBO_MODEL_PATH:/root/catkin_ws/src/iq_sim/models" >> ~/.bashrc
# Clean and build the workspace
# Configure workspace to extend ROS Noetic
RUN cd /root/catkin_ws && catkin config --extend /opt/ros/noetic

# Ensure proper dependencies are installed
RUN cd /root/catkin_ws && rosdep install --from-paths src --ignore-src -r -y

# Build the workspace
RUN cd /root/catkin_ws && catkin build

RUN echo "source /root/catkin_ws/devel/setup.bash" >> ~/.bashrc

# Add sim_vehicle to source
ENV PATH="/root/ardupilot/Tools/autotest:$PATH"

ENV PATH="/root/.local/bin:$PATH"

RUN ln -s /usr/bin/python3 /usr/bin/python


# Install GeographicLib Datasets
RUN wget https://raw.githubusercontent.com/mavlink/mavros/master/mavros/scripts/install_geographiclib_datasets.sh && \
    chmod +x install_geographiclib_datasets.sh && \
    ./install_geographiclib_datasets.sh && \
    rm install_geographiclib_datasets.sh

# Default shell
SHELL ["/bin/bash", "-c"]

# Set workspace environment at container startup
CMD ["/bin/bash"]   

