-- thanks to http://stackoverflow.com/questions/3444326/list-all-applications-output-as-text-file
property pLSRegisterPath : "/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"

using terms from application "Quicksilver"
	on open _files
		set _apppath to (do shell script pLSRegisterPath & " -dump | grep -m 1 --only-matching \"/.*/IRLauncher\\.app\"")
		set _path to POSIX path of (item 1 of _files as text)
	
		do shell script _apppath & "/Contents/MacOS/IRLauncher " & _path & " > /dev/null 2>&1 &"
	end open
end using terms from
