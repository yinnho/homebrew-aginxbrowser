class Aginxbrowser < Formula
  desc "Agent-first browser server: HTTP API over the diting engine, no Chromium"
  homepage "https://github.com/yinnho/aginxbrowser"
  license "Apache-2.0"

  if OS.mac? && Hardware::CPU.arm?
    url "https://github.com/yinnho/aginxbrowser/releases/download/v0.5.39/aginxbrowser-v0.5.39-aarch64-apple-darwin.tar.gz"
    sha256 "1e69704e4616758825ff3b123c7da738e0f0740c8d3b4f87df94bced96e5bb78"
  elsif OS.mac? && Hardware::CPU.intel?
    # Back as of v0.5.37: the release pipeline runs its whole toolchain as an
    # x86_64 host under Rosetta, so the baked V8 snapshot matches the target,
    # and the smoke step boots the real artifact before it ships.
    url "https://github.com/yinnho/aginxbrowser/releases/download/v0.5.39/aginxbrowser-v0.5.39-x86_64-apple-darwin.tar.gz"
    sha256 "ec6a440e644716beb4830ac6a7f73a4019be962a68f9e0831fd60a2190f575ea"
  elsif OS.linux? && Hardware::CPU.intel?
    url "https://github.com/yinnho/aginxbrowser/releases/download/v0.5.39/aginxbrowser-v0.5.39-x86_64-unknown-linux-gnu.tar.gz"
    sha256 "bac28059d489d122687f712586314824a59d317c52ab7b587cf16f717c96772c"
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
