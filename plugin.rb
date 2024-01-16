# frozen_string_literal: true

# name: discourse-wikimedia-auth
# about: Enable Login via Wikimedia
# version: 0.1.3
# authors: Angus McLeod
# url: https://github.com/paviliondev/discourse-wikimedia-auth

gem "omniauth-mediawiki", "0.0.4"

enabled_site_setting :wikimedia_auth_enabled

register_asset "stylesheets/common/wikimedia.scss"

%w[../lib/auth/wikimedia_authenticator.rb ../lib/wikimedia_username.rb].each do |path|
  load File.expand_path(path, __FILE__)
end

auth_provider authenticator: Auth::WikimediaAuthenticator.new

after_initialize do
  %w[../extensions/guardian.rb].each { |path| load File.expand_path(path, __FILE__) }

  ::Guardian.prepend GuardianWikimediaExtension

  add_to_serializer(:user, :wiki_username) do
    UserAssociatedAccount
      .where(user_id: object.id)
      .select("info::json->>'nickname' as wiki_username")
      .first
      &.wiki_username
  end
end
