cask "valt0" do
  arch arm: "arm64", intel: "amd64"

  version "0.0.51-pre"
  sha256 arm:   "5170cfad33d61bad94f87082b7adb0c0c6820370ed418ac1303c36f4ccfd4ac7",
         intel: "933d1bdb8af4256abe7f93c481f8aaf61ded0d1a6c96d8c0b9e73ac61035e66b"

  url "https://dl.valt0.com/v1/#{version}/valt0-darwin-#{arch}.zip",
      verified: "dl.valt0.com/"
  name "Valt0"
  desc "Encrypted secrets vault with background sync daemon"
  homepage "https://valt0.com"

  livecheck do
    url "https://dl.valt0.com/v1/"
    regex(%r{href=.*?v?(\d+(?:\.\d+)+(?:-pre)?)/}i)
    strategy :page_match
  end

  depends_on macos: ">= :ventura"

  app    "valt0.app"
  binary "#{appdir}/valt0.app/Contents/MacOS/valt0"

  postflight do
    if ENV["HOMEBREW_VALT0_NO_SERVICE"]
      opoo "Skipping background service setup (HOMEBREW_VALT0_NO_SERVICE is set)."
      next
    end

    helper = "#{appdir}/valt0.app/Contents/MacOS/valt0-agent"

    unless File.exist?(helper)
      opoo "valt0-agent helper is missing from the app bundle; service not started."
      next
    end

    result = system_command helper,
                            args:         ["ensure"],
                            must_succeed: false,
                            print_stderr: false

    case result.stdout.strip
    when "enabled"
      ohai "valt0 background service is running."
    when "requires-approval"
      opoo "valt0 is installed but its background service is turned off. " \
           "Enable it in System Settings > General > Login Items & Extensions."
    when "not-found"
      opoo "valt0's agent plist is missing from the app bundle -- this is a " \
           "packaging bug. Please report it at https://valt0.com."
    else
      opoo "Could not start the valt0 background service: #{result.stderr.strip}"
      opoo "Open valt0 from your Applications folder to enable it."
    end
  end

  uninstall_preflight do
    helper = "#{appdir}/valt0.app/Contents/MacOS/valt0-agent"
    system_command(helper, args: ["unregister"], must_succeed: false) if File.exist?(helper)
  end

  uninstall launchctl: "com.byte1620.valt0"

  zap trash: [
    "~/Library/Application Support/valt0",
    "~/Library/Logs/valt0",
    "~/Library/Preferences/com.byte1620.valt0.plist",
    "~/Library/LaunchAgents/com.byte1620.valt0.plist",
  ]

  caveats <<~EOS
    valt0's background service has been enabled and starts at login.

    Open valt0 from your Applications folder to check whether it is
    running, or to turn it off. It can also be toggled in System
    Settings, under General > Login Items & Extensions.

    `brew services` no longer manages valt0.
  EOS
end
