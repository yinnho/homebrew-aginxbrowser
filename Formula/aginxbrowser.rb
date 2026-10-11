class Aginxbrowser < Formula
  desc "Agent-first browser server: HTTP API over the diting engine, no Chromium"
  homepage "https://github.com/yinnho/aginxbrowser"
  license "Apache-2.0"

  if OS.mac? && Hardware::CPU.arm?
    url "https://github.com/yinnho/aginxbrowser/releases/download/v0.5.40/aginxbrowser-v0.5.40-aarch64-apple-darwin.tar.gz"
    sha256 "2e4603325875993ee4c17020d64d08e56175a454cdd4611a7c114561a9b5e1f0"
  elsif OS.mac? && Hardware::CPU.intel?
    # Back as of v0.5.37: the release pipeline runs its whole toolchain as an
    # x86_64 host under Rosetta, so the baked V8 snapshot matches the target,
    # and the smoke step boots the real artifact before it ships.
    url "https://github.com/yinnho/aginxbrowser/releases/download/v0.5.40/aginxbrowser-v0.5.40-x86_64-apple-darwin.tar.gz"
    sha256 "56a14b2981b8ea74b05e47244e51b5b48d57e50a7d18c6577c5ae969afe48bb7"
  elsif OS.linux? && Hardware::CPU.intel?
    url "https://github.com/yinnho/aginxbrowser/releases/download/v0.5.40/aginxbrowser-v0.5.40-x86_64-unknown-linux-gnu.tar.gz"
    sha256 "7c3b60e787fb6505a7e39e9d86a1f5365815f051540cd8b688379941a4fc2624"
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
