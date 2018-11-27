require 'sinatra'
require 'sinatra/reloader'
require 'digest/md5'
require 'time'

enable :method_override

todos = Hash.new()
filename = "todo.json"

before do
  @todos = todos
end

class Todo
  attr_accessor :title, :content, :date, :priority, :id
  def initialize
    @date = Time.new.iso8601(6)
    @id = Digest::MD5.hexdigest(@date.to_s)
  end
  def profile_to_hash
    self.instance_variables.map{|var|
      # そのままだと頭に@つきになってしまうので
      [var.match(/[\w\d]+/).to_s, self.instance_variable_get(var)]
    }.to_h
  end
end

# エントリポイント
get '/todo' do
  if File.exists?(filename)
    File.open(filename, 'r+') do  |file|
      # 読み込み
      todos = JSON.load(file)
    end
  else
    File.open(filename, 'w+') do |file|
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
  todos[todo.id] = todo.profile_to_hash
  @todos = todos
  # ここに保存する処理
  updatelist(todos, filename)
  status 201
  redirect '/todo'
end

# 編集済データ更新
patch '/todo' do
  todos[params[:id]]["title"] = params[:todotitle]
  todos[params[:id]]["content"] = params[:todocontent]
  # 時間を編集した時点に更新
  todos[params[:id]]["date"] = Time.new.iso8601(6)
  redirect '/todo'
end

get /\/todo\/items\/([\w\d]+)/ do |i|
  @memoid = i
  @memotitle = todos[i]["title"]
  @memocontent = todos[i]["content"]
  erb :memo
end

delete '/todo' do
  todos.delete(params[:id])
  updatelist(todos, filename)
  status 204
  redirect '/todo'
end

get /\/todo\/items\/edit\/([\w\d]+)/ do |i|
  @memoid = i
  @memotitle = todos[i]["title"]
  @memocontent = todos[i]["content"]
  erb :edit
end

helpers do
  def updatelist(dict, file)
    open(file, 'w') do |f|
      JSON.dump(dict, f)
    end
  end
end 