class LazaroboxImg < Formula
  desc "Image optimizer and EXIF metadata editor with CLI and TUI"
  homepage "https://github.com/pichu2707/lazarobox-img"
  url "https://github.com/pichu2707/lazarobox-img/archive/refs/tags/v0.5.1.tar.gz"
  sha256 "6ee63b0133fd1a895f9d35c6117a5f13863472e8b6f557893e8df9034e72b523"
  license "MIT"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    system "#{bin}/lazarobox-img", "--help"
  end
end
