class Aginxbrowser < Formula
  desc "Agent-first browser server: HTTP API over the diting engine, no Chromium"
  homepage "https://github.com/yinnho/aginxbrowser"
  license "Apache-2.0"

  if OS.mac? && Hardware::CPU.arm?
    url "https://github.com/yinnho/aginxbrowser/releases/download/v0.5.35/aginxbrowser-v0.5.35-aarch64-apple-darwin.tar.gz"
    sha256 "6fcaff724ab846022c3382b2b50fd0ebd57a06c3399106b6138a8c3389001391"
  elsif OS.linux? && Hardware::CPU.intel?
    url "https://github.com/yinnho/aginxbrowser/releases/download/v0.5.35/aginxbrowser-v0.5.35-x86_64-unknown-linux-gnu.tar.gz"
    sha256 "ffd6b956f752cc1d347eff02533f6231631915065b50c4bfce731c526f4f8eab"
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
        aginxbrowser                 # HTTP API on :8089 (REST + /v1/scrape + /flow/run)

      Bundled workflows (X, xhs, taobao/doudian publish & login, ...) live in
      the release tarball's workflow/ dir; drop them into ~/.aginxbrowser/workflow/.
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
