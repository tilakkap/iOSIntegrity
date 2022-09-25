#!/bin/sh

# Type a script or drag a script file from your workspace to insert its path.
LOGFILE="$HOME/Desktop/xcode-post-action.txt" ;
EXE="${ARCHIVE_PATH}/Products/Applications/RN1.app/RN1"

echo "" > $LOGFILE ;
echo "Build Post-Action" >> $LOGFILE
plutil -convert xml1 "${ARCHIVE_PATH}/Products/Applications/RN1.app/Info.plist"
SDKROOT=macosx
echo "EXE" "${EXE}" >> $LOGFILE
MACHO=$(otool -l "${EXE}" | grep -A 4 __text | grep 'offset\|size')
echo "MACHO" "${MACHO}" >> $LOGFILE
SIZE=$(echo "${MACHO}" | sed -n 1p | sed 's/size \(.\)/\1/g' | sed -e 's/[[:space:]]*//')
echo "SIZE" $SIZE >> $LOGFILE
SKIP=$(echo "${MACHO}" | sed -n 2p | sed 's/offset \(.\)/\1/g' | sed -e 's/[[:space:]]*//')
echo "SKIP" $SKIP >> $LOGFILE
echo "BUIDDIR" ${BUILD_DIR%Build/*} >> $LOGFILE
cd ${BUILD_DIR%Build/*}SourcePackages/checkouts/iOSIntegrity
MACHO_HASH=$(dd if="${EXE}" ibs=1 skip=$SKIP count=$SIZE >> /dev/null | shasum -a 256 | sed 's/[[:space:]-]*//g')
swift run -c release iOSIntegrityCli "${ARCHIVE_PATH}/Products/Applications/RN1.app" >> $LOGFILE






