#!/bin/bash

echo "🔐 Android Keystore Setup for Play Store"
echo "========================================"

# 키스토어 정보
KEYSTORE_FILE="upload-keystore.jks"
KEY_ALIAS="upload"
VALIDITY_DAYS=10000

# 사용자 정보 입력
echo "Enter your information for the keystore:"
read -p "Your name (CN): " CN
read -p "Organization Unit (OU): " OU
read -p "Organization (O): " O
read -p "City/Locality (L): " L
read -p "State/Province (ST): " ST
read -p "Country Code (C): " C

# 키스토어 생성
echo ""
echo "Creating keystore..."
keytool -genkey -v \
  -keystore $KEYSTORE_FILE \
  -keyalg RSA \
  -keysize 2048 \
  -validity $VALIDITY_DAYS \
  -alias $KEY_ALIAS \
  -dname "CN=$CN, OU=$OU, O=$O, L=$L, ST=$ST, C=$C"

if [ $? -eq 0 ]; then
  echo ""
  echo "✅ Keystore created successfully!"
  
  # key.properties 파일 생성
  echo ""
  echo "Creating key.properties file..."
  
  read -sp "Enter keystore password: " STORE_PASSWORD
  echo ""
  read -sp "Enter key password (press enter if same as keystore password): " KEY_PASSWORD
  echo ""
  
  if [ -z "$KEY_PASSWORD" ]; then
    KEY_PASSWORD=$STORE_PASSWORD
  fi
  
  cat > android/key.properties << EOF
storePassword=$STORE_PASSWORD
keyPassword=$KEY_PASSWORD
keyAlias=$KEY_ALIAS
storeFile=../upload-keystore.jks
EOF
  
  echo "✅ key.properties created!"
  
  # .gitignore에 추가
  if ! grep -q "key.properties" android/.gitignore 2>/dev/null; then
    echo "key.properties" >> android/.gitignore
    echo "✅ Added key.properties to .gitignore"
  fi
  
  if ! grep -q "*.jks" .gitignore 2>/dev/null; then
    echo "*.jks" >> .gitignore
    echo "✅ Added *.jks to .gitignore"
  fi
  
  echo ""
  echo "📋 Next steps:"
  echo "1. Keep your keystore file safe! You'll need it for all future updates."
  echo "2. Update android/app/build.gradle to use the signing configuration"
  echo "3. Build your release APK/AAB"
  
else
  echo "❌ Failed to create keystore"
  exit 1
fi