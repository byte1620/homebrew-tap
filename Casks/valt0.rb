cask "valt0" do
  arch arm: "arm64", intel: "amd64"

  version "0.0.56-pre"
  sha256 arm:   "2e8a2a1b34da5c9d9cd7a09c7d9242333141b771ba9e56c877ce056d84831b9a",
         intel: "a2ca2cca4a91c6cdc432c6e27936ad58362a7e3f48e4db76a71e040a3a55f3da"

  url "https://dl.valt0.com/v1/#{version}/valt0-darwin-#{arch}.zip"
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

  postflight_steps do
    if_path_exists "valt0.app/Contents/MacOS/valt0-agent", base: :appdir do
      run "valt0.app/Contents/MacOS/valt0-agent",
          args:         ["ensure", "--homebrew"],
          base:         :appdir,
          must_succeed: false,
          print_stdout: true
    end
  end

  uninstall_preflight_steps do
    if_path_exists "valt0.app/Contents/MacOS/valt0-agent", base: :appdir do
      run "valt0.app/Contents/MacOS/valt0-agent",
          args:         ["unregister"],
          base:         :appdir,
          must_succeed: false
    end
  end

  uninstall launchctl: "com.byte1620.valt0"

  zap trash: [
    "~/Library/Application Support/valt0",
    "~/Library/LaunchAgents/com.byte1620.valt0.plist",
    "~/Library/Logs/valt0",
    "~/Library/Preferences/com.byte1620.valt0.plist",
  ]
end
