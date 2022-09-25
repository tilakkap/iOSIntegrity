#!/bin/sh

# Type a script or drag a script file from your workspace to insert its path.
ARCHIVE_PATH="/Users/thomas/Library/Developer/Xcode/Archives/2565-09-25/RN1 25-9-2565 BE 16.09.xcarchive"
PRODUCT_NAME="RN1"
FULL_PRODUCT_NAME="${PRODUCT_NAME}.app"

# Copy to post archive from here
LOGFILE="$HOME/Desktop/xcode-post-action.txt" ;
EXE="${ARCHIVE_PATH}/Products/Applications/${FULL_PRODUCT_NAME}/${PRODUCT_NAME}"

echo "" > $LOGFILE ;
echo "Build Post-Action" >> $LOGFILE
plutil -convert xml1 "${ARCHIVE_PATH}/Products/Applications/${FULL_PRODUCT_NAME}/Info.plist"
SDKROOT=macosx
echo "EXE" "${EXE}" >> $LOGFILE
MACHO=$(otool -l "${EXE}" | grep -A 4 __text | grep 'offset\|size')
echo "MACHO" "${MACHO}" >> $LOGFILE
SIZE=$(echo "${MACHO}" | sed -n 1p | sed 's/size \(.\)/\1/g' | sed -e 's/[[:space:]]*//')
echo "SIZE" $SIZE >> $LOGFILE
SKIP=$(echo "${MACHO}" | sed -n 2p | sed 's/offset \(.\)/\1/g' | sed -e 's/[[:space:]]*//')
echo "SKIP" $SKIP >> $LOGFILE
MACHO_HASH=$(dd if="${EXE}" ibs=1 skip="${SKIP}" count="${SIZE}" | shasum -a 256 | sed 's/[[:space:]-]*//g')
echo "MACHO_HASH" $MACHO_HASH >> $LOGFILE
echo "BUIDDIR" ${BUILD_DIR%Build/*} >> $LOGFILE
cd ${BUILD_DIR%Build/*}SourcePackages/checkouts/iOSIntegrity
swift run -c release iOSIntegrityCli "${ARCHIVE_PATH}/Products/Applications/${FULL_PRODUCT_NAME}" "${MACHO_HASH}" >> $LOGFILE







