# frozen_string_literal: true

class Auth::WikimediaAuthenticator < ::Auth::ManagedAuthenticator
  def name
    "mediawiki"
  end

  def primary_email_verified?(auth_token)
    auth_token[:extra]["confirmed_email"].present? ? auth_token[:extra]["confirmed_email"] : false
  end

  def can_revoke?
    false
  end

  def can_connect_existing_user?
    false
  end

  def always_update_user_username?
    SiteSetting.wikimedia_username_conformity_login
  end

  def after_authenticate(auth_token, existing_account: nil)
    raw_info = auth_token[:extra]["raw_info"]
    auth_token[:extra] = raw_info || {}

    ## Deny entry if either:
    # 1) the user's Wikimedia email is not verified; or
    # 2) a user has previously authenticated with the same email under a different Wikimedia account
    ##

    if !primary_email_verified?(auth_token) ||
         (
           existing_associated_account =
             ::UserAssociatedAccount.where(
               "info::json->>'email' = '#{raw_info["email"]}' AND
         provider_uid != '#{raw_info["sub"]}' AND
         provider_name = '#{name}'",
             ).exists?
         )
      error_result = Auth::Result.new
      error_result.failed = true
      error_result.failed_reason =
        (
          if existing_associated_account
            I18n.t("login.authenticator_existing_account", { email: raw_info["email"] })
          else
            I18n.t("login.authenticator_email_not_verified")
          end
        )

      error_result
    else
      auth_token[:info][:nickname] = raw_info["username"] if raw_info["username"]
      auth_result = super(auth_token, existing_account: existing_account)

      ## Update user's username from the auth payload
      if auth_result.user && always_update_user_username? &&
           auth_result.user.username !=
             (wikimedia_username = WikimediaUsername.adapt(auth_result.username))
        UsernameChanger.change(auth_result.user, wikimedia_username, Discourse.system_user)
      end

      auth_result.overrides_username = true
      auth_result
    end
  end
  # :nocov:
  def register_middleware(omniauth)
    omniauth.provider :mediawiki,
                      name: name,
                      setup:
                        lambda { |env|
                          strategy = env["omniauth.strategy"]
                          options = strategy.options
                          options[:consumer_key] = SiteSetting.wikimedia_consumer_key
                          options[:consumer_secret] = SiteSetting.wikimedia_consumer_secret
                          options[:client_options][:site] = SiteSetting.wikimedia_auth_site

                          def strategy.callback_url
                            SiteSetting.wikimedia_callback_url
                          end
                        }
  end
  # :nocov:
  def enabled?
    SiteSetting.wikimedia_auth_enabled
  end
end
