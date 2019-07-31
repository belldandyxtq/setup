#!/bin/bash

PYHON3VER="3.7.4"
OPENMPIVER="3.1.4"
MAKE_BASIC="false"
PYENV="false"
INTERACTIVE="false"
LIBJPEG="false"
OPENCV="false"
OPENMPI="false"
VIM="false"
SETUP="false"

function promote()
{
    promote_str="$1"
    non_interactive_value=$2

    if [ "$INTERACTIVE" == "false" ]
    then
        echo $non_interactive_value
        return
    fi

    while true; do
        read -p "${promote_str}" yn
        case $yn in
            [Yy]* ) ret="true"; break;;
            [Nn]* ) ret="false"; break;;
            * ) echo "Please answer Yy or Nn.";;
        esac
    done
    echo $ret
}

function make_basic_directory()
{

    # make basic directory
    retval=$(promote "Make basic directories? [y/n]" ${MAKE_BASIC})
    if [ "$retval" == "false" ]
    then
        echo "not making basic directories"
        return
    else
        echo "making basic directories ..."
    fi

    cd $HOME
    mkdir -p repository
    mkdir -p software
    echo 'export REPOSITORY_HOME=$HOME/repository' >> $HOME/.bash_exports
    echo 'export SOFTWARE_HOME=$HOME/software' >> $HOME/.bash_exports

    source $HOME/.bash_exports

    echo "Done"
}

function setup_config()
{
    # get all the configures
    retval=$(promote "Setup configures? [y/n]" ${SETUP})
    if [ "$retval" == "false" ]
    then
        echo "not setting up configures"
        return
    else
        echo "setting up configures ..."
    fi

    pushd .
    cd $HOME/repository

    ## vimrc
    echo "setting vimrc ..."
    git clone https://github.com/belldandyxtq/vimconf.git
    rm -f $HOME/.vimrc
    ln -s $HOME/repository/vimconf/.vimrc $HOME/

    ### install vim plugins
    echo "setting vim plugins ..."
    curl -fLo $HOME/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    vim +PlugInstall +qall

    ## bashrc && bash_alias
    echo "setting bashrc and bash_alias ..."
    git clone https://github.com/belldandyxtq/bashconf.git
    rm -f $HOME/.bashrc $HOME/.bash_aliases
    ln -s $HOME/repository/bashconf/.bash_* $HOME/

    ## screenrc 
    echo "setting screenrc ..."
    git clone https://github.com/belldandyxtq/screenconf.git
    rm -f $HOME/.screenrc
    ln -s $HOME/repository/screenconf/.screenrc $HOME/

    source $HOME/.bashrc

    popd

    echo "Done"
}

# install basic softwares


function install_pyenv()
{
    retval=$(promote "Install pyenv? [y/n] " ${PYENV})
    if [ "$retval" == "false" ]
    then
        echo "not installing pyenv"
        return
    else
        echo "installing pyenv"
    fi

    ## pyenv
    echo "setting up pyenv ..."
    git clone https://github.com/pyenv/pyenv.git $HOME/.pyenv
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> $HOME/.bash_exports
    echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> $HOME/.bash_exports
    echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init -)"\nfi' >> $HOME/.bash_exports

    source $HOME/.bash_exports

    echo "installing python $PYHON3VER ..."
    sudo apt-get install -y make build-essential libssl-dev zlib1g-dev libbz2-dev \
        libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev \
        xz-utils tk-dev libffi-dev liblzma-dev python-openssl git

    env PYTHON_CONFIGURE_OPTS="--enable-shared" pyenv install $PYHON3VER
    pyenv global $PYHON3VER

    echo "Done"
}


## opencv

function install_libjpeg()
{
    retval=$(promote "Install libjpeg turbo? [y/n] " ${LIBJPEG})
    if [ "$retval" == "false" ]
    then
        echo "not installing libjpeg"
        return
    else
        echo "installing libjpeg ..."
    fi

    ### libjpeg-turbo
    sudo apt install -y cmake nasm

    pushd .
    cd $REPOSITORY_HOME

    git clone https://github.com/libjpeg-turbo/libjpeg-turbo.git
    pushd .
    cd libjpeg-turbo
    cmake -DCMAKE_INSTALL_PREFIX=$SOFTWARE_HOME/libjpeg
    make -j && make install
    echo 'export LIBJPEG_HOME="$SOFTWARE_HOME/libjpeg"' >> $HOME/.bash_exports
    echo 'export PATH="$LIBJPEG_HOME/bin:$PATH"' >> $HOME/.bash_exports
    echo 'export LD_LIBRARY_PATH="$LIBJPEG_HOME/lib:$LD_LIBRARY_PATH"' >> $HOME/.bash_exports
    source $HOME/.bash_exports
    popd

    echo "Done"
}

