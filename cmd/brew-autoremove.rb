# frozen_string_literal: true

#:  * `autoremove` [options]
#:
#:  Remove packages that are no longer needed.
#:
#:      -n, --dry-run                    Just print what would be removed.
#:      -f, --force                      Remove without confirmation.

require 'json'
require 'optparse'

def package_needed?(packages, package)
  return true if package['installed'].first['installed_on_request']

  packages.each do |p|
    p['dependencies'].each do |dep|
      return true if dep == package['name']
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

options = {}
OptionParser.new do |opts|
  opts.on('-n', '--dry-run', '') do
    options[:dry] = true
  end
  opts.on('-f', '--force', '') do
    options[:force] = true
  end
end.parse!

json = JSON.parse(`brew info --json --installed`)
removables = get_removable_packages(json)
removables.each do |r|
  puts r['name']
end

return if removables.empty?
return if options[:dry]

unless options[:force]
  puts "\n==> Confirm?"
  readline
end

system 'brew', 'remove', *removables.collect { |r| r['name'] }
