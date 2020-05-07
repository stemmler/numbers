require 'sinatra'

number = 1
# 
#
get '/v1/next' do
  1
end

get '/v1/current' do
  1
end

# param: current
post '/v1/current' do
  current = params[:current]
  # TODO: validate that it is a valid integer
  current 
  # no response
end
