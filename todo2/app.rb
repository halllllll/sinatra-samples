require 'sinatra'
require 'sinatra/reloader'
require 'digest/md5'
require 'time'

class Rack::MethodOverride
  ALLOWED_METHODS=%w[GET HEAD PUT POST DELETE OPTIONS PATCH LINK UNLINK]
  METHOD_OVERRIDE_PARAM_KEY = "_method".freeze
  def method_override(env)
    req = Rack::Request.new(env)
    method = req.params[METHOD_OVERRIDE_PARAM_KEY] || env[HTTP_METHOD_OVERRIDE_HEADER]
    method.to_s.upcase
  end
end

enable :method_override

todos = Hash.new()
# filename = "todo.json"

before do
  @todos = todos
end

class Todo
  attr_accessor :title, :content, :date, :priority, :id
  def initialize
    @date = Time.new.iso8601(6)
    @id = Digest::MD5.hexdigest(@date.to_s)
  end
end

# エントリポイント
get '/todo' do
  if File.exists?("todo.json")
    File.open("todo.json") do  |file|
      # とりあえず読み込む処理は後回しにしておく
      # todos = JSON.load("todo.json")
    end
  else
    File.open("todo.json", 'w+') do |file|
      file.puts('{}')
    end
  end
  erb :top
end

get '/todo/new' do
  erb :new
end
post '/todo' do
  todo = Todo.new()
  todo.content = params[:todocontent]
  todo.title = params[:todotitle]
  todos[todo.id] = todo

  # ここに保存する処理
  updatelist(todos, "todo.json")
  # erb :top
  status 201
  redirect '/todo'
end

# 編集済データ更新
patch '/todo' do
  # formでやるのはなぜか失敗するので
  todos[params[:id]].title = params[:todotitle]
  todos[params[:id]].content = params[:todocontent]
  todos[params[:id]].date = Time.new.iso8601(6)
  # @reqdata = params
  # erb :top
  redirect '/todo'
end

get /\/todo\/items\/([\w\d]+)/ do |i|
  @memoid = i
  @memotitle = todos[i].title
  @memocontent = todos[i].content
  # @reqdata = "todos[#{i}].title= "+todos[i].title
  erb :memo
end

delete '/todo' do
  todos.delete(params[:id])
  updatelist(todos, "todo.json")
  redirect '/todo'
end

get /\/todo\/items\/edit\/([\w\d]+)/ do |i|
  @memoid = i
  @memotitle = todos[i].title
  @memocontent = todos[i].content
  erb :edit
end

helpers do
  def updatelist(dict, filename)
    ret = Hash.new{|h,k| h[k] = {}}
    dict.map{|k, v|
      ret[k] = v.instance_variables.map{|var|
        [var.to_s.match(/[\w\d].+/), 
        v.instance_variable_get(var)]}.to_h
    }
    open(filename, 'w+') do |file|
      JSON.dump(ret, file)
    end
  end
end 