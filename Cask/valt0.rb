cask "valt0" do
  arch arm: "arm64", intel: "amd64"

  version "0.0.50-pre"
  sha256 arm:   "4d853624ec06530c99693aea693e834b719ea4332b85460fda5ab81cae14f551",
         intel: "211641a06c978ed49ca316bc977349b93d43c454947bd301aeb30d9deb6e9998"

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

  conflicts_with formula: "valt0"

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

    # Migration: the old formula installed a plist under the same label, so both
    # jobs would contend. Remove it, but only if it points into the Homebrew
    # prefix -- never touch a plist a user wrote by hand.
    legacy = File.expand_path("~/Library/LaunchAgents/com.byte1620.valt0.plist")
    if File.exist?(legacy) && File.read(legacy).include?("/libexec/valt0.app")
      ohai "Removing the launchd job left over from the valt0 formula."
      system_command "/bin/launchctl",
                     args:         ["bootout", "gui/#{Process.uid}/com.byte1620.valt0"],
                     must_succeed: false,
                     print_stderr: false
      File.delete(legacy)
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
