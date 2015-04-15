This is the source code for "Package Notifier", a bundle consisting out of a BulletinBord plugin, a tweak part that injects into SpringBoard and Preferences, a helper binary to run apt-related actions (since they should be exectued as root, which is not that easyly possible from SpringBoard), and a preferences bundle.

Requirs [AccuraTweaksCommon](https://github.com/Cr4zyS1m0n/AccuraTweaksCommon), which contains a lot of code used in the preferences bundle and the preferences tweak.

Description follows

---
---


###Package Notifier (compatible with iOS 7 & 8)###

Background Refresh, Notifications & Badges for Cydia

---

**Background Refresh** 

Refreshes all your package sources in the background every 1 to 48 hour (configurable). Also trigger-able using an activator action.


**Badges in Settings**

Highly customization badge in the settings for each package and a button that opens the package directly in Cydia within the package settings, all shown when there is an update available for that package.

<img width="132" src="http://i.imgur.com/VzS6hA3.png"> <img width="132"  src="http://i.imgur.com/MWgZ6hY.png">

**Update Notifications** 

Receive a banner notification as soon as an update is available for one of your installed packages. 

<img width="132" src="http://i.imgur.com/ZZpa6WC.png"> <img width="132"  src="http://i.imgur.com/xHrpHnw.png">



---

Package Notifier uses APT to refresh your package sources and determine available updates - a software for which Cydia is basically a frontend. It does not interact with Cydia directly, nor does it open Cydia in background.

Package Notifier's implementation of the notification part (a BulletinBoard plugin) is partially following the implementation of Curiosa by @rpetrich - updated for iOS 8 compatibility. Thanks for his work!

---

**Screenshots**

<img src="http://i.imgur.com/ejUjYe4.jpg"  height="450" width="253" >
<img src="http://i.imgur.com/Fteb20N.png"  height="450" width="253" >
<img src="http://i.imgur.com/ujvv0pz.jpg"  height="450" width="253" >
<img src="http://i.imgur.com/OijCDrj.jpg"  height="450" width="253" >
<img src="http://i.imgur.com/yx7YaUC.png"  height="450" width="253" >
<img src="http://i.imgur.com/VGQLjff.png"  height="450" width="253" >



**License**

Released under [BSD 3-Clause License](https://tldrlegal.com/license/bsd-3-clause-license-%28revised%29).
If you'd like to contribute something, feel free to send me a pull request!
