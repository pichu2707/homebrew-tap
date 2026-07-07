class LazaroboxImg < Formula
  desc "Image optimizer and EXIF metadata editor with CLI and TUI"
  homepage "https://github.com/pichu2707/lazarobox-img"
  url "https://github.com/pichu2707/lazarobox-img/archive/refs/tags/v0.4.1.tar.gz"
  sha256 "0b376db9d0cd9860b28d2688242f7f2e56850682adc453115dba91ad77f3b4f8"
  license "MIT"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    system "#{bin}/lazarobox-img", "--help"
  end
end
