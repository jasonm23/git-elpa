require "./spec_helper"


describe Git::Elpa do

  before_each do
    create_mock_repo
    # We start with the following fake git repo tree

    # .emacs.d
    # └── elpa
    #     ├── FakePackageFour-0.1.0
    #     ├── FakePackageOne-0.1.0
    #     ├── FakePackageThree-0.1.0
    #     └── FakePackageTwo-0.1.0
    #
  end

  after_each do
    teardown_mock_repo
  end

  describe Git::Elpa::GitElpa do

    git_elpa : Git::Elpa::GitElpa = Git::Elpa::GitElpa.new

    before_each do
      git_elpa = Git::Elpa::GitElpa.new
    end

    describe "updatable_files_from_git_status" do
      it "lists updatable files from git status" do
        git_elpa.updatable_files_from_git_status
          .should eq [
             "?? elpa/FakePackageFour-0.1.0/",
             "?? elpa/FakePackageOne-0.1.0/",
             "?? elpa/FakePackageThree-0.1.0/",
             "?? elpa/FakePackageTwo-0.1.0/",
           ]
      end
    end

    describe "updated_packages" do
      it "lists the names of updated packages" do
        git_elpa.updated_packages
          .should eq [
             "FakePackageFour",
             "FakePackageOne",
             "FakePackageThree",
             "FakePackageTwo",
           ]
      end
    end

    describe "generate_commit_message" do
      context "adding new packages" do
        it "generates a commit message for a new package" do
          git_elpa.commit_package("FakePackageOne", false)
          git_elpa.generate_commit_message.should eq "[Adding FakePackageOne version: 0.1.0]"
        end
      end


    end

    describe "commit_package" do
      it "creates a git commit for a package" do
        git_elpa.commit_package("FakePackageOne")
        git_elpa.updated_packages.should_not contain "FakePackageOne"
      end
    end

    describe "commit_all_packages" do
      it "creates git commits for all packages" do
        git_elpa.commit_all_packages
        git_elpa.updated_packages.should eq [] of String | Nil
        run_cmd("git", ["log", "--oneline"])[1].split("\n").size.should eq 6
      end
    end

    describe "shell_escape" do
      it "escapes filename strings" do
        git_elpa.shell_escape("[[]]^^^^^").should eq "[[]]^^^^^"
      end
    end
  end
end
