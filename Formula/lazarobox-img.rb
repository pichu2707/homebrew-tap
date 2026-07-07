class LazaroboxImg < Formula
  desc "Image optimizer and EXIF metadata editor with CLI and TUI"
  homepage "https://github.com/pichu2707/lazarobox-img"
  url "https://github.com/pichu2707/lazarobox-img/archive/refs/tags/v0.4.2.tar.gz"
  sha256 "80259dc0d2095c7764e0a146696b346fb79896c5b323162bf6b94ca0e9e7772c"
  license "MIT"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    system "#{bin}/lazarobox-img", "--help"
  end
end
