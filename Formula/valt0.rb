class Valt0 < Formula
  desc "Encrypted secrets vault with background sync daemon"
  homepage "https://valt0.com"
  version "0.0.38-pre"
  license "MIT"

  on_arm do
    url "https://dl.valt0.com/v1/#{version}/valt0-darwin-arm64.zip"
    sha256 "efa8da23c92bc654731c8334a82858dad8d0e05995219e7a43883803935d8e5b"
  end

  # on_intel do
  #   url "https://dl.valt0.com/v1/#{version}/valt0-darwin-x86_64.zip"
  #   sha256 "__SHA256_INTEL__"
  # end

  depends_on macos: :ventura

  livecheck do
    url "https://dl.valt0.com/v1/"
    regex(%r{href=.*?v?(\d+(?:\.\d+)+(?:-pre)?)/}i)
  end

  def install
    if (buildpath/"Contents/MacOS").directory?
      (libexec/"valt0.app").install Dir["*"]
    else
      libexec.install "valt0.app"
    end

    rm_rf libexec/"valt0.app/__MACOSX"
    bin.write_exec_script libexec/"valt0.app/Contents/MacOS/valt0"

    (prefix/"com.byte1620.valt0.plist").write <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>AssociatedBundleIdentifiers</key>
        <array>
          <string>com.byte1620.valt0</string>
        </array>
        <key>KeepAlive</key>
        <dict>
          <key>SuccessfulExit</key>
          <false/>
        </dict>
        <key>Label</key>
        <string>com.byte1620.valt0</string>
        <key>ProcessType</key>
        <string>Background</string>
        <key>ProgramArguments</key>
        <array>
          <string>#{opt_libexec}/valt0.app/Contents/MacOS/valt0</string>
          <string>agent</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>StandardOutPath</key>
        <string>#{var}/log/valt0.log</string>
        <key>StandardErrorPath</key>
        <string>#{var}/log/valt0.log</string>
      </dict>
      </plist>
    XML
  end

  service do
    name macos: "com.byte1620.valt0"
  end

  def caveats
    <<~EOS
      To start valt0 now and at every login:
        brew services start valt0
    EOS
  end

  test do
    assert_match "valt0 version", shell_output("#{bin}/valt0 --version")
  end
end
