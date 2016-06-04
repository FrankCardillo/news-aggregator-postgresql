require "sinatra"
require "pg"
require_relative "./app/models/article"
require 'pry'

set :views, File.join(File.dirname(__FILE__), "app", "views")

configure :development do
  set :db_config, { dbname: "news_aggregator_development" }
end

configure :test do
  set :db_config, { dbname: "news_aggregator_test" }
end

def db_connection
  begin
    connection = PG.connect(Sinatra::Application.db_config)
    yield(connection)
  ensure
    connection.close
  end
end


get "/" do
  redirect "/articles"
end

get "/articles/new" do
  erb :post_article
end

post "/articles/new_post" do
  article_title = params['article_title']
  article_url = params['article_url']
  article_description = params['article_description']
  @my_article = Article.new(article_title, article_url, article_description)

  @my_article.check_and_add_http
  @my_article.set_dupe_value

  if @my_article.check_for_empty_form
    raise EmptyFormError, "You did not fill out all form fields."
  elsif @my_article.check_description_length
    raise DescriptionLengthError, "Your description length is < 20 chars."
  elsif @my_article.check_dupe_value
    raise DuplicateArticleError, "This article has already been submitted."
  else
    db_connection do |conn|
      sql_query = "INSERT INTO articles (title, url, description) VALUES ($1, $2, $3)"
      data = [article_title, article_url, article_description]
      conn.exec_params(sql_query, data)
    end
    redirect "/articles"
  end
end

get "/articles" do
  @titles = []
  @urls = []
  @descriptions = []

  db_connection do |conn|
    sql_query = "SELECT * FROM articles"
    result = conn.exec(sql_query)
    result.entries.each do |hash|
      @titles << hash["title"]
      @urls << hash["url"]
      @descriptions << hash["description"]
    end
  end

  erb :index
end
