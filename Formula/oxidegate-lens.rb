class OxidegateLens < Formula
  desc "Read-only report over OxideGate: what each MCP server costs on the wire"
  homepage "https://github.com/pichu2707/oxidegate-lens"
  url "https://github.com/pichu2707/oxidegate-lens/archive/refs/tags/v0.2.1.tar.gz"
  sha256 "d12f5595076d6a90ef860e119aad9806fe3312fcebea7df1d0ed58c76cd5c9d6"
  license "MIT"
  head "https://github.com/pichu2707/oxidegate-lens.git", branch: "main"

  depends_on "node"

  def install
    # Zero runtime dependencies by design, so there is nothing to `npm install`.
    # The whole tree goes to libexec because bin/*.mjs imports ../lib/ by
    # relative path — flattening it would break that import.
    libexec.install "bin", "lib", "package.json", "README.md", "LICENSE"

    bin.install_symlink libexec/"bin/oxidegate-savings.mjs" => "oxidegate-savings"
    bin.install_symlink libexec/"bin/oxidegate-status.mjs" => "oxidegate-status"
  end

  def caveats
    <<~EOS
      Needs a running OxideGate (brew install pichu2707/tap/oxidegate).
      Set OXIDEGATE_PORT if the proxy is not on the default 8080.

        oxidegate-savings   what each MCP server weighs on the wire
        oxidegate-status    one-line summary, for a status bar

      Version contract: this release reads `deferred_tools`, which OxideGate
      emits from 0.2.0 onwards. Against an older proxy it does NOT break — the
      field is simply absent, and the report says so. An absent value is never
      shown as a zero. That degradation is covered by tests, not promised.

      The "available vs. arrived" block runs `claude mcp list` to read the MCP
      servers you have configured. Without the `claude` command the rest of the
      report still works; that block says it could not read your config, which
      is different from saying you have none.
    EOS
  end

  test do
    # There is no proxy running here, so the report must fail cleanly with a
    # message rather than crash. This exercises the fragile part of the install:
    # Node resolving `../lib/mcp-config.mjs` from the symlinked entry point.
    output = shell_output("#{bin}/oxidegate-savings 2>&1", 1)
    assert_match "oxidegate-lens", output

    # The status line degrades silently by design — it must exit 0 with no proxy,
    # because a status bar that errors out on every redraw is worse than useless.
    system bin/"oxidegate-status"
  end
end
