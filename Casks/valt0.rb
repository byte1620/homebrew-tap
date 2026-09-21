cask "valt0" do
  arch arm: "arm64", intel: "amd64"

  version "0.0.55-pre"
  sha256 arm:   "1b6b80c9e490995afea44e8fc5e5de09fe82775ff7b9d09a6dcca72362aea17e",
         intel: "9fd6d7d981cafa84c39605aa99de518da41af9139f699880cbbda1a9b70e406c"

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

  depends_on macos: :ventura

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
end
