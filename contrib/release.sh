#!/bin/bash
source gpg_id
echo "using gpg id: $GPG_ID"
#echo "Press any key..."
#read
cd ../..

if [ $# -ne 0 ]
then
  RELEASE=$1
else
  RELEASE=$(date +"%y%m%d")
  RELEASE="0.0.18."${RELEASE:0:6}
fi
echo Building release: $RELEASE

if [ -d release ]
then
	echo Directory release exists, removing ...
	rm -rf release
fi

echo exporting git tree...

git clone ./ release
cd release/qucs
git submodule init
git submodule update
cd ../..
mv release/examples release/qucs/examples/examples
mv release/qucs-core release/qucs/
mv release/qucs release/qucs-$RELEASE
rm -rf release/.git

if [ -f ~/Downloads/qucs-doc.tar.gz ]
then
	cd release/qucs-$RELEASE
	cp ~/Downloads/qucs-doc.tar.gz .
	tar -zxvf qucs-doc.tar.gz
	rm qucs-doc.tar.gz
else
	cd release/qucs-doc
	./autogen.sh
	cd tutorial
	make tutorial
	make book
	cd ..
	cd report
	make report
	make book
	cd ..
	cd technical
	make technical
	ps2pdf technical.ps
	cd ..



	DOC_SUBDIRS="report technical tutorial"
	for DOC_SUBDIR in ${DOC_SUBDIRS} ; do
		cd $DOC_SUBDIR
		mkdir -p ../../qucs-$RELEASE/qucs-doc/$DOC_SUBDIR
		find -name "*.pdf" |grep -v pics| xargs cp -t ../../qucs-$RELEASE/qucs-doc/$DOC_SUBDIR
		cd ..
	done
fi

#including pdf versions of qucs-doc in archives
cd ../qucs-$RELEASE
cd qucs-doc
./autogen.sh
make distclean
cd ..

cd examples
./autogen.sh
make distclean
cd ..

#Include the asco archive
if [ -f ~/Downloads/ASCO-0.4.9.tar.gz ]
then
	cp ~/Downloads/ASCO-0.4.9.tar.gz .
else
	wget https://downloads.sourceforge.net/project/asco/asco/0.4.9/ASCO-0.4.9.tar.gz
fi

tar -zxvf ASCO-0.4.9.tar.gz
rm ASCO-0.4.9.tar.gz
mv ASCO-0.4.9 asco
cd asco
patch -p1 < ../../../qucs/contrib/patch_asco_unbuffer.diff
#https://sourceforge.net/p/qucs/bugs/143/
patch -p1 < ../../../qucs/contrib/asco-nmlatest.c.patch
touch NEWS
tar -zxvf Autotools.tar.gz
patch -p1 < ../../../qucs/contrib/patch_asco_osx.diff
./autogen.sh
automake --add-missing
aclocal
cd ..

###include the freehdl archive
#wget http://freehdl.seul.org/~enaroska/freehdl-0.0.7.tar.gz
#tar -zxvf freehdl-0.0.7.tar.gz
#rm freehdl-0.0.7.tar.gz
#mv freehdl-0.0.7 freehdl

#include verilog in the archive
#wget ftp://icarus.com/pub/eda/verilog/v0.9/verilog-0.9.6.tar.gz
#tar -zxvf verilog-0.9.6.tar.gz
#rm verilog-0.9.6.tar.gz
#mv verilog-0.9.6 verilog


#sed -i 's/# AC_CONFIG_SUBDIRS(qucs-core)/AC_CONFIG_SUBDIRS(qucs-core)/g' configure.ac
#sed -i 's/# RELEASEDIRS="qucs-core"/RELEASEDIRS="qucs-core"/g' configure.ac
#sed -i 's/# AC_CONFIG_SUBDIRS(qucs-doc)/AC_CONFIG_SUBDIRS(qucs-doc)/g' configure.ac
#sed -i 's/# RELEASEDIRS="$RELEASEDIRS qucs-doc"/RELEASEDIRS="$RELEASEDIRS qucs-doc"/g' configure.ac
#sed -i 's/# AC_CONFIG_SUBDIRS(examples)/AC_CONFIG_SUBDIRS(examples)/g' configure.ac
#sed -i 's/# RELEASEDIRS="$RELEASEDIRS examples"/RELEASEDIRS="$RELEASEDIRS examples"/g' configure.ac
#sed -i 's/# AC_CONFIG_SUBDIRS(asco)/AC_CONFIG_SUBDIRS(asco)/g' configure.ac
#sed -i 's/# RELEASEDIRS="$RELEASEDIRS asco"/RELEASEDIRS="$RELEASEDIRS asco"/g' configure.ac

sed -i 's/RELEASE=no/RELEASE=yes/g' configure.ac

./autogen.sh
make distclean
rm -rf autom4te.cache


cd qucs-core/deps/adms
#wget http://downloads.sourceforge.net/project/mot-adms/adms-source/2.3/adms-2.3.2.tar.gz
#tar -zxvf adms-2.3.2.tar.gz
#mv adms-2.3.2/* .
#rm -rf adms-2.3.2 
#rm adms-2.3.2.tar.gz
cd admsXml
sed -i 's/\$(generated_FILES)/ /g' Makefile.in
sed -i 's/\$(generated_FILES)/ /g' Makefile.am
sed -i 's/\$(generated_FILES)/ /g' Makefile
cd ../../..
#cd qucs-core
libtoolize
./bootstrap.sh
./configure --enable-maintainer-mode
make
#cd adms
#make
#cd ../src/components/verilog
#make
#cd ../../../
./configure
make distclean
rm -rf autom4te.cache
cd ..
cd ..

echo creating source archive...

tar -zcvhf qucs-$RELEASE.tar.gz qucs-$RELEASE
rm -rf qucs-$RELEASE
tar -zxvf qucs-$RELEASE.tar.gz #make the symbolic links actual files

DISTS="trusty utopic vivid"
cd qucs-$RELEASE
./configure
cd ..
tar -zcvhf qucs_$RELEASE.orig.tar.gz qucs-$RELEASE
#cp qucs-$RELEASE.tar.gz qucs_$RELEASE.orig.tar.gz

cd qucs-$RELEASE
COUNT=-0 #last version number in repository
for DIST in ${DISTS} ; do
	COUNT=$(($COUNT-1))
	dch -D $DIST -m -v $RELEASE$COUNT -b snapshot
	debuild -S -k$GPG_ID
	./configure
done


#echo "Building mingw32"
#make clean
#INNOSETUP="$HOME/.wine/drive_c/Program Files (x86)/Inno Setup 5/Compil32.exe"
#cd ..
#WINDIR=$PWD/qucs-win32-bin
#cd qucs-$RELEASE
#export QTDIR=~/.wine/drive_c/Qt/4.8.4/
#./mingw-configure --prefix=$WINDIR
#sed -i 's/-fno-rtti/ /g' qucs-filter-v2/Makefile
#cp ../../qucs/qucs/qucsdigi.bat qucs #is deleted by the linux build for some reason
#make
#make install
#
#cp contrib/innosetup/gpl.rtf $WINDIR
#cp -r contrib/innosetup/misc $WINDIR
#if [ -f ~/Downloads/iverilog-0.9.6_setup.exe ]
#then
#	cp ~/Downloads/iverilog-0.9.6_setup.exe .
#else
#	wget http://bleyer.org/icarus/iverilog-0.9.6_setup.exe
#	#wget http://bleyer.org/icarus/iverilog-0.9.5_setup.exe
#fi
#mv iverilog-0.9.6_setup.exe $WINDIR
#if [ -f ~/Downloads/freehdl-0.0.8-setup.exe ]
#then
#	cp ~/Downloads/freehdl-0.0.8-setup.exe .
#else
#	wget https://downloads.sourceforge.net/project/qucs/freehdl/freehdl-0.0.8-setup.exe
#fi
#
#mv freehdl-0.0.8-setup.exe $WINDIR
#if [ -f ~/Downloads/mingw32-g++-0.0.2-setup.exe ]
#then
#	cp ~/Downloads/mingw32-g++-0.0.2-setup.exe .
#else
#	wget https://downloads.sourceforge.net/project/qucs/freehdl/mingw32-g%2B%2B-0.0.2-setup.exe
#fi
#mv mingw32-g++-0.0.2-setup.exe $WINDIR
#
#cp $QTDIR/bin/mingwm10.dll $WINDIR/bin
#cp $QTDIR/bin/Qt3Support4.dll  $WINDIR/bin
#cp $QTDIR/bin/QtCore4.dll  $WINDIR/bin
#cp $QTDIR/bin/QtGui4.dll  $WINDIR/bin
#cp $QTDIR/bin/QtNetwork4.dll  $WINDIR/bin
#cp $QTDIR/bin/QtXml4.dll  $WINDIR/bin
#cp $QTDIR/bin/QtSql4.dll  $WINDIR/bin
#cp $QTDIR/bin/QtSvg4.dll $WINDIR/bin
#cp $QTDIR/bin/QtScript4.dll $WINDIR/bin
#cp $QTDIR/bin/libgcc_s_dw2-1.dll $WINDIR/bin
#
#
#cp /usr/lib/gcc/i586-mingw32msvc/4.2.1-sjlj/*.dll $WINDIR/bin
#cp /usr/lib/gcc/i686-w64-mingw32/4.6/*.dll $WINDIR/bin
#
#wine "$INNOSETUP" /cc contrib/innosetup/qucs.iss
#mv contrib/innosetup/Output/qucs-0.0.18-setup.exe ../qucs-$RELEASE.exe
#
#cp debian/changelog ../../qucs/debian/changelog












