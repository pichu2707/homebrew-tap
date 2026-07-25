class Oxidegate < Formula
  desc "Local proxy that measures the real context cost between AI agents and providers"
  homepage "https://github.com/pichu2707/OxideGate"
  url "https://github.com/pichu2707/OxideGate/archive/refs/tags/v0.3.1.tar.gz"
  sha256 "0aee04c0d10dba3b50cfcce534e144dc336c48c707688d5c728e9bb25f855488"
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
    # Both binaries must describe themselves without a running proxy and
    # without a TTY. Until 0.3.1 neither could: `oxidegate --help` panicked
    # with AddrInUse when an instance was already up, and the monitor died
    # with "No such device or address" whenever stdout was not a terminal —
    # which is exactly the case inside `brew test`.
    assert_match "OXIDEGATE_PORT", shell_output("#{bin}/oxidegate --help")
    assert_match "--once", shell_output("#{bin}/oxidegate-monitor --help")

    port = free_port

    pid = spawn({ "OXIDEGATE_PORT" => port.to_s }, bin/"oxidegate")
    begin
      # /health is the readiness gate AND the first assertion — no fixed sleep.
      # A `sleep N` is a bet that the machine running `brew test` is not slower
      # than the one N was tuned on; lose it and the failure reads as "the proxy
      # is broken" instead of "we did not wait". `--retry-connrefused` covers
      # the bind window, so this returns as soon as the proxy serves rather than
      # always paying the worst case; `--retry-max-time` keeps it bounded.
      #
      # /health earns the job: it is the cheapest route in the binary, touching
      # neither AppState nor the telemetry locks, so a 200 means "serving", not
      # merely "port open". And it is not decoration — clients gate their
      # decision to route through the proxy on this probe, so a build without it
      # makes them fall back to the provider silently. This formula shipped
      # 0.2.1 long after /health existed upstream and nothing caught it; `--fail`
      # turns that 404 into a non-zero exit, so now something does.
      probe = "curl --silent --fail --retry 30 --retry-delay 1 " \
              "--retry-connrefused --retry-max-time 30 --max-time 5"
      assert_match "ok", shell_output("#{probe} http://127.0.0.1:#{port}/health")

      # A freshly started proxy has served nothing, so /stats is an empty array.
      # /health deliberately avoids the telemetry locks, so this is a distinct
      # claim: the telemetry API itself answers, not just the liveness route.
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
