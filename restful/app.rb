require 'sinatra'
require 'sinatra/reloader'

arr = []

# formからdeleteが出来なかったのでできるようにするやつ
enable :method_override

before do
  @resmessage = request.env.to_a
  @arrarr = arr
end

get '/addtest' do
  erb :addtestview, :layout => false
end

post '/addtest' do
  arr << Time.new().iso8601(6)
  status 201
  erb :addtestview, :layout => false
end

delete '/addtest' do
  if params[:POP].nil? && params[:DEQUEUE]
    arr.shift
    arr
  elsif params[:POP] && params[:DEQUEUE].nil?
    arr.pop
    arr
  else
    arr << "なんでやねん"
  end
  redirect '/addtest'
end