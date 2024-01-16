# frozen_string_literal: true

require_relative "../../plugin_helper"

describe Auth::WikimediaAuthenticator do
  let(:user) { Fabricate(:user) }
  let(:wikimedia_username) { "Wikimedia Username" }
  let(:wikimedia_uid) { "58875557" }

  def build_raw_info
    {
      aud: "12355678910",
      exp: "1564629219",
      iat: "1564629119",
      iss: "https://www.mediawiki.org",
      sub: "58875557",
      email: user.email,
      nonce: "12356",
      grants: ["mwoauth-authonlyprivate"],
      groups: %w[user autoconfirmed],
      rights: %w[
        createaccount
        read
        edit
        createpage
        createtalk
        writeapi
        viewmywatchlist
        editmywatchlist
        viewmyprivateinfo
        editmyprivateinfo
        editmyoptions
        translate
      ],
      blocked: false,
      realname: "Angus McLeod",
      username: wikimedia_username,
      editcount: 0,
      registered: "20190710001640",
      confirmed_email: true,
    }
  end

  def build_auth_hash(info = nil)
    OmniAuth::AuthHash.new(
      provider: "mediawiki",
      uid: wikimedia_uid,
      info: {
        name: wikimedia_username,
        email: user.email,
      },
      extra: {
        raw_info: info || build_raw_info,
      },
    )
  end

  before { SiteSetting.wikimedia_auth_enabled = true }

  describe "#after_authenticate" do
    it "requires user's wikimedia email to be verified" do
      raw_info = build_raw_info
      raw_info[:confirmed_email] = false
      auth_hash = build_auth_hash(raw_info)

      result = described_class.new.after_authenticate(auth_hash)
      expect(result.failed).to eq(true)
      expect(result.failed_reason).to eq(I18n.t("login.authenticator_email_not_verified"))
    end

    it "does not allow authentication from account with previously used email" do
      UserAssociatedAccount.create!(
        provider_name: "mediawiki",
        user_id: user.id,
        provider_uid: "12345",
        info: {
          email: user.email,
        },
      )

      result = described_class.new.after_authenticate(build_auth_hash)
      expect(result.failed).to eq(true)
      expect(result.failed_reason).to eq(I18n.t("login.authenticator_existing_account"))
    end

    it "allows authentication from account with previously used email if provider was different" do
      UserAssociatedAccount.create!(
        provider_name: "mediawiki2",
        user_id: user.id,
        provider_uid: "12345",
        info: {
          email: user.email,
        },
      )

      result = described_class.new.after_authenticate(build_auth_hash)
      expect(result.failed).to eq(false)
    end

    it "adapts Wikimedia username to Discourse username if username conformity is enabled" do
      SiteSetting.wikimedia_username_conformity_login = true

      result = described_class.new.after_authenticate(build_auth_hash)
      expect(result.user.username).to eq("Wikimedia_Username")
    end
  end
end
