@echo off
set ANDROID_USER_HOME=C:\Users\Heman\.android
set ANDROID_HOME=C:\Users\Heman\AppData\Local\Android\Sdk
set JAVA_HOME=C:\Users\Heman\.jdks\corretto-17.0.20.1
set PATH=%PATH%;C:\Users\Heman\flutter\bin;C:\Program Files\Git\cmd

cd frontend
call flutter run -d adb-5C151JEA309292-k4Jzfz._adb-tls-connect._tcp
