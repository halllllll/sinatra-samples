require 'sinatra'
require 'sinatra/reloader'
require 'digest/md5'
require 'time'
require 'date'

set :todos => {}
FILENAME = "todo.json"

class Todo
  attr_accessor :title, :content, :date, :priority, :id
  def initialize
    @date = Time.new.iso8601(6).to_s
    @id = Digest::MD5.hexdigest(@date)
  end
  def profile_to_hash
    self.instance_variables.map{|var|
      # そのままだと頭に@つきになってしまうので
      # [var.match(/[\w\d]+/).to_s, self.instance_variable_get(var)]
      # と思ったけど@ごと文字列にします
      [var.to_s, self.instance_variable_get(var)]
    }.to_h
  end
end

# エントリポイント
get '/' do
  if File.exists?(FILENAME)
    File.open(FILENAME, 'r+') do  |file|
      # 読み込み
      settings.todos = JSON.load(file)
    end
  else
    File.open(FILENAME, 'w+') do |file|
      file.puts('{}')
    end
  end
  @todos = settings.todos
  erb :top
end

get '/todos/new' do
  erb :new
end

post '/' do
  if params[:todocontent].split.size==0 && params[:todotitle].split.size==0
    status 204
    redirect '/'
  end
  todo = Todo.new()
  todo.content = params[:todocontent].strip
  todo.title = params[:todotitle].strip
  settings.todos[todo.id] = todo.profile_to_hash
  # ここに保存する処理
  updatelist(settings.todos, FILENAME)
  # ここで生成する
  @todos = settings.todos
  status 201
  redirect '/'
end

# 編集済データ更新(patchメソッド)
patch '/todos/:id' do
  settings.todos[params["id"]]["@title"] = params[:todotitle].strip
  settings.todos[params["id"]]["@content"] = params[:todocontent].strip
  # 時間を編集した時点に更新
  settings.todos[params["id"]]["@date"] = Time.new.iso8601(6).to_s
  updatelist(settings.todos, FILENAME)
  @todos = settings.todos
  # もうちょい検証が必要..?
  status 201
  redirect '/'
end

get /\/todos\/([\w\d]+)/ do |i|
  @todo_id = i
  @todo_title = settings.todos[i]["@title"].strip
  @todo_content = settings.todos[i]["@content"].strip
  erb :todo
end

# deleteメソッド
delete '/todos/:id' do
  settings.todos.delete(params["id"])
  updatelist(settings.todos, FILENAME)
  @todos = settings.todos
  status 204
  redirect '/'
end

get /\/todos\/([\w\d]+)\/edit/ do |i|
  @todo_id = i
  @todo_title = settings.todos[i]["@title"].strip
  @todo_content = settings.todos[i]["@content"].strip
  erb :edit
end

helpers do
  # jsonを現在のtodoに合わせてアップデート
  def updatelist(dict, file)
    # 時間順に並び替える
    dict = dict.sort_by do |key, val|
      val["@date"]
    end.reverse.to_h
    open(file, 'w+') do |f|
      JSON.dump(dict, f)
      settings.todos = JSON.load(f)
    end
    # dict
  end

  def gen_list(k, todo)
    tex = todo["@title"].size.zero? ? todo["@content"][0, 20] : todo["@title"]
    lastupdate = " -- [" + DateTime.parse(todo["@date"]).strftime("%b %d %H:%M") + "]"
    " <li class='todo__item'><a href='/todos/#{k}'>#{tex}</a><i class=&todo__item__updatetime'>#{lastupdate}</i></li>"
  end
end
