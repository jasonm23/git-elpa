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
      end
    end

    context "repo changes" do
      before_each do
        git_elpa.commit_all_packages
        create_new_package_fake("FakePackageOne", "0.1.1")
        remove_old_package_fake("FakePackageOne", "0.1.0")
      end

      describe "commit_all_packages" do

        before_each do
          create_new_package_fake("FakePackageTwo", "0.1.1")
          remove_old_package_fake("FakePackageTwo", "0.1.0")

          remove_old_package_fake("FakePackageThree", "0.1.0")

          create_new_package_fake("FakePackageFour", "0.1.1")
          remove_old_package_fake("FakePackageFour", "0.1.0")

          create_new_package_fake("Foo", "0.1.0")
          create_new_package_fake("Bar", "0.1.0")
          create_new_package_fake("Baz", "0.1.0")
        end

        it "commits all packages" do
          git_elpa.commit_all_packages
          git_elpa.updated_packages.should eq [] of String | Nil
        end
      end

      describe "commit_package" do

        context "new package" do
          it "should commit the new update" do
            git_elpa.commit_package("FakePackageOne")
            git_elpa.updated_packages.should eq [] of String | Nil
          end
        end

        context "updated package" do
          describe "updated_packages" do
            it "shows the updated packages" do
              git_elpa.updated_packages.should eq ["FakePackageOne"]
            end

            context "after commit" do
              it "must not list any committed packages" do
                git_elpa.commit_package("FakePackageOne")
                git_elpa.updated_packages.should eq [] of String | Nil
              end
            end

            it "creates an update commit" do
              git_elpa.commit_package("FakePackageOne")
              elpa_git_log
                .should contain "[Updating FakePackageOne version: 0.1.1][removing old version: 0.1.0]"
            end
          end

          context "removed package" do
            before_each do
              remove_old_package_fake("FakePackageTwo", "0.1.0")
            end

            it "shows the removed package in the list of updated packages" do
              git_elpa.updated_packages.should contain "FakePackageTwo"
            end

            describe "commit" do
              it "commits the package removal" do
                git_elpa.commit_package "FakePackageTwo"
                git_elpa.updated_packages.should_not contain "FakePackageTwo"
              end
            end
          end
        end
      end
    end
  end
end
