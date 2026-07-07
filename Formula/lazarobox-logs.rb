class LazaroboxLogs < Formula
  desc "Real-time server log analyzer with a cyberpunk TUI"
  homepage "https://github.com/pichu2707/lazarobox-logs"
  url "https://github.com/pichu2707/lazarobox-logs/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "8489b530189e1b84eba98ffbf25c8497cc3a92dc8b389302a2bbb0f1ebcfcc51"
  license "MIT"

  depends_on "pkg-config" => :build
  depends_on "rust" => :build
  depends_on "openssl@3"

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match "lazarobox-logs", shell_output("#{bin}/lazarobox-logs --version")
  end
end
