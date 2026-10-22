class Aginxbrowser < Formula
  desc "Agent-first browser server: HTTP API over the diting engine, no Chromium"
  homepage "https://github.com/yinnho/aginxbrowser"
  license "Apache-2.0"

  if OS.mac? && Hardware::CPU.arm?
    url "https://github.com/yinnho/aginxbrowser/releases/download/v0.6.2/aginxbrowser-v0.6.2-aarch64-apple-darwin.tar.gz"
    sha256 "64b2cd881d5fa27ff3dd65e9717069c301deb801f9a699dab8397dbb271fb35e"
  elsif OS.mac? && Hardware::CPU.intel?
    # Back as of v0.5.37: the release pipeline runs its whole toolchain as an
    # x86_64 host under Rosetta, so the baked V8 snapshot matches the target,
    # and the smoke step boots the real artifact before it ships.
    url "https://github.com/yinnho/aginxbrowser/releases/download/v0.6.2/aginxbrowser-v0.6.2-x86_64-apple-darwin.tar.gz"
    sha256 "d625701d01899d8e43a80c2b866e4dc91d64c5f16502cb9f92a83517c99067bc"
  elsif OS.linux? && Hardware::CPU.intel?
    url "https://github.com/yinnho/aginxbrowser/releases/download/v0.6.2/aginxbrowser-v0.6.2-x86_64-unknown-linux-gnu.tar.gz"
    sha256 "6f4fcd83fd25dafbac2c2676e6a794535b5aedac78e823515a534af09facfcb6"
  else
    odie <<~EOS
      aginxbrowser ships prebuilt binaries for macOS (arm64 and Intel) and
      Linux x86_64. Build from source on anything else:
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
