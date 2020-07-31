module Homebrew
  module_function

  def autoremove_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `autoremove` [<options>]
        Remove packages that are no longer needed.
      EOS
      switch "-n", "--dry-run",
             description: "Just print what would be removed."
      switch "-f", "--force",
             description: "Remove without confirmation."
    end
  end


  # check if package was installed on request
  def package_requested?(package)
    package["installed"].each do |i|
      return true if i["installed_on_request"]
    end

    false
  end

  # check if package is needed by another
  def package_needed?(packages, package)
    packages.each do |p|
      p["installed"].each do |i|
        # need to be safe, cause 'runtime_dependencies' field might not exist
        i["runtime_dependencies"]&.each do |d|
          return true if d["full_name"] == package["full_name"]
        end
      end
    end

    false
  end

  # get packages that could be safely removed
  def get_removable_packages(packages)
    removables = []

    packages.each do |package|
      next if package_requested? package
      next if package_needed? packages, package

      packages = packages.delete_if { |p| p == package }
      removables = removables.append(package)
      removables = removables.concat get_removable_packages(packages)
      break
    end

    removables
  end

  def autoremove
    args = autoremove_args.parse

    info = Utils.safe_popen_read HOMEBREW_BREW_FILE, "info", "--json", "--installed"
    json = JSON.parse info
    removables = get_removable_packages json
    names = removables.map { |r| r["full_name"] }

    exit if removables.length.zero?

    oh1 "Removable packages: " \
      "#{names.sort.map(&Formatter.method(:identifier)).to_sentence}",
      truncate: false

    exit if args.dry_run?

    unless args.force?
      ohai "Proceed?", <<~EOF
        Enter:  yes
        CTRL-C: no

        To mark package as not removable run:
            brew install PACKAGE
      EOF
      readline
    end

    system HOMEBREW_BREW_FILE, "remove", *names
  end
end
