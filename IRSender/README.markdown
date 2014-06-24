# How to attach custom icon

Use Finder and attach custom icon (resources/IRSender.png) to IRSender.scpt .
Save custom icon resource fork to a separate file.

```
% DeRez -only icns ./IRSender.scpt > resources/IRSender.rsrc
```

Next, when adding:

```
% Rez -append resources/IRSender.rsrc -o IRSender.scpt
% SetFile -a C IRSender.scpt
```
