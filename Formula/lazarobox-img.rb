class LazaroboxImg < Formula
  desc "Image optimizer and EXIF metadata editor with CLI and TUI"
  homepage "https://github.com/pichu2707/lazarobox-img"
  url "https://github.com/pichu2707/lazarobox-img/archive/refs/tags/v0.5.0.tar.gz"
  sha256 "60c06384de2f2d90139650d4a7a60d1dd8416c7f6ac7b405022f280691dc9630"
  license "MIT"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    system "#{bin}/lazarobox-img", "--help"
  end
end
