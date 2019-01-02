# GCConnection
> GameCenter multiplayer connection util

By [v-braun - viktor-braun.de](https://viktor-braun.de).

[![](https://img.shields.io/github/license/v-braun/GCConnection.svg?style=flat-square)](https://github.com/v-braun/GCConnection/blob/master/LICENSE)
[![Build Status](https://img.shields.io/travis/v-braun/GCConnection.svg?style=flat-square)](https://travis-ci.org/v-braun/GCConnection)
![PR welcome](https://img.shields.io/badge/PR-welcome-green.svg?style=flat-square)

<p align="center">
<img width="70%" src="https://github.com/v-braun/GCConnection/blob/master/.assets/logo.png?raw=true" />
</p>


## Description


## Installation

1. Download and drop ```GCConnection.swift``` in your project.  
2. Congratulations!  


## Usage

For detailed usage check out the demo [ViewController.swift](https://github.com/v-braun/GCConnection/blob/master/GCConnection/ViewController.swift) file.


### Authenticate

In your AppDelegate invoke *authenticate*

``` swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    GCConnection.shared.authenticate()
    
    return true
}
```

Later on in your ViewControlelr you can check the authenticate status

``` swift

switch GCConnection.shared.authStatus {
case .undef:
    // not authenticated
case .loginCancelled:
    // login canccelled 🙅‍♀️
case .error(let err):
    // auth err
case .loginRequired(let viewController):
    // login required
    // show present ciewController - it is the GC login view
case .ok(let localPlayer):
    // authenticated 🥳
}

```

You can also listen to authentication state changes!

Implement the *AuthHandler* protocol and set the authHandler property

``` swift

override func viewDidLoad() {
    super.viewDidLoad()
    
    GCConnection.shared.authHandler = self
}

```

### Match making





## Configuration

### Prepare App for GameCenter support

First you should enable the GameCenter feature in your ap. 
Go to Project/Capabilities and enable GameCenter

![Enable GameCenter](https://github.com/v-braun/GCConnection/blob/master/.assets/enable-gc-proj.png?raw=true)


After that you have to register your app in [App Store Connect](https://appstoreconnect.apple.com/). 
Login with your account and go to **My Apps**

![App Store Connect Home](https://github.com/v-braun/GCConnection/blob/master/.assets/appstore-conn-home.png?raw=true)

On the Dashboard add a new App


![App Store Connect Dashboard](https://github.com/v-braun/GCConnection/blob/master/.assets/appstore-conn-dashboard.png?raw=true)


Enter the needed information. 
**IMPORTANT:** The BundleIdentifier should match your Project setting


During my tests I found out that GameCenter will not recognize your app until you create at least one leaderboard. 

Goto /Features/Game Center/Leaderboard

![App Store Connect Leaderboard](https://github.com/v-braun/GCConnection/blob/master/.assets/appstore-conn-leaderboard.png?raw=true)



## Related Projects
[Cocoa Rocks](https://cocoa.rocks/): a gallery of beatiful Cocoa Controls
[awesome-cocoa](https://github.com/v-braun/awesome-cocoa): an awesome list of cocoa controls


## Authors

![image](https://avatars3.githubusercontent.com/u/4738210?v=3&amp;s=50)  
[v-braun](https://github.com/v-braun/)



## Contributing

Make sure to read these guides before getting started:
- [Contribution Guidelines](https://github.com/v-braun/GCConnection/blob/master/CONTRIBUTING.md)
- [Code of Conduct](https://github.com/v-braun/GCConnection/blob/master/CODE_OF_CONDUCT.md)

## License
**GCConnection** is available under the MIT License. See [LICENSE](https://github.com/v-braun/GCConnection/blob/master/LICENSE) for details.
