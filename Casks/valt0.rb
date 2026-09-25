cask "valt0" do
  arch arm: "arm64", intel: "amd64"

  version "0.0.57-pre"
  sha256 arm:   "d3be1b17fe66b27332c5543a3e816743d565aa01110756dbe99ba274f56fc50a",
         intel: "6779d6d0750e49efc04cd6750d39438d31717da1718ac7fba16c5d51c4a0bd79"

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

  generated_script "valt0-install.sh", content: <<~SH
    #!/bin/sh
    set -eu

    src="#{staged_path}/valt0.app"
    dst="#{appdir}/valt0.app"

    if [ -e "$dst" ]; then
      echo "Error: $dst already exists (not installed by this cask)." >&2
      echo "Move it to the Trash, then run the install again." >&2
      exit 1
    fi

    mkdir -p "#{appdir}"
    /usr/bin/ditto "$src" "$dst"

    if [ -n "${HOMEBREW_VALT0_NO_SERVICE:-}" ]; then
      echo "==> Skipping background service setup (HOMEBREW_VALT0_NO_SERVICE is set)."
      exit 0
    fi

    agent="$dst/Contents/MacOS/valt0-agent"
    if [ ! -x "$agent" ]; then
      echo "Warning: valt0-agent is missing from the app bundle; service not started." >&2
      exit 0
    fi

    # A failed registration must not fail the install: the app is in place
    # and the user can enable the service from its window.
    err="$(mktemp)"
    status="$("$agent" ensure 2>"$err")" || true

    case "$status" in
      enabled)
        echo "==> valt0 background service is running."
        ;;
      requires-approval)
        echo "Warning: valt0 is installed but its background service is turned off." >&2
        echo "Enable it in System Settings > General > Login Items & Extensions." >&2
        ;;
      *)
        echo "Warning: could not start the valt0 background service: $(cat "$err")" >&2
        echo "Open valt0 from your Applications folder and click \\"Enable Service\\"." >&2
        ;;
    esac
    rm -f "$err"
  SH

  generated_script "valt0-uninstall.sh", content: <<~SH
    #!/bin/sh
    agent="#{appdir}/valt0.app/Contents/MacOS/valt0-agent"
    if [ -x "$agent" ]; then
      "$agent" unregister >/dev/null 2>&1 || true
    fi
    exit 0
  SH

  installer script: "valt0-install.sh"
  binary "#{appdir}/valt0.app/Contents/MacOS/valt0"

  uninstall launchctl: "com.byte1620.valt0",
            script:    {
              executable:   "valt0-uninstall.sh",
              must_succeed: false,
            },
            delete:    "#{appdir}/valt0.app"

  zap trash: [
    "~/Library/Application Support/valt0",
    "~/Library/LaunchAgents/com.byte1620.valt0.plist",
    "~/Library/Logs/valt0",
    "~/Library/Preferences/com.byte1620.valt0.plist",
  ]
end
