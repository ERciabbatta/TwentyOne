on:
push:
branches:
- master

name: Build My Apps

jobs:
build:
name: Build and Release new apk
runs-on: ubuntu-latest
steps:
- uses: actions/checkout@v3

- uses: actions/setup-java@v2
with:
distribution: 'zulu'
java-version: '17'

- uses: subosito/flutter-action@v2
with:
channel: 'stable'

- run: flutter pub get

- name: Decode keystore
        run: echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 --decode > android/app/release.jks

        - name: Create key.properties
        run: |
cat > android/key.properties <<EOF
        storeFile=../app/release.jks
storePassword=${{ secrets.STORE_PASSWORD }}
keyAlias=${{ secrets.KEY_ALIAS }}
keyPassword=${{ secrets.KEY_PASSWORD }}
EOF

- run: flutter build apk --release --split-per-abi

- name: Push to Releases
uses: ncipollo/release-action@v1
with:
artifacts: "build/app/outputs/apk/release/*"
tag: v${{ github.run_number }}
token: ${{ secrets.TOKEN }}