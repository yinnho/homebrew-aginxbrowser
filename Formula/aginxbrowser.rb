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
    server = TCPServer.new("127.0.0.1", port)
    server.close

    pid = spawn({ "AGINXBROWSER_BIND" => "127.0.0.1:#{port}" }, "#{bin}/aginxbrowser", err: "/dev/null")
    begin
      ok = false
      90.times do
        sleep 1
        begin
          s = TCPSocket.new("127.0.0.1", port)
          s.close
          ok = true
          break
        rescue StandardError
          next
        end
      end
      flunk "server did not bind within 90s" unless ok
      body = `curl -fsS http://127.0.0.1:#{port}/health`
      assert_match %r{"status":"ok"}, body
    ensure
      Process.kill("TERM", pid) rescue nil
      Process.wait(pid) rescue nil
    end
  end
end
