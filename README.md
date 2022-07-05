# Instagram Clone
## _By Tien Dat Pham_
##### Flutter/Dart
##### Firebase Realtime Database - Firebase Storage
##### Facebook Developer - Facebook Login
---
## How to run
##### **Note**: *If after all the steps you still can't run or get an error, please contact me using the information at the end*
#
##### Make sure you are using these versions (you can update if you want):
- ##### Flutter 3.0.1
- #####   Dart 2.17.1
- ##### Environment sdk : >=2.17.1 <3.0.0
- ##### Kotlin 1.6.10
- ##### android/app/build.gradle:  minSdkVersion 22/targetSdkVersion 31

##### Command to run:
#
    flutter clean
    flutter pub upgrade --major-versions
    flutter pub outdated
    flutter pub get
    flutter run
##### Here is list test accounts or you can ***Login with Facebook*** or ***Sign up*** new account for you
1. email: cat@gmail.com /password: 123456
2. email: dog@gmail.com /password: 123456

## Configure Firebase tutorial 

##### **Note**: *unnecessary - only if you want to use your firebase*

### Step 1 - Create Project and Android App in firebase console

- Go to https://console.firebase.google.com/

- Click Add Project

- Enter Project name and click Continue

- Disable Google Analytics and click Create Project

- Create Android app

![](https://firebasestorage.googleapis.com/v0/b/instagram-clone-99e38.appspot.com/o/README_TUTORIAL%2Fb2.png?alt=media&token=19d501dc-85f8-4717-b7db-2ffd3858a2c0)

- Add or Change google-services.json 

![](https://firebasestorage.googleapis.com/v0/b/instagram-clone-99e38.appspot.com/o/README_TUTORIAL%2Fb3.png?alt=media&token=e8851b6c-8897-4494-8f93-59425f9055fd)

- Add Firebase SDK and create

### Step 2 - Configure Authentication

- Click Authentication -> Click Get Started

- Choose Email/Password -> Enable Email/Password -> Save

![](https://firebasestorage.googleapis.com/v0/b/instagram-clone-99e38.appspot.com/o/README_TUTORIAL%2Fb4.png?alt=media&token=4619665f-2999-4148-ae4c-4bf7b04285f3)

### Step 3 - Configure Realtime Database

- Click Realtime Database -> Click Create Database -> Next

- Security rules -> Start in test mode -> Enable

- Click Edit Rules and change follow below

![](https://firebasestorage.googleapis.com/v0/b/instagram-clone-99e38.appspot.com/o/README_TUTORIAL%2Fb5.png?alt=media&token=94e850e6-b202-4a53-ad36-193bc8c16373)

### Step 4 - Configure Storage

- Click Storage -> Click Get started 

- Secure rules for Cloud Storage : click "start in test mode" -> Next -> Done

- Click Edit rules and change follow below

![](https://firebasestorage.googleapis.com/v0/b/instagram-clone-99e38.appspot.com/o/README_TUTORIAL%2Fb6.png?alt=media&token=c77a7c7c-c8ce-49c4-93ec-16c8743ee557)


## License
BSD License

## Contact

**Email** : phamtiendat230901@gmail.com

**Facebook** : [@Code.moew](https://www.facebook.com/Code.moew/ "Facebook Pham Tien Dat")

**Phone** : 0903684049



