class Aginxbrowser < Formula
  desc "Agent-first browser server: HTTP API + MCP, no Chromium"
  homepage "https://github.com/yinnho/aginxbrowser"
  license "Apache-2.0"

  if OS.mac? && Hardware::CPU.arm?
    url "https://github.com/yinnho/aginxbrowser/releases/download/v0.3.0/aginxbrowser-v0.3.0-aarch64-apple-darwin.tar.gz"
    sha256 "2eb87d8bc0b550f4d2d4bb5f55c117ac2d9ffa22e40f9c6b7b6cd983c0dada3c"
  elsif OS.linux? && Hardware::CPU.intel?
    url "https://github.com/yinnho/aginxbrowser/releases/download/v0.3.0/aginxbrowser-v0.3.0-x86_64-unknown-linux-gnu.tar.gz"
    sha256 "f6cc5a74b8561679256639954a9f82d75c980cead245656fa8ecc442be8c832e"
  else
    odie <<~EOS
      aginxbrowser ships prebuilt binaries for macOS arm64 and Linux x86_64.
      On macOS Intel the prebuilt asset was dropped: a V8 snapshot architecture
      defect made every prior Intel asset crash on launch. Build from source:
        git clone https://github.com/yinnho/aginxbrowser && cd aginxbrowser
        cargo build --release --features stealth,screenshot
    EOS
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
