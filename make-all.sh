/usr/bin/bash

VERSION="1.0"

# universal
UNIVERSAL="usss-ohio-v${VERSION}--universal.love"
cd usss-ohio/
/usr/bin/zip -9 -r ../${UNIVERSAL} .
cd ..

# windows
WIN_DIR="usss-ohio-v${VERSION}--win32"
/usr/bin/mkdir ./${WIN_DIR}
/usr/bin/cat love-win32.exe ${UNIVERSAL} > ./${WIN_DIR}/usss-ohio-v${VERSION}.exe
/usr/bin/cp ./love-win32/* ./${WINDIR}
/usr/bin/zip -9 -r ./${WIN_DIR} ./${WIN_DIR}.zip

