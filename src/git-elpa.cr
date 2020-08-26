# Git Elpa
# ========
#
# This module is used to simplify updating Emacs ELPA packages.
#
# In a nutshell, within Emacs you would update/modify your ELPA/MELPA packages
#
# Then use this script to:
# - list names of packages which have been updated/added/deleted
# - create commits for each package change
#   - by all
#   - by a single named package
#
# Abstract
# ========
#
# In this Emacs config, unlike most, I maintain a repository history of
# the ELPA packages I install. Usually (99% of the time over many years
# so far) I have no issues with this at all.  Of course, hypothetically,
# it's quite possible that any feature of any package could be broken at
# any time.
#
# In case a breakage occurs, it's possible to roll back to a previous
# version of that package, and it's easy to do when we can identify the
# package. We can simply cherry-pick it from a previous commit, or just
# grab it from it's canonical source.
#
# However, if the breakage manifests as a side-effect, identifying
# the problem package is much harder.
#
# To this end, I wrote this script to make each package have it's own
# commit history, (starting today!)
#
# Usage:
# ======
#
#     git-elpa --list
#
# or
#
#     git-elpa -l
#
# List all updated packages, not yet committed.
#
#     git-elpa --commit=package-name
#
# or
#
#     git-elpa -c package-name
#
# Commit the package update (and old version removal). The following
# automatic commit message pattern will be used:
#
# "[package-name upgraded] to NEW_VERSION from OLD_VERSION"
#
#     git-elpa --all
#
# or
#
#     git-elpa -a
#
# Commit all updated packages (as individual commits)
#
#     git-elpa --cleanup
#
# Remove all stray package info .txt files (created when viewing package details)
#

require "regex"
require "option_parser"

ANSI_RESET = "\x1b[0m"
ANSI_COMMAND_LOG = "\x1b[36m"
ANSI_MESSAGE = "\x1b[32m"
ANSI_WARNING = "\x1b[33m"
ANSI_ERROR = "\x1b[31m"

NO_UPDATES = "#{ANSI_WARNING}There are no updated packages / no commits required#{ANSI_RESET}"

def cd_to_emacs_d
  Dir.cd(File.join(ENV["HOME"], ".emacs.d"))
end

def log(str)
  puts "#{ANSI_MESSAGE}#{str}#{ANSI_RESET}"
end

def log_warning(str)
  puts "#{ANSI_WARNING}#{str}#{ANSI_RESET}"
end

def log_error(str)
  puts "#{ANSI_WARNING}#{str}#{ANSI_RESET}"
end

def run_cmd(cmd, args)
  args_clean : Array(String) = args.compact!.map(&.as(String))
  stdout = IO::Memory.new
  stderr = IO::Memory.new
  status = Process.run(cmd, args: args_clean, output: stdout, error: stderr)
  if status.success?
    {status.exit_code, stdout.to_s}
  else
    {status.exit_code, stderr.to_s}
  end
end

module Git::Elpa
  VERSION = "0.1.0"

  BANNER = <<-EOD
Emacs ELPA package commit tool

This tool is designed to assist the storage of your installed ELPA packages.
It will commit each package separately.

Please note: it is assumed you are actually performing the package updates with Emacs.

