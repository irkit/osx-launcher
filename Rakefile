require "pp"
require "xcodeproj"
require "versionomy"

TARGET_NAME           = "IRLauncher"
SCHEME_NAME           = TARGET_NAME
PRODUCT_NAME          = TARGET_NAME
CONFIGURATION         = "Release"
SDK                   = "macosx"
GITHUB_USER           = "irkit"
GITHUB_REPO           = "osx-launcher"

PROJECT_PATH          = "#{TARGET_NAME}.xcodeproj"
WORKSPACE_PATH        = "#{TARGET_NAME}.xcworkspace"
INFOPLIST_PATH        = "#{TARGET_NAME}/#{TARGET_NAME}-Info.plist"
PRODUCT_PATH          = "Products"

CODE_SIGNING_IDENTITY = "IRLauncher signing certificate"

[:major,:minor,:tiny].each { |part|
  desc "increment #{part} part of version"
  task "increment:#{part}" do |task|
    version=`/usr/libexec/Plistbuddy -c "Print CFBundleVersion" #{INFOPLIST_PATH}`.chomp
    version=Versionomy.parse(version)
    version=version.bump(part)

    # I use the same string for CFBundleVersion and CFBundleShortVersionString for now
    sh "/usr/libexec/PlistBuddy -c 'Set :CFBundleVersion #{version}' #{INFOPLIST_PATH}"
    sh "/usr/libexec/PlistBuddy -c 'Set :CFBundleShortVersionString #{version}' #{INFOPLIST_PATH}"

    print "version upgraded to #{version}\n"
  end
}

desc "build #{PRODUCT_NAME}"
task "build" do |task|
  sh "xcodebuild -workspace '#{WORKSPACE_PATH}' -scheme '#{SCHEME_NAME}' -sdk '#{SDK}' -configuration '#{CONFIGURATION}' install DSTROOT='#{PRODUCT_PATH}'"
end

desc "clean"
task "clean" do |task|
  sh "xcodebuild clean -workspace '#{WORKSPACE_PATH}' -scheme '#{SCHEME_NAME}'"
  sh "rm -rf Products/"
end

desc "codesign"
task "codesign" do |task|
  # don't abort when codesign returns non 0, for example when already signed
  sh "codesign --sign '#{CODE_SIGNING_IDENTITY}' --verbose ./Products/Applications/#{PRODUCT_NAME}.app" rescue nil
end

desc "zip"
task "zip" do |task|
  sh "cd ./Products/Applications && zip #{PRODUCT_NAME}.app.zip -r #{PRODUCT_NAME}.app"
end

desc "release"
task "release" do |task|
  tag=`git describe --abbrev=0 --tags`.chomp

  # go get github.com/mash/github-release
  sh "github-release release --user #{GITHUB_USER} --repo #{GITHUB_REPO} --tag #{tag} --name #{tag} --pre-release"
  sh "github-release upload --user #{GITHUB_USER} --repo #{GITHUB_REPO} --tag #{tag} --name "#{PRODUCT_NAME}.app.zip" --file Products/Applications/#{PRODUCT_NAME}.app.zip"
end

task "default" => [ "clean", "build", "codesign", "zip" ]
