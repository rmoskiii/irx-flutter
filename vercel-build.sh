#!/bin/bash
if [ -d "flutter" ]; then
  cd flutter && git pull && cd ..
else
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

export PATH="$PATH:`pwd`/flutter/bin"
flutter build web --base-href "/demo/" --dart-define=API_BASE_URL=https://irx-backend-908197786741.africa-south1.run.app
