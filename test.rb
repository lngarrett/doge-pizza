require 'sinatra'
require 'data_mapper'
require 'dm-migrations'
require 'net/http'

### Configuration Variables ###
$dogeAPIKey = '1vmegdm574t6yw29zag1ubmy7c'

def getRequest(url)
  @resp = Net::HTTP.get_response(URI.parse(url))
  @body = @resp.body
end

def getAddressReceived(address)
  @action = "https://www.dogeapi.com/wow/?api_key=#{$dogeAPIKey}&a=get_address_received&payment_address=#{address}"
  @string = getRequest(@action)
  @string = @string.gsub( /\A"/m, "" ).gsub( /"\Z/m, "" )
  @string
end

def getNewAddress(addressLabel)
  @action = "https://www.dogeapi.com/wow/?api_key=#{$dogeAPIKey}&a=get_new_address&address_label=#{addressLabel}"
  @string = getRequest(@action)
  @string = @string.gsub( /\A"/m, "" ).gsub( /"\Z/m, "" )
  @string
end

DataMapper.setup(:default, 'mysql://root:dixie12bz@localhost/database')

class Order
  include DataMapper::Resource
  
  property :id,			Serial
  property :firstName,		String
  property :lastName,		String
  property :street,		String
  property :city,		String
  property :paymentAddress,	String
  property :paid,		Boolean, :default => false
end

DataMapper.finalize
DataMapper.auto_migrate!

set :bind, '0.0.0.0'
enable :sessions

get '/form' do
  erb :form
end

post '/form' do
  @address = getNewAddress(@count)
  @count = Order.count + 1
  @order = Order.create(
  :firstName		=> params[:firstName],
  :lastName		=> params[:lastName],
  :street		=> params[:street],
  :city			=> params[:city],
  :paymentAddress	=> @address
  )
  session[:paymentAddress] = @address
  redirect to("/payment/#{session[:paymentAddress]}")
end

get '/payment/:address' do
  @address = params[:address]
  @received = getAddressReceived(@address)
  if @received.to_i == 0
    "Doge Received: " + @received + "\n If you've sent your payment, please wait a minute and refresh the page."
  else
    puts "Recieved " + @received
  end
end
