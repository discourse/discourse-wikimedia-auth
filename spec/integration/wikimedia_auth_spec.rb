# frozen_string_literal: true

describe "Wikimedia Oauth2" do
  let(:access_token) { "wikimedia_access_token_448" }
  let(:oauth_token_secret) { "wikimedia_oauth_token_secret_4898" }
  let(:client_id) { "abcdef11223344" }
  let(:client_secret) { "adddcccdddd99922" }

  fab!(:user1) { Fabricate(:user) }

  def setup_wikimedia_email_stub(email:, verified:)
    stub_request(
      :get,
      "https://meta.wikimedia.org/w/index.php?title=Special:OAuth/identify",
    ).to_return(
      status: 200,
      body:
        JWT.encode(
          {
            sub: "394234234",
            username: "someb0dy",
            email: email,
            iss: "https://meta.wikimedia.org",
            confirmed_email: verified,
          },
          client_secret,
        ),
      headers: {
        "Content-Type" => "application/json",
      },
    )
  end

  before do
    SiteSetting.wikimedia_auth_enabled = true
    SiteSetting.wikimedia_consumer_key = client_id
    SiteSetting.wikimedia_consumer_secret = client_secret

    stub_request(
      :post,
      "https://meta.wikimedia.org/w/index.php?title=Special:OAuth/initiate",
    ).to_return(
      status: 200,
      body:
        Rack::Utils.build_query(oauth_token: access_token, oauth_token_secret: oauth_token_secret),
      headers: {
        "Content-Type" => "application/x-www-form-urlencoded",
      },
    )

    stub_request(
      :post,
      "https://meta.wikimedia.org/w/index.php?title=Special:OAuth/token",
    ).to_return(
      status: 200,
      body:
        Rack::Utils.build_query(oauth_token: access_token, oauth_token_secret: oauth_token_secret),
      headers: {
        "Content-Type" => "application/x-www-form-urlencoded",
      },
    )
  end

  it "doesn't sign in the user if the email from wikimedia isn't verified" do
    post "/auth/mediawiki"
    expect(response.status).to eq(302)
    expect(response.location).to start_with(
      "https://meta.wikimedia.org/wiki/Special:Oauth/authorize",
    )

    setup_wikimedia_email_stub(email: user1.email, verified: false)

    post "/auth/mediawiki/callback", params: { state: session["omniauth.state"] }
    expect(response.status).to eq(200)
    expect(response.body).to include(I18n.t("login.authenticator_email_not_verified"))
    expect(session[:current_user_id]).to be_blank
  end

  it "signs in the user if the email from wikimedia is verified" do
    post "/auth/mediawiki"
    expect(response.status).to eq(302)
    expect(response.location).to start_with(
      "https://meta.wikimedia.org/wiki/Special:Oauth/authorize",
    )

    setup_wikimedia_email_stub(email: user1.email, verified: true)

    post "/auth/mediawiki/callback", params: { state: session["omniauth.state"] }
    expect(response.status).to eq(302)
    expect(session[:current_user_id]).to eq(user1.id)
  end
end
