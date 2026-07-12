class Oxidegate < Formula
  desc "Local proxy that measures the real context cost between AI agents and providers"
  homepage "https://github.com/pichu2707/OxideGate"
  url "https://github.com/pichu2707/OxideGate/archive/refs/tags/v0.2.1.tar.gz"
  sha256 "41b99112e30bf81a33dc87fe52fe13b6daabc192d5b004b73a210759d12f267a"
  license "MIT"
  head "https://github.com/pichu2707/OxideGate.git", branch: "main"

  depends_on "pkg-config" => :build
  depends_on "rust" => :build
  # `reqwest` links against the system TLS stack (openssl-sys). Without these
  # two, the build dies in openssl-sys's build script — which no `brew audit`
  # catches, because it only shows up when you actually compile.
  depends_on "openssl@3"

  def install
    # Point openssl-sys at Homebrew's OpenSSL instead of letting it hunt the
    # system (or vendor its own copy, which would bloat the build).
    ENV["OPENSSL_DIR"] = Formula["openssl@3"].opt_prefix
    ENV["OPENSSL_NO_VENDOR"] = "1"

    # Only the two user-facing binaries. `oxidegate-bench` is a development
    # tool for controlled benchmark sweeps — it has no business in anyone's
    # PATH, so it is deliberately not installed.
    system "cargo", "install", "--bin", "oxidegate", "--bin", "oxidegate-monitor", *std_cargo_args
  end

  def caveats
    <<~EOS
      Point your client at the proxy and it will measure every request:

        export ANTHROPIC_BASE_URL=http://127.0.0.1:8080

      Live dashboard:  oxidegate-monitor
      One-off snapshot: oxidegate-monitor --once

      Telemetry is written to ~/.config/oxidegate/telemetry.jsonl

      Note: routing a harness that defers its MCP tool schemas (Claude Code does)
      through ANY non-first-party ANTHROPIC_BASE_URL makes it fall back to
      loading them all upfront. OxideGate is such a base URL, so some of the
      bytes it reports exist because it is in the path. See §3 of
      docs/optimizer-tool-search.md — it is measured, not speculated.
    EOS
  end

  test do
    port = free_port

    pid = spawn({ "OXIDEGATE_PORT" => port.to_s }, bin/"oxidegate")
    begin
      # Give the listener time to bind before asserting against it.
      sleep 3

      # A freshly started proxy has served nothing, so /stats is an empty array.
      # This proves the binary starts, binds the port and serves its own API.
      output = shell_output("curl --silent --max-time 5 http://127.0.0.1:#{port}/stats")
      assert_equal "[]", output.strip

      # And that the TUI binary can talk to it headlessly.
      system bin/"oxidegate-monitor", "--once", "--url", "http://127.0.0.1:#{port}/stats"
    ensure
      Process.kill("TERM", pid)
      Process.wait(pid)
    end
  end
end