Usage: git-elpa [options]
EOD

  class GitElpa

    @old : Array(Nil | String) = [] of (Nil | String)
    @ver : Nil | String = nil
    @rx : Regex = %r{}

    def initialize
    end

    def shell_escape(str)
      str.gsub(%r{([^A-Za-z0-9_\-+.,:\/@\n]+)}) { $~[1] }
    end

    def updatable_files_from_git_status
      cd_to_emacs_d
      git_status = run_cmd("git", ["status", "-s"])
      status_rows = git_status[1].split("\n")
      a_or_d_git_status_items_rx = %r{^( D | A |[?]{2} )elpa/.*}

      updatable = status_rows.select! {|line|
        a_or_d_git_status_items_rx.match(line)
      }.uniq

      updatable
    end

    def updated_packages
      package_name = %r{^(.*)-.*?$}

      updatable = updatable_files_from_git_status
                  .map { |name| name[8..name.size] }
      updated_names = updatable.map { |u|
        md = package_name.match(u)
        md[1] if md
      }.uniq.compact.sort

      return if updated_names.empty?

      updated_names
    end

    def commit_package(package : String, do_commit = true)
      @package = package
      @rx = %r{(^elpa/)(#{@package})-(.*)/}
      @old = old_versions
      @ver = new_version

      commit if do_commit
    end

    def commit_all_packages
      if updated_packages.nil?
        log "No updated Emacs packages"
        return
      end

      updated_packages.try &.each do |p|
        commit_package(p)
      end
    end

    def pluralise(word, amount)
      # The world's most minimalistic English pluralisation engine.
      word + (amount > 1 ? "s" : "")
    end

    def remove_package_message(versions_label)
      "[Removing #{@package} #{versions_label}: #{@old.join(',')}]"
    end

    def updating_new_and_remove_old_package_message(versions_label)
      "[Updating #{@package} version: #{@ver}][removing old #{versions_label}: #{@old.join(',')}]"
    end

    def adding_new_package_message
      "[Adding #{@package} version: #{@ver}]"
    end

    def generate_commit_message
      versions_label = pluralise("version", @old.size) if @old && @old.size > 0
      return remove_package_message(versions_label) if @ver.nil? && @old.size > 0
      return updating_new_and_remove_old_package_message(versions_label) if @old.size > 0
      return adding_new_package_message if @old.size.zero?
    end

    def add_to_index
      cd_to_emacs_d

      new_version_files.each do |file|
        run_cmd("git", ["add", shell_escape(file)])
      end unless @ver.nil?

      old_version_files.each do |file|
        run_cmd("git", ["rm", "-rf", shell_escape(file)])
      end unless @old.empty?
    end

    def git_commit(message)
      cd_to_emacs_d
      run_cmd("git", ["commit", "-m", message])
    end

    def commit(message = generate_commit_message)
      add_to_index
      log(message)
      git_commit(message)
    end

    def new_version : String
      versions : Array(String) =
        new_version_files
        .map { |f|

        md = @rx.try(&.match(f))
        md[3] if md

      }.uniq.compact!.map(&.as String)

      if versions.size > 1
        log_warning("There are more than one new versions of #{@package}")
        exit(1)
      end

      if versions.size < 1
        log_warning("There are no new versions of #{@package}")
        exit(1)
      end

      versions[0]
    end

    def old_versions : Array(Nil | String)
      old_version_files
        .map { |f|

        md = @rx.try(&.match(f))
        md[3] if md

      }.uniq
    end

    def cleanup_version_file_names(list)
      list
        .map { |f| f.gsub(%r{^.{3}elpa/}, "") }
        .select { |f| f != "" }
    end

    def filter_version_files(status_rx)
      cleanup_version_file_names(
        updatable_files_from_git_status
        .select { |file| status_rx.match(file) }
        .map { |file| file.gsub(status_rx, "") }
        .select { |f|
          @rx.match(f)
        }
      )
    end

    def new_version_files
      status_rx = /^( A |[?]{2} )/
      filter_version_files(status_rx)
    end

    def old_version_files
      status_rx = /^( D )/
      filter_version_files(status_rx)
    end

    def commit_archives
      cd_to_emacs_d
      run_cmd("git", ["add", "elpa/archives"])
      git_commit("Updating elpa archives")
    end
  end

  option_parser = OptionParser.new do |opts|
    elpa = GitElpa.new
    opts.banner = BANNER

    opts.invalid_option do |flag|
      STDERR.puts("ERROR: #{flag} is not a valid option.")
      STDERR.puts(opts)
      exit(1)
    end

    opts.on("-l", "--list", "List updated packages") do
      package_list = elpa.updated_packages
      if package_list.nil?
        log "No updated Emacs packages"
        exit(1)
      else
        log "Listing updated ELPA packages...(to be committed)"
        puts elpa.updated_packages.try &.join("/n")
        exit(0)
      end
    end

    opts.on "-cPACKAGE", "--commit=PACKAGE", "Commit a new/updated elpa package" do |package|
      elpa.commit_package package
      exit(0)
    end

    opts.on("-A", "--all", "Commit all updated elpa packages (as individual commits)") do
      puts <<-EOD.gsub(/^ */, "")
        #{ANSI_MESSAGE}Commit all updated packages
    EOD
      elpa.commit_all_packages
      exit(0)
    end

    opts.on("-e", "--elpa-archive", "Commit updated elpa/melpa archive index") do
      elpa.commit_archives
      exit(0)
    end

    opts.on "-C", "--cleanup", "Cleanup stray elpa txt files" do
      log("Cleaning out elpa .txt files")
      unwanted_text_files_pattern = File.join(ENV["HOME"], "emacs.d", "elpa", "*.txt")
      if Dir.glob(unwanted_text_files_pattern).empty?
        log("There are no unwanted .txt files in elpa.")
      else
        Dir.glob(unwanted_text_files_pattern).each do |file|
          log_warning("Deleting: #{file}")
          File.delete(file)
        end
      end
      log("done")
      exit(0)
    end

    opts.on("-R", "--reset-custom", "Reset custom.el") do
      log("resetting custom.el")
      cd_to_emacs_d
      run_cmd("git", ["checkout", "custom/custom.el"])
      log("done")
      exit(0)
    end
  end

  option_parser.parse
  puts option_parser

end
