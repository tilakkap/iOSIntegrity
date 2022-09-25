#!/bin/sh
#EXE="/Users/thomas/Library/Developer/Xcode/Archives/2565-09-25/RN1 25-9-2565 BE 12.50.xcarchive/Products/Applications/RN1.app/RN1"
EXE="/Users/thomas/Projects/swift/iOSIntegrity/Tests/test.app/RN1"
MACHO=$(otool -l $EXE | grep -A 4 __text | grep 'offset\|size')
SIZE=$(echo $MACHO | sed -n 1p | sed 's/size \(.\)/\1/g' | sed -e 's/[[:space:]]*//')
SKIP=$(echo $MACHO | sed -n 2p | sed 's/offset \(.\)/\1/g' | sed -e 's/[[:space:]]*//')
echo $MACHO
echo $SIZE
echo $SKIP
MACHO_HASH=$(dd if=$EXE ibs=1 skip=$SKIP count=$SIZE >> /dev/null | shasum -a 256 | sed 's/[[:space:]-]*//g')
echo $MACHO_HASH
