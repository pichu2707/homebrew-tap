class Oxidegate < Formula
  desc "Local proxy that measures the real context cost between AI agents and providers"
  homepage "https://github.com/pichu2707/OxideGate"
  url "https://github.com/pichu2707/OxideGate/archive/refs/tags/v0.3.0.tar.gz"
  sha256 "4ab877749f0c7808b11737ad25be17d0cf19d176e8f625567728149601494042"
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
    ENV["OPENSSL_DIR"] = formula_opt_prefix("openssl@3")
    ENV["OPENSSL_NO_VENDOR"] = "1"

    # Only the two user-facing binaries. `oxidegate-bench` is a development
    # tool for controlled benchmark sweeps — it has no business in anyone's
    # PATH, so it is deliberately not installed.
    system "cargo", "install", "--bin", "oxidegate", "--bin", "oxidegate-monitor", *std_cargo_args
  end

  def caveats
    <<~EOS
      Point your client at the proxy and it will measure every request.

      Do NOT leave the proxy on its default port 8080 — Apache, Tomcat and
      friends usually own it, and a client that ends up talking to someone
      else's web server is worse off than one with no proxy at all. Pick a
      free port and use that same one everywhere:

        OXIDEGATE_PORT=8899 oxidegate
        export ANTHROPIC_BASE_URL=http://127.0.0.1:8899

      Live dashboard:  oxidegate-monitor
      One-off snapshot: oxidegate-monitor --once

      From 0.3.0 the proxy serves GET /health, a cheap liveness route that
      touches neither AppState nor the telemetry locks. Clients that decide
      whether to route through the proxy probe it first, so against an older
      build that probe 404s and they fall back to talking to the provider
      directly — silently, by design. If traffic is not showing up, check
      `curl http://127.0.0.1:$OXIDEGATE_PORT/health` before anything else.

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

      # /health must answer 200. This is not decoration: clients gate their
      # decision to route through the proxy on this probe, and a probe that
      # 404s makes them fall back to the provider directly — with no error,
      # no log, and an empty report the user cannot explain. This formula
      # shipped 0.2.1 (no /health) long after the route existed upstream, and
      # nothing caught it. Now something does.
      # `--fail` turns a 404 into a non-zero exit, which makes shell_output
      # raise — so a stale build fails here rather than returning a body we
      # would then have to parse.
      health = shell_output("curl --silent --fail --max-time 5 http://127.0.0.1:#{port}/health")
      assert_match "ok", health

      # And that the TUI binary can talk to it headlessly.
      system bin/"oxidegate-monitor", "--once", "--url", "http://127.0.0.1:#{port}/stats"
    ensure
      Process.kill("TERM", pid)
      Process.wait(pid)
    end
  end
end
