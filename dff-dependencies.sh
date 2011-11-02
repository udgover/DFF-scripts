#!/bin/sh
#
#  Script which installs some libraries dependencies for DFF
#  (Digital Forensics Framework). A folder "third-parties" is
#  created where DFF has been installed. It also modifies 
#  /usr/bin/dff script to add LD_LIBRARY_PATH of the thrid-parties
#  folder.
#
#  Libraries installed in third-parties folrder are:
#
#  - libbfio http://sourceforge.net/projects/libbfio/
#  - libewf http://sourceforge.net/projects/libewf/
#  - libpff http://sourceforge.net/projects/libpff/
#
#
# Copyright (c) 2011, Frederic Baguelin <fba@arxsys.fr>
#
#
# This software is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
# 
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this software.  If not, see <http://www.gnu.org/licenses/>.
#

# On Ubuntu zlib1g-dev must be installed to compile ewf

BASEDIR=${PWD}
WORKENV="${BASEDIR}/dff-deps"

build_bfio()
{
    cd ${WORKENV}
    if [ ! -d libbfio ] ; then
	mkdir libbfio
    fi
    echo "getting libbfio latest tarball from sourceforge and extracting to libbfio folder"
    wget -qO- "http://sourceforge.net/projects/libbfio/files/latest/download?_test=goal" | tar zxf - --strip-components=1 --directory=libbfio
    if [ $? != 0 ] ; then
	echo "!! Error while extracting libbfio."
	exit 1
    else
	cd libbfio
	echo "Building libbfio"
	./configure --prefix=${PWD}/temp_install && make && make install
	if [ $? != 0 ] ; then
	    echo "!! Error while building libbfio."
	fi
    fi
}

build_ewf()
{
    cd ${WORKENV}
    if [ ! -d libewf ] ; then
	mkdir libewf
    fi
    echo "getting libewf latest tarball from sourceforge and extracting to libewf folder"
    wget -qO- "http://sourceforge.net/projects/libewf/files/latest/download?_test=goal" | tar zxf - --strip-components=1 --directory=libewf
    if [ $? != 0 ] ; then
	echo "!! Error while extracting libewf."
	exit 1
    else
	cd libewf
	echo "Building libewf"
	CFLAGS="-D_LIBBFIO_TYPES_H" ./configure --prefix=${PWD}/temp_install --with-libbfio=${WORKENV}/libbfio/temp_install && make && make install
	if [ $? != 0 ] ; then
	    echo "!! Error while building libewf."
	    exit 1
	fi
    fi
}


build_pff()
{
    cd ${WORKENV}
    if [ ! -d libpff ] ; then
	mkdir libpff
    fi
    echo "getting libpff latest tarball from sourceforge and extracting to libpff folder"
    wget -qO- "http://sourceforge.net/projects/libpff/files/latest/download?_test=goal" | tar zxf - --strip-components=1 --directory=libpff
    if [ $? != 0 ] ; then
	echo "!! Error while extracting libpff."
	exit 1
    else
	cd libpff
	echo "Building libpff"
	LDFLAGS="-L${WORKENV}/libbfio/temp_install/lib" CFLAGS="-D_LIBBFIO_TYPES_H -I${WORKENV}/libbfio/temp_install/include" ./configure --prefix=${PWD}/temp_install && make && make install
	if [ $? != 0 ] ; then
	    echo "!! Error while building libpff."
	    exit 1
	fi
    fi
}


main() 
{
    DFF_STARTER=`whereis dff | sed -n "s/dff: \(.*\)/\1/ p"`
    if [ ! -z ${DFF_STARTER} ] ; then
	if [ "$(whoami)" = "root" ] ; then
	    if [ ! -d ${WORKENV} ] ; then
		mkdir ${WORKENV}
	    fi
            echo "starting building process"
	    build_bfio
	    build_ewf
	    build_pff
	    echo "gathering built libraries"
	    INSTALL_PATH=`sed -n "s/\(.*python \)\(.*\)\(\/dff\.py \$\*\)/\2/ p" $DFF_STARTER | tr -d ' \n'`
	    if [ -z "`grep LD_LIBRARY_PATH $DFF_STARTER`" ] ; then
		sed -i "s#\(python.*\$\*\)#LD_LIBRARY_PATH=$INSTALL_PATH/third-parties \1#" ${DFF_STARTER}
	    fi
	    echo "${INSTALL_PATH}"
	    if [ ! -d ${INSTALL_PATH}/third-parties ] ; then
		mkdir $INSTALL_PATH/third-parties
	    fi
	    cp -d ${WORKENV}/libbfio/temp_install/lib/libbfio.so* ${INSTALL_PATH}/third-parties
	    cp -d ${WORKENV}/libpff/temp_install/lib/libpff.so* ${INSTALL_PATH}/third-parties
	    cp -d ${WORKENV}/libewf/temp_install/lib/libewf.so* ${INSTALL_PATH}/third-parties
	    echo "Gathered libraries are:"
	    ls -la ${INSTALL_PATH}/third-parties
	    rm -rf ${WORKENV}
	else
	    echo "In order to work, you must be root"
	    exit 1
	fi
    else
	echo "DFF does not seem to be installed."
	echo "Please install it first."
	exit 1
    fi
}

main