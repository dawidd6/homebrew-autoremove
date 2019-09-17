# frozen_string_literal: true

#:  * `autoremove` [options]
#:
#:  Remove packages that are no longer needed.
#:
#:      -n, --dry-run                    Just print what would be removed.
#:      -f, --force                      Remove without confirmation.

require "json"
require "optparse"

module Homebrew
  module_function

  def package_needed?(packages, pkg)
    return true if pkg["installed"].first["installed_on_request"]

    packages.each do |package|
      deps = package["installed"].first["runtime_dependencies"]
      next if deps.nil?

      deps.each do |dep|
        return true if dep["full_name"] == pkg["full_name"]
      end
    end

    false
  end

  def get_removable_packages(packages)
    removables = []

    packages.each do |package|
      next if package_needed?(packages, package)

      packages = packages.delete_if { |p| p == package }
      removables = removables.append(package)
      removables = removables.concat(get_removable_packages(packages))
      break
    end

    removables
  end

  dry = false
  force = false
  parser = OptionParser.new
  parser.on("-n", "--dry-run", "") { dry = true }
  parser.on("-f", "--force", "") { force = true }
  parser.parse!

  json = JSON.parse(`brew info --json --installed`)
  removables = get_removable_packages(json)
  names = removables.map { |r| r["name"] }

  exit if removables.length.zero?

  oh1("Removable packages: " \
    "#{names.map(&Formatter.method(:identifier)).to_sentence}",
    truncate: false)

  exit if dry

  unless force
    ohai("Confirm?")
    readline
  end

  system("brew", "remove", *names)
end
