IRLauncher : Launch IR signals from your favorite launcher (Quicksilver, Alfred, ..)
====================================================================================

IRLauncher is a Mac client for [IRKit device](github.com/irkit/device).  
Get one from [Amazon.co.jp](http://www.amazon.co.jp/gp/product/B00H91KK26) and set it up before using this.

IRLauncher's purpose is to be the fastest way to control home electronics when you're using a Mac.  
Fastest means not leaving home position on keyboard, obviously.  
I heavily use [Quicksilver](http://qsapp.com/), many others use [Alfred 2](http://www.alfredapp.com/) or Spotlight, so why not send infrared signals utilizing a launcher app?

## Demo

<a href="http://www.youtube.com/watch?feature=player_embedded&v=Qex3yCzFVyA" target="_blank"><img src="http://img.youtube.com/vi/Qex3yCzFVyA/0.jpg" alt="IMAGE ALT TEXT HERE" width="480" height="360" border="10" /></a>  
Click to play on YouTube.

## Installation

[Download the latest release](https://github.com/irkit/osx-launcher/releases) and place it in /Applications directory.

1. Launch IRLauncher.app
1. Click on either "Install Quicksilver extension" or "Install Alfred extension".
1. Learn an IR signal and set it's name.
1. Use Quicksilver, Alfred 2 or Spotlight (or any other launcher) to send the IR signal!

### Quicksilver

Type IR signals' name, `<TAB>` and select `IRSender` action.

![Quicksilver screenshot](/Web/quicksilver.png?raw=true)

### Alfred 2

Type `ir<space>` and then IR signals' name.

![Alfred 2 screenshot](/Web/alfred2.png?raw=true)

You need Powerpack license to use this.

## How does this work?

IRLauncher stores IR signal JSON representation files under `~/.irkit.d/signals` directory, with a filename you give.  
Quicksilver, Alfred 2 extensions tell their indexer to index files under `~/.irkit.d/signals`.  
IRLauncher also sets the custom launch application of the IR JSON representation file to itself, so you can just double click `aircon-off.json` to turn off your air conditioner.

You can also call `/Applications/IRLauncher.app/Contents/MacOS/IRLauncher ~/.irkit.d/signals/aircon-off.json` to send it.

IRLauncher uses `NSDistributedNotificationCenter`, make sure you're not killing `distnoted` which manages `NSDistributedNotification`s.

## More information

* [About IRKit](http://getirkit.com/)
* [IRKit device](http://github.com/irkit/device)
* [iOS App : IRKit Simple Remote](https://itunes.apple.com/app/irkit-simple-remote/id778790928?l=ja&ls=1&mt=8)
* Build your own IR sender app using [IRKit's SDK](https://github.com/irkit/ios-sdk)
* [Author on Twitter @maaash](http://twitter.com/maaash)
* [Contributing](https://github.com/irkit/ios-sdk/blob/master/Contributing.md)
* [License](https://github.com/irkit/osx-launcher/blob/master/LICENSE)

## [Acknowledgements](https://github.com/irkit/osx-launcher/blob/master/Pods/Pods-acknowledgements.markdown)

Thank you.
