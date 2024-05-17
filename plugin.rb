# frozen_string_literal: true

# name: discourse-wikimedia-auth
# about: Enable Login via Wikimedia
# version: 0.1.3
# authors: Angus McLeod
# url: https://github.com/paviliondev/discourse-wikimedia-auth

gem "omniauth-mediawiki", "0.0.4"

enabled_site_setting :wikimedia_auth_enabled

register_asset "stylesheets/common/wikimedia.scss"

require_relative "lib/auth/wikimedia_authenticator"
require_relative "lib/wikimedia_username"

auth_provider authenticator: Auth::WikimediaAuthenticator.new

after_initialize do
  require_relative "extensions/guardian"

  reloadable_patch { Guardian.prepend(GuardianWikimediaExtension) }

  add_to_serializer(:user, :wiki_username) do
    UserAssociatedAccount
      .where(user_id: object.id)
      .select("info::json->>'nickname' as wiki_username")
      .first
      &.wiki_username
  end
end
