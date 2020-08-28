require "file_utils"
require "spec"
require "../src/git-elpa"

FAKE_DIR = File.tempname(".emacs.d")

# Spy on logs
def log(str)
  "#{ANSI_MESSAGE}#{str}#{ANSI_RESET}"
end

def log_warning(str)
  "#{ANSI_WARNING}#{str}#{ANSI_RESET}"
end

def log_error(str)
  "#{ANSI_WARNING}#{str}#{ANSI_RESET}"
end

# Fake emacs_d
def cd_to_emacs_d
  Dir.cd(FAKE_DIR)
end

def create_mock_repo
  Dir.mkdir(FAKE_DIR)
  Dir.cd(FAKE_DIR)

  run_cmd("git", ["init"])

  Dir.mkdir("elpa")
  Dir.cd("elpa")
  File.touch("README.md")

  run_cmd("git", ["add", "."])
  run_cmd("git", ["commit", "-m", "init_repo"])

  [
    "FakePackageOne",
    "FakePackageTwo",
    "FakePackageThree",
    "FakePackageFour"
  ].each do |package|
    folder_name = "#{package}-0.1.0"
    Dir.mkdir(folder_name)
    Dir.cd(folder_name)
    [
      "#{package}.el",
      "#{package}-pkg.el",
      "#{package}-autoloads.el",
      "#{package}.elc"
    ].each do |file|
      File.touch(file)
    end
    Dir.cd(FAKE_DIR)
    Dir.cd("elpa")
  end

  Dir.cd(FAKE_DIR)

end

def teardown_mock_repo
  FileUtils.rm_r(FAKE_DIR)
end
