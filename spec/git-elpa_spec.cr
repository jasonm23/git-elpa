require "./spec_helper"

describe Git::Elpa do

  before_each do
  end

  after_each do
  end

  describe "check mocks" do
    it "sets up spec/.emacs.d as a mock environment" do
      cd_to_emacs_d

      current_dir = Dir.current
      expected_dir = MOCK_DIR

      current_dir.should eq expected_dir
    end
  end

  describe Git::Elpa::GitElpa do

    git_elpa : Git::Elpa::GitElpa = Git::Elpa::GitElpa.new

    before_each do
      git_elpa = Git::Elpa::GitElpa.new
    end

    describe "updatable_files_from_git_status" do
      it "lists updatable files from git status" do
        # setup - create temp folder
      end
    end

    describe "shell_escape" do
      it "escapes filename strings" do
        escaped = git_elpa.shell_escape "[[]]^^^^^test  😇"
        expectation = "[[]]^^^^^test  😇"

        escaped.should eq(expectation)
      end
    end
  end
end
