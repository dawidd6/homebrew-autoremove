require "formula"

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

  def get_removable_formulae(installed_formulae)
    removable_formulae = []

    installed_formulae.each do |formula|
      # Reject formulae installed on request.
      next if formula.installed_kegs.any? { |keg| Tab.for_keg(keg).installed_on_request }
      # Reject formulae which are needed at runtime by other formulae.
      next if installed_formulae.map(&:deps).flatten.uniq.map(&:to_formula).include?(formula)

      removable_formulae << installed_formulae.delete(formula)
      removable_formulae += get_removable_formulae(installed_formulae)
    end

    removable_formulae
  end

  def autoremove
    args = autoremove_args.parse

    removable_formulae = get_removable_formulae(Formula.installed)

    return if removable_formulae.empty?

    formulae_names = removable_formulae.map(&:full_name)

    oh1 "Formulae that could be removed: " \
      "#{formulae_names.sort.map(&Formatter.method(:identifier)).to_sentence}",
      truncate: false

    return if args.dry_run?

    unless args.force?
      ohai "Proceed?", <<~EOF
        Enter:  yes
        CTRL-C: no

        To mark formulae as not removable run:
            brew install PACKAGE
      EOF
      readline
    end

    system HOMEBREW_BREW_FILE, "rm", *formulae_names
  end
end
