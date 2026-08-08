EDEN MUSIC ANDROID LAUNCHER ICON

To update the Eden Music launcher icon for a new Android release:

1. Prepare the new launcher icon assets.
2. Replace the existing ic_launcher assets in:
   android/app/src/main/res/mipmap-mdpi/
   android/app/src/main/res/mipmap-hdpi/
   android/app/src/main/res/mipmap-xhdpi/
   android/app/src/main/res/mipmap-xxhdpi/
   android/app/src/main/res/mipmap-xxxhdpi/

3. Replace both regular and round launcher icons.
4. Keep the AndroidManifest.xml references:
   @mipmap/ic_launcher
   @mipmap/ic_launcher_round

5. Rebuild the Android app.

The launcher icon is a native Android asset. Changing an image inside the web app does not change the installed Android launcher icon.
