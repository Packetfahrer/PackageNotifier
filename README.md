**Status**: Delayed, name changed to Package Notifier

---
---


###Package Notifier (iOS 7 & 8)###

Background Refresh, Notifications & Badges for Cydia

---

**Background Refresh** 

Refreshes all your package sources in the background every 1 to 48 hour (configurable). Also trigger-able using an activator action.


**Badges in Settings**

Highly customization badge in the settings for each package and a button that opens the package directly in Cydia within the package settings, all shown when there is an update available for that package.

<img width="132" src="http://i.imgur.com/VzS6hA3.png"> <img width="132"  src="http://i.imgur.com/MWgZ6hY.png">

**Update Notifications** 

Receive a banner notification as soon as an update is available for one of your installed packages. 

<img width="132" src="http://i.imgur.com/qzFpOuA.png"> <img width="132"  src="http://i.imgur.com/xHrpHnw.png">



---

Package Notifier uses APT to refresh your package sources and determine available updates - a software for which Cydia is basically a frontend. It does not interact with Cydia directly, nor does it open Cydia in background.

Package Notifier's implementation of the notification part (a BulletinBoard plugin) is partially following the implementation of Curiosa by @rpetrich - updated for iOS 8 compatibility. Thanks for his work!

---

**Screenshots**

<img src="http://i.imgur.com/OijCDrj.jpg"  height="450" width="253" >
<img src="http://i.imgur.com/Fteb20N.png"  height="450" width="253" >
<img src="http://i.imgur.com/ujvv0pz.jpg"  height="450" width="253" >
<img src="http://i.imgur.com/ejUjYe4.jpg"  height="450" width="253" >
<img src="http://i.imgur.com/bTxfxpA.png"  height="450" width="253" >
<img src="http://i.imgur.com/zev5GhU.png"  height="450" width="253" >



**License**

Released under [BSD 3-Clause License](https://tldrlegal.com/license/bsd-3-clause-license-%28revised%29).
If you'd like to contribute something, feel free to send me a pull request!
