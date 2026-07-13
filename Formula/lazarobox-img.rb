class LazaroboxImg < Formula
  desc "Image optimizer and EXIF metadata editor with CLI and TUI"
  homepage "https://github.com/pichu2707/lazarobox-img"
  url "https://github.com/pichu2707/lazarobox-img/archive/refs/tags/v0.4.3.tar.gz"
  sha256 "8cf1d4ea46e5fa29483f55fc693871225819a2f1e2e197382d76d3b31893c8bf"
  license "MIT"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    system "#{bin}/lazarobox-img", "--help"
  end
end
