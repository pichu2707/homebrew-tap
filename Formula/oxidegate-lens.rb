class OxidegateLens < Formula
  desc "Read-only report over OxideGate: what each MCP server costs on the wire"
  homepage "https://github.com/pichu2707/oxidegate-lens"
  url "https://github.com/pichu2707/oxidegate-lens/archive/refs/tags/v0.5.0.tar.gz"
  sha256 "b0785f14e4fe2c2ffaf31412f8e350d6dada690b3e8c6113f16dee0cd28b9338"
  license "MIT"
  head "https://github.com/pichu2707/oxidegate-lens.git", branch: "main"

  depends_on "node"

  def install
    # Zero runtime dependencies by design, so there is nothing to `npm install`.
    # The whole tree goes to libexec because bin/*.mjs imports ../lib/ by
    # relative path — flattening it would break that import.
    #
    # `opencode` and `examples` ship too. Leaving them out was not a saving:
    # the OpenCode plugin is where the MCP valve tools live, so a formula
    # without it installed the report and withheld the thing the report is
    # meant to act on. The only way to get the plugin was to clone the repo.
    libexec.install "bin", "lib", "opencode", "examples", "package.json", "README.md", "LICENSE"

    bin.install_symlink libexec/"bin/oxidegate-savings.mjs" => "oxidegate-savings"
    bin.install_symlink libexec/"bin/oxidegate-mcp.mjs" => "oxidegate-mcp"
  end

  def caveats
    <<~EOS
      Needs a running OxideGate (brew install pichu2707/tap/oxidegate).

      Do NOT run the proxy on its default port 8080 — Apache, Tomcat and
      friends usually own it, and this report would then be reading someone
      else's web server. Pick a free port and export it here too:

        OXIDEGATE_PORT=8899 oxidegate-savings

        oxidegate-savings   what each MCP server weighs on the wire
        oxidegate-mcp       pick which MCP servers survive startup, with each
                            one's measured price next to it

      `oxidegate-mcp` needs no OxideGate and no OpenCode: the configuration
      belongs to you, not to the harness, so it works the same under OpenCode,
      pi, or whatever comes next. What it CANNOT do is connect or disconnect a
      RUNNING session — that needs the harness SDK and lives in the plugin.

      To get the MCP valve inside OpenCode, add the installed plugin to your
      opencode.json — it is not picked up automatically:

        {
          "plugin": ["#{opt_libexec}/opencode/oxidegate-lens.ts"],
          "agent": {
            "build": {
              "tools": {
                "oxidegate_lens_mcp_valve": true,
                "oxidegate_lens_mcp_connect": true,
                "oxidegate_lens_mcp_disconnect": true
              }
            }
          }
        }

      See #{opt_libexec}/examples/opencode.json for the provider block that
      actually routes traffic through the proxy. Without routing there is
      nothing to report on: the valve will keep saying it has not observed
      enough to judge, which is the honest answer, not a bug.

      BREAKING in 0.3.0: those three tools dropped their `experimental_`
      prefix. A config still naming oxidegate_lens_experimental_mcp_status
      (or _connect / _disconnect) silently gets none of them — the old names
      no longer exist.

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

    # Both binaries must describe themselves with no TTY, which is exactly the
    # case inside `brew test`. This is the failure mode that shipped in
    # OxideGate for two releases: a TUI binary that died with "No such device
    # or address" the moment stdout was not a terminal.
    assert_match "oxidegate-mcp", shell_output("#{bin}/oxidegate-mcp --help")

    # With a sandboxed HOME there is no mcp-savings snapshot, so the selector
    # has no inventory. It must EXPLAIN that and exit 1 — never draw an empty
    # table, which would read as "you have no MCP servers". That distinction is
    # the whole point of the module behind it.
    no_inventory = shell_output("#{bin}/oxidegate-mcp 2>&1", 1)
    assert_match "mcp-savings", no_inventory

    # The plugin must actually be on disk. This formula shipped for two
    # releases without it while package.json listed it under `files`, so
    # nothing disagreed loudly enough to notice. Assert it, because the
    # failure mode is a user following the caveats to a path that is not there.
    assert_path_exists libexec/"opencode/oxidegate-lens.ts"
    assert_path_exists libexec/"examples/opencode.json"

    # The lib modules the valve is built from are imported by relative path at
    # runtime, so a partial install would only fail once someone ran section (d).
    assert_path_exists libexec/"lib/mcp-valve.mjs"
    assert_path_exists libexec/"lib/mcp-config-editor.mjs"
  end
end
