class LazaroboxAscii < Formula
  desc "ASCII tool from Lazaro"
  homepage "https://github.com/pichu2707/lazaro-ascii"
  url "https://github.com/pichu2707/lazaro-ascii/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "e68fd3d7c93ff5ed666f136f06cdcfd48093ad9152cb6d3214c212db720df477"
  license "MIT"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end
    test do
    system "#{bin}/lazarobox-ascii", "--help"
  end
end
