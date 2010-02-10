# example of RESTful Service to register publications
require 'rubygems'
require 'sinatra/base'  # gem install sinatra
require 'json'          # gem install json
require 'maruku'        # gem install maruku

class HAL < Sinatra::Base
  
  configure do
    # dummy databases
    AUTHORS = [
      {
        "uid" => "crohr",
        "first_name" => "Cyril",
        "last_name" => "Rohr",
        "affiliations" => ["INRIA", "IRISA"]
      },
      {
        "uid" => "gdupond",
        "first_name" => "Georges",
        "last_name" => "Dupond",
        "affiliations" => ["CNRS", "IRISA"]
      }
    ]
    PAPERS = [
      {
        "uid" => "some-well-chosen-title", 
        "revision" => 1, 
        "title" => "Some Well-Chosen Title", 
        "content" => "# Title\nHello **World**",
        "authors" => ["crohr"], 
        "tags" => ["rest", "http", "web services"],
        "updated_at" => Time.now-3600
      }
    ]
  end
  
  before do
    @accepted_types = request.accept.map!{|f| f.gsub(/;.*/,'')}
  end
  
  
  # API entry-point
  get '/' do
    halt 406, "application/json" if (@accepted_types & ["application/json", "*/*"]).empty?
    output = {
      "links" => [
        {"rel" => "self", "href" => "/", "type" => "application/json"},
        {"rel" => "collection", "href" => "/papers", "title" => "papers", "type" => "application/json"},
        {"rel" => "collection", "href" => "/authors", "title" => "authors", "type" => "application/json"}
      ]
    }
    content_type "application/json"
    JSON.pretty_generate(output)
  end
  
  
  # GET the authors
  get '/authors' do
    halt 406, "application/json" if (@accepted_types & ["application/json", "*/*"]).empty?
    authors = if params[:affiliations].nil? || params[:affiliations].empty?
      AUTHORS
    else
      AUTHORS.reject{ |author| (author['affiliations'] & params[:affiliations].split(",")).empty? }
    end
    output = {
      "total" => authors.length, 
      "offset" => 0, 
      "items" => [],
      "links" => [
        {"rel" => "self", "href" => "/authors", "type" => "application/json"},
        {"rel" => "parent", "href" => "/", "type" => "application/json"}
      ]
    }
    authors.each do |author|
      author['links'] = links_for_author(author)
      output["items"].push(author)
    end
    content_type "application/json"
    response['Allow'] = "GET, POST"
    JSON.pretty_generate(output)
  end
  
  
  # GET all the papers of a specific author
  get '/authors/:author_uid/papers' do |author_id|
    halt 404, "Author not found" unless author = AUTHORS.find{|a| a['uid'] == author_id}
    halt 406, "application/json" if (@accepted_types & ["application/json", "*/*"]).empty?
    papers = papers_by_author(author_id)
    output = {
      "total" => papers.length, 
      "offset" => 0, 
      "items" => [],
      "links" => [
        {"rel" => "self", "href" => "/authors/#{author_id}/papers", "type" => "application/json"},
        {"rel" => "parent", "href" => "/authors/#{author_id}", "type" => "application/json"}
      ]
    }
    papers.each do |paper|
      paper['links'] = links_for_paper(paper)
      output["items"].push(paper)
    end
    content_type "application/json"
    response['Allow'] = "GET"
    JSON.pretty_generate(output)
  end
  
  
  #  GET all the papers
  get "/papers" do
    halt 406, "application/json" if (@accepted_types & ["application/json", "*/*"]).empty?
    output = {
      "total" => PAPERS.length, 
      "offset" => 0, 
      "items" => [],
      "links" => [
        {"rel" => "self", "href" => "/papers", "type" => "application/json"},
        {"rel" => "parent", "href" => "/", "type" => "application/json"}
      ]
    }
    PAPERS.each do |paper|
      paper['links'] = links_for_paper(paper)
      output["items"].push(paper)
    end
    content_type "application/json"
    response['Allow'] = "GET, POST"
    JSON.pretty_generate(output)
  end
  
  
  # Submit a new paper
  post '/papers' do
    halt 406, "application/json" if (@accepted_types & ["application/json", "*/*"]).empty?
    halt 415, "Does not accept #{request.content_type}" unless request.content_type =~ /application\/json/i
    begin
      data = JSON.parse(request.body.read)
      halt 400, "Paper is invalid" if data['title'].nil? || data['authors'].empty? || data['content'].empty?
      paper = data.merge("uid" => permalink_for(data), "revision" => 1, "updated_at" => Time.now.to_i)
      PAPERS.push(paper)
      status 201
      response['Location'] = "/papers/#{paper['uid']}"
      content_type "application/json"
      ""
    rescue StandardError => e  
      halt 400, "Bad input: #{e.message}"
    end
  end
  
  
  # GET a specific paper
  # Can get it back as text/html, text/plain, application/json, application/pdf, application/x-latex
  get "/papers/:paper_id" do |paper_id|
    halt 406, "application/json" if (accepted_type = @accepted_types & ["application/json", "text/plain", "application/x-latex", "text/html", "*/*"]).empty?
    content_type accepted_type
    halt 404, "Cannot find #{paper_id}" unless paper = PAPERS.find{|p| p['uid'] == paper_id}
    response['Allow'] = 'GET, PUT, DELETE'
    etag compute_etag_for_paper(paper)
    last_modified Time.at(paper['updated_at']).httpdate
    paper['links'] = links_for_paper(paper)
    case accepted_type.first
    when "application/json"
      JSON.pretty_generate(paper)
    when "text/plain"
      paper['content']
    when "text/html", "*/*"
      Maruku.new(paper['content']).to_html_document
    when "application/x-latex"
      "TODO"
    when "application/pdf"
      "TODO"
    end
  end
  
  
  # GET all the authors of a specific paper
  get "/papers/:paper_id/authors" do |paper_id|
    halt 404, "Paper not found" unless paper = PAPERS.find{|a| a['uid'] == paper_id}
    halt 406, "application/json" if (@accepted_types & ["application/json", "*/*"]).empty?
    authors = AUTHORS.select{ |author| paper['authors'].include?(author['uid']) }
    output = {
      "total" => authors.length, 
      "offset" => 0, 
      "items" => [],
      "links" => [
        {"rel" => "self", "href" => "/papers/#{paper_id}/authors", "type" => "application/json"},
        {"rel" => "parent", "href" => "/papers/#{paper_id}", "type" => "application/json"}
      ]
    }
    authors.each do |author|
      author['links'] = links_for_author(author)
      output["items"].push(author)
    end
    content_type "application/json"
    response['Allow'] = "GET"
    JSON.pretty_generate(output)
  end
  
  
  # Update a paper
  put "/papers/:paper_id" do |paper_id|
    halt 404, "Cannot find #{paper_id}" unless paper = PAPERS.find{|p| p['uid'] == paper_id}
    halt 406, "application/json" if (@accepted_types & ["application/json", "*/*"]).empty?
    halt 415, "Does not accept #{request.content_type}" unless request.content_type =~ /application\/json/i
    etag compute_etag_for_paper(paper)
    last_modified Time.at(paper['updated_at']).httpdate
    begin
      data = JSON.parse(request.body.read)
      halt 400, "Paper is invalid" if data['tags'].empty? || data['title'].nil? || data['authors'].empty? || data['content'].empty?
      if data['revision'] == paper['revision']
        paper.merge!(data)
        paper.merge!("revision" => paper['revision']+1, "updated_at" => Time.now.to_i)
        status 200
        paper['links'] = links_for_paper(paper)
        etag compute_etag_for_paper(paper)
        last_modified Time.at(paper['updated_at']).httpdate
        content_type "application/json"
        JSON.pretty_generate(paper)
      else
        halt 409, "Conflict: the current revision of the paper is #{paper['revision'].inspect}. Yours is #{data['revision'].inspect}."
      end
    rescue StandardError => e  
      halt 400, "Bad input: #{e.message}"
    end
  end
  
  
  # Delete a paper
  delete "/papers/:paper_id" do |paper_id|
    halt 404, "Cannot find #{paper_id}" unless paper = PAPERS.find{|p| p['uid'] == paper_id}
    etag compute_etag_for_paper(paper)
    last_modified Time.at(paper['updated_at']).httpdate
    PAPERS.delete(paper)
    status 204
    ""
  end



  # helpers functions
  helpers do
    # generates the links for a paper
    def links_for_paper(paper)
      [
        {"rel" => "parent", "href" => "/", "type" => "application/json"},
        {"rel" => "self", "href" => "/papers/#{paper['uid']}", "type" => "application/json"},
        {"rel" => "collection", "title" => "authors", "href" => "/papers/#{paper['uid']}/authors", "type" => "application/json"},
        {"rel" => "search", "href" => URI.encode("http://google.com?q=#{(paper['tags'] || []).join("+")}")}
      ]
    end

    # generates the links for an author
    def links_for_author(author)
      [
        {"rel" => "parent", "href" => "/", "type" => "application/json"},
        {"rel" => "self", "href" => "/authors/#{author['uid']}", "type" => "application/json"},
        {"rel" => "collection", "title" => "papers", "href" => "/authors/#{author['uid']}/papers", "type" => "application/json"}
      ]
    end

    # you would use some database or dictionary here
    def papers_by_author(author_uid)
      PAPERS.select{ |paper| paper['authors'].include?(author_uid) }
    end

    def compute_etag_for_paper(paper)
      Digest::SHA1.hexdigest([paper["authors"], paper['revision'], paper["title"]].join)
    end
    
    # naive permalink implementation
    def permalink_for(paper)
      increment = 1
      text = paper['title'].downcase.gsub(/\W/, ' ').split(/\s+/).join('-')
      while PAPERS.find{ |p| p['uid'] == [increment, text].join("-") }
        increment += 1
      end
      [increment, text].join("-")
    end
  end

end

HAL.run! :host => 'localhost', :port => 4567
