class Aginxbrowser < Formula
  desc "Agent-first browser server: HTTP API + MCP, no Chromium"
  homepage "https://github.com/yinnho/aginxbrowser"
  license "Apache-2.0"

  if OS.mac? && Hardware::CPU.arm?
    url "https://github.com/yinnho/aginxbrowser/releases/download/v0.2.3/aginxbrowser-v0.2.3-aarch64-apple-darwin.tar.gz"
    sha256 "82d1ad670433aa8ab08032365050debe7721a4b7971dedd88d3901bfcbf5cb29"
  elsif OS.mac? && Hardware::CPU.intel?
    url "https://github.com/yinnho/aginxbrowser/releases/download/v0.2.3/aginxbrowser-v0.2.3-x86_64-apple-darwin.tar.gz"
    sha256 "be237fdffb59bb0bcd8376946cce9efa7545e54f773b740fd917d97cad11118f"
  elsif OS.linux? && Hardware::CPU.intel?
    url "https://github.com/yinnho/aginxbrowser/releases/download/v0.2.3/aginxbrowser-v0.2.3-x86_64-unknown-linux-gnu.tar.gz"
    sha256 "5c1c115a0703088abf4ff1d6e4186d0cf02c610b73b0aeae305e44751bc9468e"
  else
    odie "aginxbrowser only ships prebuilt binaries for macOS arm64/intel and Linux x86_64"
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
        rescue
          next
        end
      end
      flunk "server did not bind within 90s" unless ok
      body = `curl -fsS http://127.0.0.1:#{port}/health`
      assert_match(/"status":"ok"/, body)
    ensure
      begin
        Process.kill("TERM", pid)
      rescue Errno::ESRCH
      end
      begin
        Process.wait(pid)
      rescue Errno::ECHILD
      end
    end
  end
end
