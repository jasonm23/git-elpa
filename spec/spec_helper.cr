require "file_utils"
require "spec"
require "../src/git-elpa"

MOCK_DIR = File.tempname(".emacs.d")

def cd_to_emacs_d
  Dir.cd(MOCK_DIR)
end

def create_mock_repo
  Dir.mkdir(MOCK_DIR)
  Dir.cd(MOCK_DIR)

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
    Dir.cd(MOCK_DIR)
    Dir.cd("elpa")
  end

  Dir.cd(MOCK_DIR)

end

def teardown_mock_repo
  FileUtils.rm_r(MOCK_DIR)
end
