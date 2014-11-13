require 'uri'
require 'httparty'

class Auth0Client
  include HTTParty
  base_uri 'login.auth0.com'

  def initialize(options)
    self.class.base_uri "https://#{options[:namespace]}"

    token_reponse = self.class.post("/oauth/token", {
      body: {
        'client_id'     => options[:client_id],
        'client_secret' => options[:client_secret],
        'grant_type'    => 'client_credentials'
      }
    })

    unless token_reponse.code == 200
      raise "Error geting the token: #{token_reponse.body}"
    end

    @token = token_reponse["access_token"]
    @headers = {
      "Authorization" => "Bearer #{@token}"
    }
  end

  def method_missing(meth, *args, &block)
    meth_split = meth.to_s.split('_')
    action = meth_split.shift
    path = meth_split.join('/')

    options = ( args.shift || {} )

    id = options[:id]
    body = options[:body]

    uri = URI.escape("/api/#{path}/#{id}")

    _args = []

    _args << action
    _args << uri
    _args << { body: body }

    response = self.class.send(*_args)
    response.body
  end

  def get_connections
    response = self.class.get("/api/connections", { headers: @headers })
    response.body
  end

  def delete_user(id)
    fail "#{__method__}: No id" if id.to_s.empty?

    uri = URI.escape("/api/users/#{id}")
    response = self.class.delete(uri, { headers: @headers })
    response.body
  end

  def delegation(options)
    response = self.class.post("/delegation", {
                body: {
                  client_id: options[:client_id],
                  grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
                  id_token: options[:id_token],
                  target: options[:target],
                  scope: "open_id"
                }
              })
    response.body
  end
end
