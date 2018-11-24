require 'sinatra'
require 'sinatra/reloader'

require 'digest/md5'

# とりあえずグローバルにtodoの配列作っとく
# 速度的にハッシュのほうがいいので変えた
todos = Hash.new()

before do
  # ページ遷移の前にtodosに設定
  @todos = todos
end

class Todo
  # 優先度は3段階でデフォルト0 titleが空ならcontentの頭10文字くらいを入れる
  # id管理しようと思ったけどあんま意味なさそうだったので作られた時間で
  # とおもったけど編集するときにどういうページングにすればいいのかさっぱりわからんのでつける
  # 最後に編集された時間で更新される
  attr_accessor :title, :content, :date, :priority, :id
  def initialize
    @date = Time.new.iso8601(6)
    # 雑だけどとりあえずTime.nowをそのまんま文字列にしてハッシュ生成
    @id = Digest::MD5.hexdigest(@date.to_s)
  end
end

# エントリポイント
get '/todo' do
  # 一覧と追加,詳細
  erb :top
end

get '/todo/new' do
  erb :new
end

# /newで送信したあとに画面表示としてはトップでいいんだけど、
# 追加処理保存処理をここでやるのはなんというか正義なのかわからん ダメな気がする
post '/todo' do
  # とりあえずpostリクエストした内容を出してみる
  @reqdata = request.env.to_a
  # ググって出てきたサンプルをみるとここでclassから作っているみたいだ
  todo = Todo.new()
  todo.content = params[:todocontent]
  todo.title = params[:todotitle]
  # インスタンスが持つ固有のIDをハッシュのキーにするの、二重にIDがあってなんだかなぁ
  todos[todo.id] = todo
  status 201
  redirect '/todo'
end

# 編集済
patch '/todo' do
  todos[params[:id]].title = params[:todotitle]
  todos[params[:id]].content = params[:todocontent]
  redirect '/todo'
end

# メモにフォーカスしたときのやつ
# URI設計がむずい。。
# get /todo/items/id' do
get /\/todo\/items\/([\w\d]+)/ do |i|
  @memoid = i
  @memotitle = todos[i].title
  @memocontent = todos[i].content
  erb :memo
end

# メモにフォーカスした画面から削除するやつ
# とくにアラートは出ない
delete '/todo' do
  todos.delete(params[:delete])
  redirect '/todo'
end

get /\/todo\/items\/edit\/([\w\d]+)/ do |i|
  @memoid = i
  @memotitle = todos[i].title
  @memocontent = todos[i].content
  erb :edit
end