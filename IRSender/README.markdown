# How to attach custom icon

Use Finder and attach custom icon (resources/IRSender.png) to IRSender.scpt .
Save custom icon resource fork to a separate file.

```
% DeRez -only icns ./IRSender.scpt > resources/IRSender.rsrc
# or
% DeRez -only icns ~/.irkit.d/signals/bb.json > resources/IRSignal.json.icon.rsrc
```

Next, when adding:

```
% Rez -append resources/IRSender.rsrc -o IRSender.scpt
% SetFile -a C IRSender.scpt
# or
% Rez -append resources/IRSignal.json.icon.rsrc -o ~/.irkit.d/signals/aa.json
% SetFile -a C ~/.irkit.d/signals/aa.json
```


# How to open file using specified application

Use Finder to associate application.

```
% xattr -px com.apple.ResourceFork ~/.irkit.d/signals/aa.json > resources/IRSignal.json.app.xattr
# or
% DeRez -only usro ~/.irkit.d/signals/aa.json > resources/IRSignal.json.app.rsrc
```

Next, when adding:

```
% xattr -wx com.apple.ResourceFork "`cat resources/IRSignal.json.app.xattr`" ~/.irkit.d/signals/bb.json
# or
% Rez -append resources/IRSignal.json.app.rsrc -o ~/.irkit.d/signals/bb.json
```
