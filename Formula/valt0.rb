class Valt0 < Formula
  desc "Encrypted secrets vault with background sync daemon"
  homepage "https://valt0.com"
  version "0.0.24-pre"
  license "MIT"

  on_arm do
    url "https://dl.valt0.com/v1/#{version}/valt0-darwin-arm64.zip"
    sha256 "ce8d61a5390223ba02877e663c784f2e7d9033392d77c6983e7a87cdee537a9a"
  end

  # on_intel do
  #   url "https://github.com/byte1620/valt0/releases/download/v#{version}/valt0-#{version}-x86_64.zip"
  #   sha256 "0000000000000000000000000000000000000000000000000000000000000000"
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
