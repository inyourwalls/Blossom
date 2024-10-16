#!/bin/sh

# Build using Xcode
xcodebuild clean build archive \
-scheme Blossom \
-project Blossom.xcodeproj \
-sdk iphoneos \
-destination 'generic/platform=iOS' \
-archivePath Blossom \
CODE_SIGNING_ALLOWED=NO

chmod 0644 Resources/Info.plist
cp supports/entitlements.plist Blossom.xcarchive/Products
cd Blossom.xcarchive/Products/Applications
codesign --remove-signature Blossom.app
cd -
cd Blossom.xcarchive/Products
mv Applications Payload
ldid -Sentitlements.plist Payload/Blossom.app
chmod 0644 Payload/Blossom.app/Info.plist
zip -qr Blossom.tipa Payload
cd -
mkdir -p packages
mv Blossom.xcarchive/Products/Blossom.tipa packages/Blossom.tipa
