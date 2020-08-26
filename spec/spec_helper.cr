require "spec"
require "../src/git-elpa"

MOCK_DIR = File.tempname(".emacs.d")

def cd_to_emacs_d
  Dir.cd(MOCK_DIR)
end

def create_mock_repo
  Dir.mkdir(MOCK_DIR)
  Dir.cd(MOCK_DIR)
  Dir.mkdir("elpa")
  Dir.cd("elpa")

  File.touch

  run_cmd("git", ["init"])
  run_cmd("git", ["add", "."])
  run_cmd("git", ["commit", "-m", "init_repo"])
end

def teardown_mock_repo
  Dir.delete MOCK_DIR
end
