#!/usr/bin/bash

VERSION="1.0"

/usr/bin/mkdir -p ./distributions/

# universal
UNIVERSAL="usss-ohio-v${VERSION}--universal.love"
cd src/
/usr/bin/zip -9 -r ../distributions/${UNIVERSAL} .
cd ..

# windows
WIN_DIR="usss-ohio-v${VERSION}--win32"
/usr/bin/mkdir -p ./distributions/${WIN_DIR}
/usr/bin/cat ./love-win32/love.exe ./distributions/${UNIVERSAL} \
  > ./distributions/${WIN_DIR}/usss-ohio-v${VERSION}.exe
/usr/bin/cp ./love-win32/license.txt ./distributions/${WIN_DIR}
/usr/bin/cp ./love-win32/love.dll ./distributions/${WIN_DIR}
/usr/bin/cp ./love-win32/lua51.dll ./distributions/${WIN_DIR}
/usr/bin/cp ./love-win32/mpg123.dll ./distributions/${WIN_DIR}
/usr/bin/cp ./love-win32/msvcp120.dll ./distributions/${WIN_DIR}
/usr/bin/cp ./love-win32/msvcr120.dll ./distributions/${WIN_DIR}
/usr/bin/cp ./love-win32/OpenAL32.dll ./distributions/${WIN_DIR}
/usr/bin/cp ./love-win32/SDL2.dll ./distributions/${WIN_DIR}
cd ./distributions
/usr/bin/zip -9 -r ${WIN_DIR}.zip ./${WIN_DIR}
cd ..

