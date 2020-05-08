require 'bcrypt'
require 'json'
require 'jwt'
require 'sinatra/base'

class App < Sinatra::Base

  # Authorization Headers
  AuthorizationHeaderName = 'HTTP_AUTHORIZATION'
  AuthorizationBearerPrefix = 'Bearer '

  # API endpoints that do not require the API token
  # Note: don't have an API token yet in the /v1/register endpoint,
  # and it is retrieved in the /v1/login endpoint, so we do not
  # require the API token to exist for those requests
  UnauthEndpointPaths = [ '/v1/register', '/v1/login' ]

  # Note: we would never store secret keys in code in production.
  # Since this is just a test assignment, and we are not storing
  # any real Personally Identifiable Information (PII), it is okay
  # to save here for now, but ideally we would store somewhere secure
  # like credstash, or some key management service, and read it in when
  # our application loads.
  JWTSecretKey = 'TestSecretKeyThinkific'
  JWTAlgorithm = 'HS256'

  # Integer values
  InitialIntegerValue = 1
  MinIntegerValue = 1
  MaxIntegerValue = 1_000_000_000_000

  MinPasswordLength = 10

  # User storage (in memory, and re-set on every app start up)
  # a dictionary of users, with the following structure:
  # { email -> { encrypted_password:,
  #              number:,
  #              api_token: }
  # 
  @@users = {}

  # the current user in the request (re-set on every http request)
  @@current_user = nil

  # before each request, check for the API token, and set
  # the current user to the corresponding user, if the API token
  # is valid, and the user exists
  before do
    # reset the current user to nil on every request
    @@current_user = nil

    # do the auth check, if needed
    if !UnauthEndpointPaths.include?( request.env[ 'PATH_INFO' ] )
      auth_check
    end
  end

  ####
  # API endpoints 
  ####

  # user creation endpoint
  #
  # params:
  # - email
  # - password
  post '/v1/register' do
    email = params[ :email ]
    password = params[ :password ]

    valid = valid_input_params?( email: email, password: password )
    if !valid_input_params?( email: email, password: password )
      status 400
      error_message = \
        "Invalid parameters: 'email' and 'password' must not be empty, "\
        "email must be valid, password must be minimum length "\
        "#{ MinPasswordLength }, and email must not be taken by "\
        "an existing user."
      return JSON.dump( { error: error_message } )
    end

    # return the user's api token
    api_token = create_user( email: email, password: password )
    return JSON.dump( { token: api_token } )
  end

  # user login endpoint, which retrieves the API token
  # for an existing user
  #
  # params:
  # - email
  # - password
  post '/v1/login' do
    email = params[ :email ]
    password = params[ :password ]

    # Note: we would want to add more parameter validation here, 
    # especially if we are reading from a DB, so that users
    # can't SQL inject, or any other abusive behaviour
    if email.nil? || password.nil? 
      status 400
      resp = { error: "Invalid parameters: 'email' and 'password' must not be empty." }
      return JSON.dump( resp )
    end

    # lookup user by the email and get the encrypter password object
    user = @@users[ email ]
    if user.nil?
      status 400
      resp = { error: "Invalid parameters: no user found with email #{ email }." }
      return JSON.dump( resp )
    end

    encrypted_password = user[ :encrypted_password  ]

    # check if the password matches the current. 
    # Note: the bcrypt object allows equality comparison on the 
    # raw password with the encrypted version, so we just need
    # to do a comparison here between the stored encrypted
    # password, and the one supplied, to validate if they match
    if encrypted_password != password
      status 400 
      return JSON.dump( { error: "Invalid password supplied." } )
    end

    # if we have gotten this far, then the password and email
    # match, so we can return the API token now
    api_token = user[ :api_token ]

    return JSON.dump( { api_token: api_token } )
  end

  # Get the next integer for the user
  get '/v1/next' do
    next_value = @@current_user[ :number ] + 1

    # if the incremented value is above the max integer
    # then error
    if next_value >= MaxIntegerValue
      status 400 
      return JSON.dump( { error: "Cannot increment number beyond max "\
                                 "value #{ MaxIntegerValue }. Reset "\
                                 "your number to a lower value and "\
                                 "try again." } )
    end

    # otherwise, update the current user's number
    @@users[ @@current_user[ :email ] ][ :number ] = next_value

    return JSON.dump( { integer: next_value } )
  end

  # Get the current integer for the user
  get '/v1/current' do
    # directly return the current number
    return JSON.dump( { integer: @@current_user[ :number ] } )
  end

  # Set the current integer for the user
  # 
  # params: 
  # - current 
  post '/v1/current' do
    current_number = validate_number( number: params[ :current ] )

    if current_number.nil?
      status 400
      error_message = "Parameter 'current' must be a valid integer in range "\
                      "[#{ MinIntegerValue }, #{ MaxIntegerValue } ], but "\
                      "got #{ params[ :current ].inspect }."
      return JSON.dump( { error: error_message } )
    end

    # set the user's number to the supplied value
    @@users[ @@current_user[ :email ] ][ :number ] = current_number

    # no return value, since this is an update
    return JSON.dump( {} )
  end

  ##########################
  # Helper functions below
  ##########################


  ###
  # Validation functions
  ###

  # check the http headers for the API token (if applicable)
  # and set the @@current_user to the corresponding user
  def auth_check
    # Note: sinatra doesn't show custom headers through headers variable, so 
    # instead you must use request.env to get the custom headers
    # source: https://stackoverflow.com/questions/25660827/accessing-headers-from-sinatra
    bearer = request.env[ AuthorizationHeaderName ]

    # Note: could add case insensitivity on the word "Bearer"
    if !bearer || !bearer.start_with?( AuthorizationBearerPrefix )
      halt 401, JSON.dump( { error_message: 'A valid token must be passed.'} )
    end

    # we extract the header 'Authorization: Bearer XXXX' and take the XXXX (i.e., the API token)
    # by taking everything from after the 'Bearer ' prefix, until the end
    api_token = bearer[ AuthorizationBearerPrefix.length.. -1 ]
    begin
      email = decode_api_token( api_token: api_token )
      @@current_user = @@users[ email ]

      if @@current_user.nil?
        halt 401, JSON.dump( { error_message: 'A valid token must be passed.'} )
      end

    # failure cases for the API decoding
    # source: https://auth0.com/blog/ruby-authentication-secure-rack-apps-with-jwt/
    rescue JWT::DecodeError
      halt 401, JSON.dump( { error_message: 'A valid token must be passed.'} )
    rescue JWT::ExpiredSignature
      halt 403, JSON.dump( { error_message: 'The token has expired.'} )
    rescue JWT::InvalidIssuerError
      halt 403, JSON.dump( { error_message: 'The token does not have a valid issuer.'} )
    rescue JWT::InvalidIatError
      halt 403, JSON.dump( { error_message: 'The token does not have a valid "issued at" time.'} )
    end
  end

  def encrypt_password( password: )
    return BCrypt::Password.create( password )
  end

  # validate the new number by ensuring it 
  # - is not empty
  # - is a valid integer
  # - with within bounds of MinIntegerValue and MaxIntegerValue
  #
  # returns: 
  # - nil if any of the above conditions fail
  # - integer, otherwise
  def validate_number( number: )

    # check if the number is nil
    if number.nil?
      return nil
    end

    # must be able to convert to valid integer
    begin
      value = Integer( number )
      if value < MinIntegerValue || value > MaxIntegerValue
        return nil
      end
      return value

    rescue ArgumentError
      return nil
    end
  end

  # validate the input parameters for creating a new
  # user with email and password
  # returns: bool, indicating whether the parameters
  # are valid
  def valid_input_params?( email:, password: )

    # ensure neither param is empty
    if email.nil? || password.nil? || email.empty? || password.empty?
      return false
    end

    # ensure email does not already belong to an existing user
    if !@@users[ email ].nil?
      return false
    end

    # we want to ensure the email is valid, so we use existing
    # regexp to validate
    # Note: we could build our own here
    if ( email =~ URI::MailTo::EMAIL_REGEXP ).nil?
      return false
    end

    # ensure password meets minimum length requirements
    # Note: we could add more validation in requiring symbols,
    # numbers, uppercase, etc.
    if password.length < MinPasswordLength
      return false
    end

    return true
  end

  ###
  # API token helpers
  ###

  def generate_api_token( email: )
    payload = { email: email }
    return JWT.encode( payload, JWTSecretKey, JWTAlgorithm )
  end

  def decode_api_token( api_token: )
    options = { algorithm: JWTAlgorithm }
    payload, header = JWT.decode( api_token, JWTSecretKey, true, options )
    return payload[ 'email' ]
  end


  ###
  # User storage
  ###

  # create a new user, and return the API token for that user
  # prereqs: the parameters have already been validated
  # returns: the API token for the new user
  def create_user( email:, password: )

    # first, encrypt the password, and then save the user
    # to our in-memory dictionary @@users
    encrypted_password = encrypt_password( password: password )
    api_token = generate_api_token( email: email )

    # we store by email, so that we can do an easy lookup.
    # we also store the email in the user's dictionary so that we
    # can easily look it up. this is redundant, and we could instead
    # just populate the field on the current_user object when we fetch
    # it during the auth_check
    @@users[ email ] = {
      email: email,
      encrypted_password: encrypted_password,
      number: InitialIntegerValue,
      api_token: api_token
    }

    # returns the api token for this user
    return api_token
  end
end

App.run!
