class Aginxbrowser < Formula
  desc "Agent-first browser server: HTTP API + MCP, no Chromium"
  homepage "https://github.com/yinnho/aginxbrowser"
  license "Apache-2.0"

  if OS.mac? && Hardware::CPU.arm?
    url "https://github.com/yinnho/aginxbrowser/releases/download/v0.2.4/aginxbrowser-v0.2.4-aarch64-apple-darwin.tar.gz"
    sha256 "d5d194f6c05b5f6593d31c023162d489f6b10034578457d6d4d32f1f63485386"
  elsif OS.mac? && Hardware::CPU.intel?
    url "https://github.com/yinnho/aginxbrowser/releases/download/v0.2.4/aginxbrowser-v0.2.4-x86_64-apple-darwin.tar.gz"
    sha256 "32e92ee388b624776da666cb3b6ea3a41c957c1b9595985e8119b9b3ed95910a"
  elsif OS.linux? && Hardware::CPU.intel?
    url "https://github.com/yinnho/aginxbrowser/releases/download/v0.2.4/aginxbrowser-v0.2.4-x86_64-unknown-linux-gnu.tar.gz"
    sha256 "52b4adad7fe99df6d89b1b83322fa2ba999e580af47548e59a01ffe347ab044a"
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
        nil
      end
      begin
        Process.wait(pid)
      rescue Errno::ECHILD
        nil
      end
    end
  end
end
