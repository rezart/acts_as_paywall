require 'acts_as_paywall'
require_relative 'crawlers.rb'

module ActsAsPaywall::InstanceMethods
  attr_accessor :permissible_controllers
  attr_accessor :free_views
  attr_accessor :wall_url

  def paywall
    redirect_to_paywall! if should_redirect_to_paywall?
    increment_content_views!
  end

  def subscription_wall
    if signed_in?
      redirect_to_subscription_wall! if should_redirect_to_subscription_wall?
      increment_subscription_views!
    end
  end

  def redirect_to_paywall!
    session[:return_to] = request.fullpath
    redirect_to paywall_option(:wall_url)
  end

  def redirect_to_subscription_wall!
    session[:return_to] = request.fullpath
    redirect_to paywall_option(:subscription_url)
  end

  def increment_content_views!
    return true if skip_paywall?
    views = content_views
    views += 1
    cookies[paywall_option(:content_view_cookie_key)] = views.to_s
  end

  def increment_subscription_views!
    return true if skip_paywall?
    views = subscription_views
    views += 1
    current_user.views = views.to_s
    current_user.save
  end

  def free_views_used?
    content_views.to_i > paywall_option(:free_views) if !skip_paywall?
  end

  def subscription_views_used?
    subscription_views.to_i > paywall_option(:subscription_views) if !skip_paywall?
  end

  def content_views
    (cookies[paywall_option(:content_view_cookie_key)] ||= 0).to_i
  end

  def subscription_views
    current_user.views ||= cookies[paywall_option(:subscription_view_cookie_key)]
    (current_user.views ||= 0).to_i
  end

  def skip_paywall?
    permissible_controller?
  end

  def should_redirect_to_paywall?
    free_views_used? &&
      !is_google? &&
      !skip_paywall? &&
      !(signed_in?)
  end

  def should_redirect_to_subscription_wall?
    subscription_views_used? &&
      !current_user.vip &&
      current_user.subscription.nil? if signed_in?
  end

  def permissible_controller?
    paywall_option(:permissible_controllers).include?("#{controller_name}##{action_name}")
  end

  def paywall_option(key)
    self.class.paywall_options[key.to_sym]
  end

  def is_google?
    paywall_option(:crawler_user_agents).include?(request.env['HTTP_USER_AGENT'])
  end
end
