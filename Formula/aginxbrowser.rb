class Aginxbrowser < Formula
  desc "Agent-first browser server: HTTP API + MCP, no Chromium"
  homepage "https://github.com/yinnho/aginxbrowser"
  license "Apache-2.0"

  if OS.mac? && Hardware::CPU.arm?
    url "https://github.com/yinnho/aginxbrowser/releases/download/v0.2.7/aginxbrowser-v0.2.7-aarch64-apple-darwin.tar.gz"
    sha256 "27e680d95998a9df16d690918127fcf4e4c93c68e2caf50d9f57b337baef9a72"
  elsif OS.mac? && Hardware::CPU.intel?
    url "https://github.com/yinnho/aginxbrowser/releases/download/v0.2.7/aginxbrowser-v0.2.7-x86_64-apple-darwin.tar.gz"
    sha256 "c066be4e7d33a020e9f1d48013fa80c98a9e486926907693afbcffd1a58899a8"
  elsif OS.linux? && Hardware::CPU.intel?
    url "https://github.com/yinnho/aginxbrowser/releases/download/v0.2.7/aginxbrowser-v0.2.7-x86_64-unknown-linux-gnu.tar.gz"
    sha256 "6f053dbd11c98c99786dc99de2d2d6791e60e981bb54630d779674dae5d839a7"
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
