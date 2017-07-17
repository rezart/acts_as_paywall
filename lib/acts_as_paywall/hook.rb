module ActsAsPaywall::Hook
  def acts_as_paywall(*args)
    options = args.extract_options!
    include ActsAsPaywall::InstanceMethods

    before_action :paywall, options
  end
end
