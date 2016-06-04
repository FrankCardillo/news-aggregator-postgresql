require "pg"
#=============
# CODE IMPORTED FROM CSV VERSION

def db_connection
  begin
    connection = PG.connect(Sinatra::Application.db_config)
    yield(connection)
  ensure
    connection.close
  end
end

class Article
  attr_reader :title, :url, :description, :dupe_article

  def initialize(title, url, description)
    @title = title
    @url = url
    @description = description
    @dupe_article = false
  end

  def check_and_add_http
    if @url[0..3] != "http"
      @url = "http://" + @url
    end
  end

  def set_dupe_value
    db_connection do |conn|
      sql_query = "SELECT * FROM articles WHERE url = '#{@url}';"
      result = conn.exec(sql_query)
      if result.entries.length > 0
        @dupe_article = true
      end
    end

  end

  def check_for_empty_form
    @title.length == 0 || @url.length == 0 || @description.length == 0
  end

  def check_description_length
    @description.length < 20
  end

  def check_dupe_value
    @dupe_article
  end
end

class EmptyFormError < StandardError
end

class DescriptionLengthError < StandardError
end

class DuplicateArticleError < StandardError
end
