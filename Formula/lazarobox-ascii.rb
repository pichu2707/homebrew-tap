class LazaroboxAscii < Formula
  desc "Image-to-terminal art converter (ASCII, Braille, blocks) with CLI and TUI"
  homepage "https://github.com/pichu2707/lazaro-ascii"
  url "https://github.com/pichu2707/lazaro-ascii/archive/refs/tags/v0.2.0.tar.gz"
  sha256 "0bf87ecc580308cd1341954c0576a4ca82c988845c3b9953bfb9ecf32b027efd"
  license "MIT"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match "lazarobox-ascii", shell_output("#{bin}/lazarobox-ascii --version")
  end
end
