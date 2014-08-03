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