function install_opencv()
{
    retval=$(promote "Install opencv? [y/n] " ${OPENCV})
    if [ "$retval" == "false" ]
    then
        echo "not installing opencv"
        return
    else
        echo "installing opencv ..."
    fi

    ### opencv
    pushd .
    cd $REPOSITORY_HOME

    # git clone https://github.com/opencv/opencv.git
    # git clone https://github.com/opencv/opencv_contrib.git

    cd opencv
    mkdir build
    cd build

    pip install numpy

    echo "start building ..."
    git clone https://github.com/belldandyxtq/opencv_build_script.git
    mv opencv_build_script/run.sh .

    ./run.sh
    make -j && make install
    echo 'export OPENCV_HOME="$SOFTWARE_HOME/opencv"' >> $HOME/.bash_exports
    echo 'export PATH="$OPENCV_HOME/bin:$PATH"' >> $HOME/.bash_exports
    echo 'export LD_LIBRARY_PATH="$OPENCV_HOME/lib:$LD_LIBRARY_PATH"' >> $HOME/.bash_exports

    popd

    echo "Done"
}


function install_openmpi()
{
    ### openmpi
    retval=$(promote "Install openmpi? [y/n] " ${OPENMPI})
    if [ "$retval" == "false" ]
    then
        echo "not installing openmpi"
        return
    else
        echo "installing openmpi ${OPENMPIVER} ..."
    fi

    pushd .
    cd $REPOSITORY_HOME

    OPENMPIV=`echo ${OPENMPIVER} | cut -c1-3`
    OPENMPI_TAR="openmpi-${OPENMPIVER}.tar.bz2"
    wget "https://download.open-mpi.org/release/open-mpi/v${OPENMPIV}/$OPENMPI_TAR" -O - | tar -xjf -
    cd openmpi-${OPENMPIVER}

    echo "building ..."
    ./configure --prefix $SOFTWARE_HOME/openmpi && make -j && make install

    echo 'export OPENMPI_HOME="$SOFTWARE_HOME/openmpi"' >> $HOME/.bash_exports
    echo 'export PATH="$OPENMPI_HOME/bin:$PATH"' >> $HOME/.bash_exports
    echo 'export LD_LIBRARY_PATH="$OPENMPI_HOME/lib:$LD_LIBRARY_PATH"' >> $HOME/.bash_exports

    popd 

    echo "Done"
}


function install_vim()
{
    ### vim
    retval=$(promote "Install vim? [y/n] " ${VIM})
    if [ "$retval" == "false" ]
    then
        echo "not installing vim"
        return
    else
        echo "installing vim ${OPENMPIVER} ..."
    fi

    pushd .
    cd $REPOSITORY_HOME

    git clone https://github.com/vim/vim.git
    cd vim

    echo "building vim ..."
    ./configure --prefix $SOFTWARE_HOME/vim --disable-gui \
        --disable-pythoninterp --enable-python3interp=dynamic \
        --with-python3-command=python3 \
        --with-python3-config-dir=${PYENV_ROOT}/versions/$PYHON3VER/lib/python3.7/config-3.7m-x86_64-linux-gnu
    
    make -j && make install

    echo 'export VIM_HOME="$SOFTWARE_HOME/vim"' >> $HOME/.bash_exports
    echo 'export PATH="$VIM_HOME/bin:$PATH"' >> $HOME/.bash_exports
    echo 'export LD_LIBRARY_PATH="$VIM_HOME/lib:$LD_LIBRARY_PATH"' >> $HOME/.bash_exports

    popd 

    echo "Done"
}

function usage()
{
    echo "Usage: $0 [bijcvh] [-p VERSION=$PYHON3VER] [-m VERSION=$OPENMPIVER]" 1>&2
    echo "     b: make basic directory" 1>&2
    echo "     p: install pyenv and python with of VERSION (default $PYHON3VER)" 1>&2
    echo "     i: run in interactive mode" 1>&2
    echo "     j: install libjpeg-turbo" 1>&2
    echo "     c: install opencv" 1>&2
    echo "     m: install openmpi VERSION (default $OPENMPIVER)" 1>&2
    echo "     v: install vim" 1>&2
    echo "     h: show this help message" 1>&2
    exit 0
}

##### Main

while getopts "bsijcvhp:m:" OPT
do
    case $OPT in
        b)  MAKE_BASIC="true"
            ;;
        s)  SETUP="true"
            ;;
        p)  PYENV="true"
		    PYHON3VER=$OPTARG
            ;;
        i)  INTERACTIVE="true"
            ;;
		j)  LIBJPEG="true"
		    ;;
        c)  OPENCV="true"
            ;;
        m)  OPENMPI="true"
            OPENMPIVER=$OPTARG
            ;;
        v)  VIM="true"
            ;;
        h)  usage
            ;;
        \?) usage
            ;;
    esac
done

make_basic_directory
install_pyenv
install_vim
setup_config
install_libjpeg
install_opencv
install_openmpi
