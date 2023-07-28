
# sudo docker build . -t sydneyinformaticshub/cryoem
# xhost +
# sudo docker run --gpus all --device /dev/dri/ -it --rm  -e DISPLAY=unix$DISPLAY  -v `pwd`:`pwd` -v /tmp/.X11-unix:/tmp/.X11-unix  -e QT_X11_NO_MITSHM=1  sydneyinformaticshub/cryoem


FROM nvidia/cudagl:10.2-devel-ubuntu16.04
MAINTAINER Nathaniel Butterworth USYD SIH

# Install base dependencies for everything
RUN apt-get update
RUN apt-get install -y g++	gfortran	git	wget	autoconf	libtool	libnuma-dev	libelf1	flex	tar	pkg-config	initramfs-tools	unzip	python3	build-essential	mpi-default-bin	mpi-default-dev	libfftw3-dev	libtiff-dev	libpng-dev	ghostscript	libxft-dev	make	libopenmpi-dev	libhdf5-dev	python3-numpy	python3-dev	libtiff5-dev	libsqlite3-dev	default-jdk curl libopencv-dev libgl-dev libglu1-mesa mesa-utils libgl1-mesa-dri libxkbcommon-x11-0 libxkbcommon-x11-dev libgl1 libglib2.0-0 libsm6 libxrender1 libxext6 software-properties-common

# Set the working directory
WORKDIR /opt
RUN mkdir /opt/bin/
ENV PATH="/opt/bin:${PATH}"
ARG PATH="/opt/bin:${PATH}"

RUN wget https://github.com/Kitware/CMake/releases/download/v3.27.0/cmake-3.27.0-linux-x86_64.sh && \
  bash cmake-3.27.0-linux-x86_64.sh --skip-license && \
  ln -s /opt/cmake-3.27.0-linux-x86_64/bin/c* -t /opt/bin/

## Relion
# https://relion.readthedocs.io/en/release-4.0/Installation.html
RUN add-apt-repository ppa:ubuntu-toolchain-r/test && apt-get update -y
RUN apt-get install gcc-7 g++-7 gfortran-7  -y && \
  update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 60 && \
  update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-7 60 && \
  update-alternatives --install /usr/bin/gfortran gfortran /usr/bin/gfortran-7 60

RUN git clone https://github.com/3dem/relion.git && \
  cd relion && \
  git checkout ver4.0 && \
  git pull && \
  mkdir build

RUN cd /opt/relion/build && \
  cmake .. && \
  make -j 12

ENV PATH="/opt/relion/build/bin:${PATH}"

## Gautomatch
#https://www2.mrc-lmb.cam.ac.uk/download/gautomatch-053/pped file in
# Download takes a long time, just add the unzi
#RUN curl -o gautomatch.tar.gz "https://www2.mrc-lmb.cam.ac.uk/download/gautomatch-053/?wpdmdl=17941&refresh=64b74f60d46761689735008&ind=1588087070026&filename=Gautomatch_v0.53_and_examples.tar.gz"
#RUN ls && tar -xzvf gautomatch.tar.gz
ADD Gautomatch_v0.53 /opt/Gautomatch_v0.53
RUN ln -s /usr/local/cuda/lib64/libcufft.so /usr/lib/libcufft.so.8.0
RUN ln -s /opt/Gautomatch_v0.53/bin/Gautomatch-v0.53_sm_20_cu8.0_x86_64 /opt/bin/Gautomatch
ENV PATH="/opt/Gautomatch_v0.53/bin:${PATH}"

## Chimera
#https://www.cgl.ucsf.edu/chimera/download.html
RUN curl -o /opt/bin/chimera.bin https://www.cgl.ucsf.edu/chimera/cgi-bin/secure/chimera-get.py?file=linux_x86_64/chimera-1.17.3-linux_x86_64.bin

## MotionCor2
# https://emcore.ucsf.edu/ucsf-software
#License must be accepted. Then zip/binaries are downloaded from
ADD MotionCor2_1.6.4_Cuda102_Mar312023 /opt/bin/
RUN ln -s /opt/bin/MotionCor2_1.6.4_Cuda102_Mar312023 /opt/bin/MotionCor2

## Python
ENV PATH="/opt/miniconda3/bin:${PATH}"
ARG PATH="/opt/miniconda3/bin:${PATH}"
RUN curl -o miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-py311_23.5.2-0-Linux-x86_64.sh &&\
	mkdir /opt/.conda && \
	bash miniconda.sh -b -p /opt/miniconda3 &&\
	rm -rf miniconda.sh

RUN conda init bash
RUN /bin/bash -c "source /root/.bashrc"

## EPU_group_AFIS
#https://github.com/DustinMorado/EPU_group_AFIS
RUN conda create -n EPU_group_AFIS -c conda-forge -c anaconda numpy scikit-learn matplotlib
RUN git clone https://github.com/DustinMorado/EPU_group_AFIS.git
RUN ln -s /opt/EPU_group_AFIS/EPU_Group_AFIS.py /opt/bin/EPU_Group_AFIS.py

## cryolo
#https://cryolo.readthedocs.io/en/stable/troubleshooting.html#cryolo-glibc-label
RUN conda create -n cryolo -c conda-forge -c anaconda pyqt=5 python=3.7 cudatoolkit=10.2.89 cudnn=7.6.5 numpy=1.18.5 libtiff wxPython=4.1.1  adwaita-icon-theme
RUN conda run -n cryolo  pip install 'cryolo[gpu]'

## pyem
#https://github.com/asarnow/pyem/wiki/Install-pyem-with-Miniconda
RUN conda create -n pyem -c anaconda -c conda-forge numpy scipy matplotlib seaborn numba pandas natsort pyfftw healpy pathos
RUN  git clone https://github.com/asarnow/pyem.git && \
  cd pyem && \
  conda run -n pyem pip install --no-dependencies -e .
RUN ln -s /opt/pyem/*.py -t /opt/bin/

## topaz
# https://github.com/tbepler/topaz
RUN conda create -n topaz topaz -c tbepler -c pytorch

#https://blake.bcm.edu/emanwiki/EMAN2/Install/SourceInstall
#RUN conda create -n eman2 eman-dev -c cryoem -c conda-forge
RUN conda create -n eman2 eman-dev==2.99.47 -c cryoem -c conda-forge

## Scipion & xmipp
# https://github.com/I2PC/xmipp#xmipp
# https://scipion-em.github.io/docs/release-3.0.0/docs/scipion-modes/how-to-install.html
RUN apt-get install gcc-9 g++-9 gfortran-9  -y
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 70
RUN update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-9 70
RUN	update-alternatives --install /usr/bin/gfortran gfortran /usr/bin/gfortran-9 70

RUN pip install scipion-installer
RUN python -m scipioninstaller -conda -noXmipp -noAsk /opt/scipion
RUN /opt/scipion/scipion3 config
#RUN git clone https://github.com/I2PC/xmipp.git
RUN echo $'CUDA = True \n\
CUDA_BIN = /usr/local/cuda-10.2/bin \n\
CUDA_LIB = /usr/local/cuda-10.2/lib64 \n\
MPI_BINDIR = /usr/bin \n\
MPI_LIBDIR = /usr/lib/openmpi/lib/ \n\
MPI_INCLUDE = /usr/lib/openmpi/include/ \n\
OPENCV = False' >> /opt/scipion/config/scipion.conf
RUN /opt/scipion/scipion3 installp -p scipion-em-xmipp -j 12 | tee -a install.log
RUN ln -s /opt/scipion/scipion3 /opt/bin/scipion3

RUN mkdir /scratch /project 
