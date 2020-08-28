require "file_utils"
require "spec"
require "../src/git-elpa"

FAKE_DIR = File.tempname(".emacs.d")

class String
  def kebab
    underscore.tr("_", "-")
  end
end

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

def elpa_dir_entries
  cd_to_emacs_d
  Dir.entries("elpa")
end

def elpa_git_status_s
  cd_to_emacs_d
  run_cmd("git", ["status", "-s"])[1]
end

def elpa_git_log
  cd_to_emacs_d
  run_cmd("git", ["log", "--oneline"])[1]
end

def elpa_tree
  cd_to_emacs_d
  run_cmd("tree", [] of String)[1]
end

def remove_old_package_fake(name : String, version : String)
  cd_to_emacs_d
  Dir.cd("elpa")
  package_folder = "#{name}-#{version}"
  FileUtils.rm_r package_folder
end

def create_new_package_fake(name : String, version : String)
  # To be run from elpa folder
  cd_to_emacs_d
  Dir.cd("elpa")

  package_folder = "#{name}-#{version}"
  file_name = name.kebab
  Dir.mkdir(package_folder)
  Dir.cd(package_folder)
  [
    "#{file_name}.el",
    "#{file_name}-pkg.el",
    "#{file_name}-autoloads.el",
    "#{file_name}.elc"
  ].each do |file|
    File.touch(file)
  end
  Dir.cd("..")

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
    create_new_package_fake(package, "0.1.0")
  end

  Dir.cd(FAKE_DIR)
end

def teardown_mock_repo
  Dir.cd(__DIR__)
  FileUtils.rm_r(FAKE_DIR) if Dir.exists?(FAKE_DIR)
end
