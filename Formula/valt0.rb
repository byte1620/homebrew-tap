class Valt0 < Formula
  desc "Encrypted secrets vault with background sync daemon"
  homepage "https://valt0.com"
  version "latest"
  license "MIT"

  on_arm do
    url "https://dl.valt0.com/v1/#{version}/valt0-darwin-arm64.zip"
  end

  # on_intel do
  #   url "https://github.com/byte1620/valt0/releases/download/v#{version}/valt0-#{version}-x86_64.zip"
  #   sha256 "0000000000000000000000000000000000000000000000000000000000000000"
  # end

  depends_on macos: :ventura

  livecheck do
    url :stable
    strategy :github_latest
  end

  def install
    libexec.install "valt0.app"
    bin.install_symlink libexec/"valt0.app/Contents/MacOS/valt0"
  end

  service do
    run [opt_libexec/"valt0.app/Contents/MacOS/valt0", "agent"]
    run_type :immediate
    keep_alive successful_exit: false
    restart_delay 10
    process_type :background
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
