require "sinatra"
require "sinatra/reloader"
require 'tilt/erubis'
require 'pry'

before do
  @chapters = File.readlines('data/toc.txt')
end

helpers do
  def in_paragraphs(text)
    text.split("\n\n").map.with_index do |paragraph, index|
      "<p id=\"paragraph-#{index + 1}\">#{paragraph}</p>"
    end.join
  end

  def highlight_query(paragraph, query)
    paragraph.gsub(query, "<strong>#{query}</strong>")
  end
end

get "/" do
  @title = "The Adventures of Sherlock Holmes"  

  erb :home
end

get "/chapters/:number" do
  ch_num = params[:number].to_i
  redirect "/" unless ch_num.between?(1, @chapters.size)

  ch_title = @chapters[ch_num - 1]
  @title = "Chapter #{ch_num}: #{ch_title}"
  @chapter = File.read("data/chp#{ch_num}.txt")

  erb :chapter
end

get "/search" do
  @results = search_results(params[:query])
  
  erb :search
end

not_found do
  redirect "/"
end

# Helpers
def each_chapter
  @chapters.each_with_index do |ch_title, index|
    ch_num = index + 1
    contents = File.read("data/chp#{ch_num}.txt")
  
    yield ch_num, ch_title, contents
  end
end

def search_results(query)
  results = []
  return results if query.to_s.empty?

  each_chapter do |ch_num, ch_title, contents|
    if contents.include?(query)
      paragraph_results = matching_paragraphs(contents, query)

      results << { number: ch_num, title: ch_title, matches: paragraph_results }      
    end
  end

  results
end

def matching_paragraphs(contents, query)
  contents.split("\n\n").filter_map.with_index do |paragraph, index|
    { id: "paragraph-#{index + 1}", text: paragraph } if paragraph.include?(query)
  end
end