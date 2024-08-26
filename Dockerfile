FROM nvidia/cuda:11.6.1-devel-ubuntu20.04

ENV HOME /root
ENV TZ=America/Denver
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
ENV DEBIAN_FRONTEND=noninteractive

# Install basic utilities and dependencies
RUN apt-get update && apt-get install -y \
    nano vim git ssh wget \
    cmake ninja-build build-essential \
    libboost-program-options-dev \
    libboost-filesystem-dev \
    libboost-graph-dev \
    libboost-system-dev \
    libeigen3-dev \
    libflann-dev \
    libfreeimage-dev \
    libmetis-dev \
    libgoogle-glog-dev \
    libgtest-dev \
    libsqlite3-dev \
    libglew-dev \
    qtbase5-dev \
    libqt5opengl5-dev \
    libcgal-dev \
    libceres-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    freeglut3-dev

# Install miniconda3
WORKDIR $HOME
ENV MINICONDA3 $HOME/miniconda3
RUN mkdir -p $MINICONDA3 \
    && echo "I'm building for TARGETPLATFORM=${TARGETPLATFORM}" \
    && case ${TARGETPLATFORM} in \
        "linux/arm64") MINI_ARCH=aarch64 ;; \
        *) MINI_ARCH=x86_64 ;; \
    esac \
    && wget https://repo.anaconda.com/miniconda/Miniconda3-py39_23.11.0-2-Linux-${MINI_ARCH}.sh -O $MINICONDA3/miniconda.sh \
    && chmod +x $MINICONDA3/miniconda.sh \
    && bash $MINICONDA3/miniconda.sh -b -u -p $MINICONDA3 \
    && rm -rf $MINICONDA3/miniconda.sh

ENV PATH="/root/miniconda3/bin:${PATH}"
RUN conda init bash

# Clone and set up LOD-3DGS
RUN git clone https://github.com/zhaofuq/LOD-3DGS.git --recursive
WORKDIR $HOME/LOD-3DGS
ENV USE_CUDA=1
ENV FORCE_CUDA 1
ENV TORCH_CUDA_ARCH_LIST "8.6"
RUN conda env update -f environment.yml --prune
RUN conda install cmake -y

# Install additional conda packages for OpenGL support
RUN conda install -c conda-forge glew mesa-libgl-devel-cos7-x86_64 freeglut -y

# Build COLMAP
WORKDIR $HOME
RUN git clone https://github.com/colmap/colmap.git
RUN cd colmap && mkdir build && cd build \
    && cmake .. -GNinja -DCMAKE_CUDA_ARCHITECTURES=86 \
    && ninja -j4 && ninja install

# Set up environment variables for OpenGL
ENV LD_LIBRARY_PATH="/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH}"

WORKDIR $HOME/LOD-3DGS

# How to use:
# docker build . -t lod-3dgs
# docker run --rm -it --gpus all lod-3dgs bash
# conda activate lod-3dgs
# nvidia-smi
# python -c "import torch; print(torch.cuda.is_available())"