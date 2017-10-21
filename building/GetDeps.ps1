cd C:\TEMP\
$WebClient = New-Object System.Net.WebClient
$TEMP = @("http://www.openssl.org/source/openssl-1.0.1l.tar.gz", "http://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz",
"https://netcologne.dl.sourceforge.net/project/boost/boost/1.57.0/boost_1_57_0.tar.gz", "http://miniupnp.free.fr/files/download.php?file=miniupnpc-1.9.20150206.tar.gz",
"https://github.com/google/protobuf/releases/download/v2.6.1/protobuf-2.6.1.tar.gz", "https://netcologne.dl.sourceforge.net/project/libpng/libpng16/older-releases/1.6.16/libpng-1.6.16.tar.gz",
"http://fukuchi.org/works/qrencode/qrencode-3.4.4.tar.gz",
"http://download.qt.io/archive/qt/5.2/5.2.1/single/qt-everywhere-opensource-src-5.2.1.tar.gz", 
"http://download.qt.io/archive/qt/5.2/5.2.1/submodules/qttools-opensource-src-5.2.1.tar.gz",
"http://download.qt.io/archive/qt/5.2/5.2.1/submodules/qtwebkit-opensource-src-5.2.1.tar.gz");
for ($i=7; $i -lt $TEMP.length; $i++){
    Write-Host "Downloading File:" $TEMP[$i]
	$WebClient.DownloadFile($TEMP[$i], "C:\\TEMP\\x.tar.gz")
    cd C:\TEMP\
    tar xvfz x.tar.gz
    if($i -eq 0){
        
        cd openssl-1.0.1l
        bash ./Configure no-zlib no-shared no-dso no-krb5 no-camellia no-capieng no-cast no-cms no-dtls1 no-gost no-gmp no-heartbeats no-idea no-jpake no-md2 no-mdc2 no-rc5 no-rdrand no-rfc3779 no-rsax no-sctp no-seed no-sha0 no-static_engine no-whirlpool no-rc2 no-rc4 no-ssl2 no-ssl3 mingw
        Start-Process cmd.exe @("/C";"make")
        cd ..
    }
    if($i -eq 1){
        cd db-4.8.30.NC/build_unix
        bash ../dist/configure --enable-mingw --enable-cxx --disable-shared --disable-replication
        Start-Process cmd.exe @("/C";"make")
        cd ../..
    }
    if($i -eq 2){
        cd boost_1_57_0
        ./bootstrap.bat mingw
        ./b2.exe --build-type=complete --with-chrono --with-filesystem --with-program_options --with-system --with-thread toolset=gcc variant=release link=static threading=multi runtime-link=static stage
        cd ..
    }
    if($i -eq 3){
        cd miniupnpc-1.9.20150206
        mingw32-make -f Makefile.mingw init upnpc-static
        cd ..
    }
    if($i -eq 4){
        cd protobuf-2.6.1
        configure --disable-shared
        Start-Process cmd.exe @("/C";"make")
        cd ..
    }
    if($i -eq 5){
        cd libpng-1.6.16
        configure --disable-shared
        Start-Process cmd.exe @("/C";"make && cp .libs/libpng16.a .libs/libpng.a")
        cd ..
    }
    if($i -eq 6){
        cd qrencode-3.4.4
        $env::LIBS="../libpng-1.6.16/.libs/libpng.a ../../mingw32/i686-w64-mingw32/lib/libz.a" 
        $env::png_CFLAGS="-I../libpng-1.6.16" 
        $env::png_LIBS="-L../libpng-1.6.16/.libs" 
        bash ./configure --enable-static --disable-shared --without-tools
        Start-Process cmd.exe @("/C";"make")
        cd ..
    }
    if($i -eq 7){
        Copy-Item -Force qt-everywhere-opensource-src-5.2.1 C:\Qt\5.2.1 -recurse
    }
    if($i -eq 8){
        Copy-Item -Force qttools-opensource-src-5.2.1 C:\Qt\qtbase-opensource-src-5.2.1 -recurse
        $QtSrcDir = "C:\Qt\5.2.1"
        $QtDir = "C:\Qt\Static\5.2.1"

            $File = "$QtSrcDir\qtbase\mkspecs\win32-g++\qmake.conf"
            if (-not (Select-String -Quiet -SimpleMatch -CaseSensitive "# [QT-STATIC-PATCH]" $File)) {
                Write-Output "Patching $File ..."
                Copy-Item $File "$File.orig"
                        @"

# [QT-STATIC-PATCH]
QMAKE_LFLAGS += -static -static-libgcc
QMAKE_CFLAGS_RELEASE -= -O2
QMAKE_CFLAGS_RELEASE += -Os -momit-leaf-frame-pointer
DEFINES += QT_STATIC_BUILD
"@ | Out-File -Append $File -Encoding Ascii
            }

        if (-not $MingwDir) {
            # Search all instances of gcc.exe from C:\Qt prebuilt environment.
            $GccList = @(Get-ChildItem -Path C:\Qt\*\Tools\mingw*\bin\gcc.exe | ForEach-Object FullName | Sort-Object)
            if ($GccList.Length -eq 0) {
                Exit-Script "MinGW environment not found, no Qt prebuilt version?"
            }
            $MingwDir = (Split-Path -Parent (Split-Path -Parent $GccList[$GccList.Length - 1]))
        }

        $env:QT_INSTALL_PREFIX = $QtDir

        set INCLUDE="C:\\TEMP\\libpng-1.6.16;C:\\TEMP\\openssl-1.0.1l\include"
        set LIB="C:\\TEMP\\libpng-1.6.16\.libs;C:\\TEMP\\openssl-1.0.1l"

        cd C:\Qt\5.2.1\
        bash ./configure -static -debug-and-release -platform win32-g++ -prefix C:\Qt\Static\5.2.1 -qt-zlib -qt-pcre -qt-libpng -qt-libjpeg -qt-freetype -opengl desktop -qt-sql-sqlite -openssl -opensource -confirm-license -make libs -nomake tools -nomake examples -nomake tests
        mingw32-make -j4
        mingw32-make -k install

        set PATH=$env:Path+";$QtDir\bin"

        $File = "$QtDir\mkspecs\win32-g++\qmake.conf"
    @"
CONFIG += static
"@ | Out-File -Append $File -Encoding Ascii

        cd C:\Qt\qttools-opensource-src-5.2.1
        qmake qttools.pro
        mingw32-make
    }
}

