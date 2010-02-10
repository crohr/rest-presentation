require 'rubygems'
require 'restclient' # gem install rest-client
require 'json' # gem install json
require 'pp'
require 'logger'

RestClient.log = Logger.new(STDERR)

# declare the API entry-point
api = RestClient::Resource.new("http://localhost:4567")

authors_response = api['/authors'].get(:accept => "application/json")
authors_collection = JSON.parse(authors_response)

unless authors_collection['items'].empty?
  
  # get the papers of the first author
  papers_link = authors_collection['items'].first['links'].find{|l| l['rel'] == "collection" && l['title'] == "papers"}
  papers_response = api[papers_link['href']].get(:accept => papers_link['type'])
  papers_collection = JSON.parse(papers_response)
  
  unless papers_collection['items'].empty?
    # try to update the first paper of the first author
    paper_link = papers_collection['items'].first['links'].find{|l| l['rel'] == "self"}
    paper_response = api[paper_link['href']].get(:accept => paper_link['type'])
    # check that we can send a PUT method there
    if paper_response.headers[:allow].split(/\s*,\s*/).include?("PUT")
      paper = JSON.parse paper_response
      paper['content'] = "# First title\nSome text\n# Second title\nUpdated at: #{Time.now}"
      puts "Trying to update the first paper... revision=#{paper['revision']}"
      api[paper_link['href']].put(
        JSON.dump(paper), 
        :content_type => "application/json", 
        :accept => "application/json"
      )
      
      # GET the updated version
      paper_response = api[paper_link['href']].get(:accept => paper_link['type'])
      pp JSON.parse paper_response
    end
  end
end