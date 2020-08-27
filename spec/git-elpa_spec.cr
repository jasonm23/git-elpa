require "./spec_helper"

describe Git::Elpa do

  before_each do
    create_mock_repo
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
          .sort
          .should eq [
             "?? elpa/FakePackageOne-0.1.0/",
             "?? elpa/FakePackageTwo-0.1.0/",
             "?? elpa/FakePackageThree-0.1.0/",
             "?? elpa/FakePackageFour-0.1.0/"
           ].sort
      end
    end

    describe "updated_packages" do
      it "lists the names of updated packages" do
        git_elpa.updated_packages
          .should eq [
             "FakePackageOne",
             "FakePackageTwo",
             "FakePackageThree",
             "FakePackageFour"
           ].sort
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

    describe "shell_escape" do
      it "escapes filename strings" do
        git_elpa.shell_escape("[[]]^^^^^").should eq "[[]]^^^^^"
      end
    end
  end
end
