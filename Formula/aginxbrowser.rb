class Aginxbrowser < Formula
  desc "Agent-first browser server: HTTP API + MCP, no Chromium"
  homepage "https://github.com/yinnho/aginxbrowser"
  version "0.2.1"
  license "Apache-2.0"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/yinnho/aginxbrowser/releases/download/v0.2.1/aginxbrowser-v0.2.1-aarch64-apple-darwin.tar.gz"
      sha256 "a75641c668997dbbc2ac7fc2cab65c0f55324a098f62f5da8e6a1e80a0b7bdcb"
    else
      url "https://github.com/yinnho/aginxbrowser/releases/download/v0.2.1/aginxbrowser-v0.2.1-x86_64-apple-darwin.tar.gz"
      sha256 "e59b7f83b99d6eace3c1d79368bdf0997ed2ce2724ac15da61e36e3dc3f7224e"
    end
  end

  on_linux do
    url "https://github.com/yinnho/aginxbrowser/releases/download/v0.2.1/aginxbrowser-v0.2.1-x86_64-unknown-linux-gnu.tar.gz"
    sha256 "e3aca5a9d5c106e8c95e75f50f0682916e1df2309de043ade10d970c29a822eb"
  end

  def install
    bin.install "aginxbrowser"
    doc.install "README.md", "install.md"
  end

  def caveats
    <<~EOS
      Run the server:
        aginxbrowser                 # HTTP API on :8089 (REST + CDP + /v1/scrape)
        aginxbrowser --mcp           # native MCP over stdio

      Register with Claude / Cursor (hosted instance):
        claude mcp add aginxbrowser --transport http https://browser.aginx.net/mcp
    EOS
  end

  test do
    require "socket"
    port = free_port
    env = { "AGINXBROWSER_BIND" => "127.0.0.1:#{port}" }
    pid = spawn(env, "#{bin}/aginxbrowser")
    begin
      # The binary warms up V8 before binding; poll the health endpoint.
      ok = false
      60.times do
        sleep 1
        begin
          body = File.popen("curl -fsS http://127.0.0.1:#{port}/health 2>/dev/null", &:read)
          ok = !body.to_s.empty?
          break if ok
        rescue StandardError
          next
        end
      end
      assert_match "ok", `curl -fsS http://127.0.0.1:#{port}/health`
    ensure
      Process.kill("TERM", pid) rescue nil
      Process.wait(pid) rescue nil
    end
  end
end
